import 'package:flutter_test/flutter_test.dart';
import 'package:healtnest_app/data/models/sensor_packet.dart';
import 'package:healtnest_app/data/repositories/local_store.dart';
import 'package:healtnest_app/data/repositories/packet_parser.dart';
import 'package:healtnest_app/data/services/connectivity_service.dart';
import 'package:healtnest_app/data/services/offline_sync_service.dart';

// =============================================================================
// In-Memory LocalStore for unit testing (avoids sqflite native dependency)
// =============================================================================

class InMemoryLocalStore implements LocalStore {
  final Map<String, List<_InMemoryQueueItem>> _queues = {};
  int _autoId = 0;
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  Future<int> enqueue(String queueName, Map<String, dynamic> payload) async {
    _checkInit();
    _autoId++;
    _queues.putIfAbsent(queueName, () => []);
    _queues[queueName]!.add(_InMemoryQueueItem(
      id: _autoId,
      payload: Map<String, dynamic>.from(payload),
      createdAt: DateTime.now(),
    ));
    return _autoId;
  }

  @override
  Future<List<QueuedItem>> peek(String queueName, {int limit = 50}) async {
    _checkInit();
    final items = _queues[queueName] ?? [];
    final limited = items.take(limit).toList();
    return limited
        .map((item) => QueuedItem(
              id: item.id,
              queueName: queueName,
              payload: item.payload,
              createdAt: item.createdAt,
            ))
        .toList();
  }

  @override
  Future<void> dequeue(String queueName, List<int> ids) async {
    _checkInit();
    final items = _queues[queueName];
    if (items != null) {
      items.removeWhere((item) => ids.contains(item.id));
    }
  }

  @override
  Future<int> getQueueCount(String queueName) async {
    _checkInit();
    return _queues[queueName]?.length ?? 0;
  }

  @override
  Future<void> clear(String queueName) async {
    _checkInit();
    _queues.remove(queueName);
  }

  @override
  Future<void> close() async {
    _queues.clear();
    _initialized = false;
  }

  void _checkInit() {
    if (!_initialized) {
      throw StateError('InMemoryLocalStore must be initialized before use.');
    }
  }
}

class _InMemoryQueueItem {
  final int id;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  _InMemoryQueueItem({
    required this.id,
    required this.payload,
    required this.createdAt,
  });
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('NFR-2.4 — Malformed Packet Handling', () {
    late DefaultPacketParser parser;

    setUp(() {
      parser = DefaultPacketParser();
    });

    test('Empty byte list returns null (no crash)', () {
      final result = OfflineSyncService.safeParse(parser, []);
      expect(result, isNull);
    });

    test('Packet with < 8 bytes returns null (no crash)', () {
      final result = OfflineSyncService.safeParse(parser, [0, 1, 2]);
      expect(result, isNull);
    });

    test('All-zero garbage input returns null or valid packet (no crash)', () {
      final result = OfflineSyncService.safeParse(parser, [0, 0, 0, 0, 0, 0, 0, 0]);
      // This should not crash; it may return a valid (zeroed) packet
      expect(result, isNotNull);
      expect(result!.accelX, 0.0);
      expect(result.accelY, 0.0);
      expect(result.accelZ, 0.0);
    });

    test('Random garbage bytes do not crash', () {
      final garbage = List<int>.generate(256, (i) => (i * 7 + 13) % 256);
      final result = OfflineSyncService.safeParse(parser, garbage);
      // Should not throw; result may or may not be null
      expect(() => result, returnsNormally);
    });

    test('Very large packet does not crash', () {
      final large = List<int>.generate(10000, (i) => i % 256);
      final result = OfflineSyncService.safeParse(parser, large);
      expect(result, isNotNull);
      expect(result!.ppgRaw.length, 10000 - 8);
    });

    test('Negative byte values (edge case) do not crash', () {
      // Dart allows negative values in List<int>, parser should handle gracefully
      final data = [-1, -128, 255, 0, 127, -1, 50, 60];
      final result = OfflineSyncService.safeParse(parser, data);
      // Should not crash — result may be non-null
      expect(() => result, returnsNormally);
    });

    test('Valid 8-byte packet parses correctly', () {
      // accelX: bytes[0,1] = (100, 0) => 100/1000 = 0.1
      // accelY: bytes[2,3] = (200, 0) => 200/1000 = 0.2
      // accelZ: bytes[4,5] = (44, 1) => 300/1000 = 0.3
      // spo2: bytes[6] = 97
      // temp: bytes[7] = 65 => 30.0 + 65/10 = 36.5
      final validPacket = [100, 0, 200, 0, 44, 1, 97, 65];
      final result = OfflineSyncService.safeParse(parser, validPacket);
      expect(result, isNotNull);
      expect(result!.accelX, closeTo(0.1, 0.001));
      expect(result.accelY, closeTo(0.2, 0.001));
      expect(result.accelZ, closeTo(0.3, 0.001));
      expect(result.spo2, 97.0);
      expect(result.temperature, closeTo(36.5, 0.01));
    });
  });

  group('OfflineSyncService — Queue and Sync', () {
    late InMemoryLocalStore localStore;
    late MockConnectivityService connectivity;
    late OfflineSyncService syncService;

    setUp(() async {
      localStore = InMemoryLocalStore();
      connectivity = MockConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
      syncService = OfflineSyncService(
        localStore: localStore,
        connectivityService: connectivity,
        batchSize: 10,
        syncIntervalMs: 60000, // Long interval; we'll manually trigger syncs
      );
      await syncService.init();
    });

    tearDown(() {
      syncService.dispose();
      connectivity.dispose();
    });

    test('Enqueue sensor data increments pending count', () async {
      final packet = SensorPacket(
        timestamp: DateTime.now(),
        ppgRaw: [1, 2, 3],
        accelX: 0.1,
        accelY: 0.2,
        accelZ: 0.3,
        temperature: 36.5,
        spo2: 98.0,
      );

      await syncService.enqueueSensorData(packet);
      expect(syncService.pendingCount, 1);

      await syncService.enqueueSensorData(packet);
      expect(syncService.pendingCount, 2);
    });

    test('Enqueue batch queues multiple items', () async {
      final packets = List.generate(
        5,
        (i) => SensorPacket(
          timestamp: DateTime.now().add(Duration(seconds: i)),
          ppgRaw: [i],
          accelX: 0.1 * i,
          accelY: 0.2 * i,
          accelZ: 0.3 * i,
          temperature: 36.0 + i * 0.1,
          spo2: 97.0 + i * 0.5,
        ),
      );

      await syncService.enqueueSensorBatch(packets);
      expect(syncService.pendingCount, 5);
    });

    test('SyncOnce drains items from queue', () async {
      final packet = SensorPacket(
        timestamp: DateTime.now(),
        ppgRaw: [1, 2, 3],
        accelX: 0.1,
        accelY: 0.2,
        accelZ: 0.3,
        temperature: 36.5,
        spo2: 98.0,
      );

      // Enqueue 3 items
      for (int i = 0; i < 3; i++) {
        await syncService.enqueueSensorData(packet);
      }
      expect(syncService.pendingCount, 3);

      // Sync once (batch size 10, so should drain all 3)
      final synced = await syncService.syncOnce();
      expect(synced, 3);
      expect(syncService.pendingCount, 0);
      expect(syncService.totalSynced, 3);
    });

    test('SyncAll drains entire queue across batches', () async {
      final packet = SensorPacket(
        timestamp: DateTime.now(),
        ppgRaw: [1, 2, 3],
        accelX: 0.1,
        accelY: 0.2,
        accelZ: 0.3,
        temperature: 36.5,
        spo2: 98.0,
      );

      // Enqueue 25 items (> batch size of 10)
      for (int i = 0; i < 25; i++) {
        await syncService.enqueueSensorData(packet);
      }
      expect(syncService.pendingCount, 25);

      // Sync all should drain everything
      final total = await syncService.syncAll();
      expect(total, 25);
      expect(syncService.pendingCount, 0);
    });

    test('Queue retains data when offline (no auto-sync)', () async {
      // connectivity starts offline
      expect(connectivity.currentStatus, ConnectivityStatus.offline);

      final packet = SensorPacket(
        timestamp: DateTime.now(),
        ppgRaw: [10, 20, 30],
        accelX: 0.5,
        accelY: 0.6,
        accelZ: 0.7,
        temperature: 36.8,
        spo2: 96.0,
      );

      await syncService.enqueueSensorData(packet);
      expect(syncService.pendingCount, 1);

      // Wait a bit — data should still be in queue since we're offline
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(syncService.pendingCount, 1);
    });

    test('ClearQueue removes all pending items', () async {
      final packet = SensorPacket(
        timestamp: DateTime.now(),
        ppgRaw: [1],
        accelX: 0.0,
        accelY: 0.0,
        accelZ: 0.0,
        temperature: 36.0,
        spo2: 98.0,
      );

      for (int i = 0; i < 10; i++) {
        await syncService.enqueueSensorData(packet);
      }
      expect(syncService.pendingCount, 10);

      await syncService.clearQueue();
      expect(syncService.pendingCount, 0);
    });

    test('Generic payload (check-in) can be queued and synced', () async {
      final payload = {
        'user_id': 1,
        'feeling': 'FINE',
        'pain': 'NONE',
        'stress': 'LOW',
      };

      await syncService.enqueuePayload(kCheckInQueue, payload);
      expect(syncService.pendingCount, 1);

      final synced = await syncService.syncOnce();
      expect(synced, 1);
      expect(syncService.pendingCount, 0);
    });
  });

  group('ConnectivityService — Mock', () {
    test('Initial status is configurable', () {
      final online = MockConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );
      expect(online.currentStatus, ConnectivityStatus.online);

      final offline = MockConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
      expect(offline.currentStatus, ConnectivityStatus.offline);

      online.dispose();
      offline.dispose();
    });

    test('goOffline/goOnline emits status changes', () async {
      final service = MockConnectivityService();
      final statuses = <ConnectivityStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      service.goOffline();
      service.goOnline();
      service.goOffline();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(statuses, [
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
      ]);

      await sub.cancel();
      service.dispose();
    });

    test('Duplicate status changes are ignored', () async {
      final service = MockConnectivityService();
      final statuses = <ConnectivityStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      service.goOnline(); // Already online, should not emit
      service.goOnline(); // Still online

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(statuses, isEmpty);

      await sub.cancel();
      service.dispose();
    });
  });

  group('SensorPacket serialization round-trip', () {
    test('toJson and fromJson preserve all fields', () {
      final original = SensorPacket(
        timestamp: DateTime(2026, 10, 16, 8, 30, 0),
        ppgRaw: [100, 200, 150],
        accelX: 0.123,
        accelY: -0.456,
        accelZ: 0.789,
        temperature: 36.7,
        spo2: 97.5,
        localHeartRate: 72.0,
      );

      final json = original.toJson();
      final restored = SensorPacket.fromJson(json);

      expect(restored.timestamp, original.timestamp);
      expect(restored.ppgRaw, original.ppgRaw);
      expect(restored.accelX, original.accelX);
      expect(restored.accelY, original.accelY);
      expect(restored.accelZ, original.accelZ);
      expect(restored.temperature, original.temperature);
      expect(restored.spo2, original.spo2);
      expect(restored.localHeartRate, original.localHeartRate);
    });
  });
}
