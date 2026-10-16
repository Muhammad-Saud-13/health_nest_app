import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_packet.dart';
import '../repositories/local_store.dart';
import '../repositories/packet_parser.dart';
import '../services/connectivity_service.dart';

/// Queue name constant for sensor data batches.
const String kSensorBatchQueue = 'sensor_batches';

/// Queue name constant for check-in submissions.
const String kCheckInQueue = 'checkins';

/// Offline Queue and Sync Service (FR-4.4, FR-4.5, NFR-2.2, NFR-2.4).
///
/// Responsibilities:
/// - Queue sensor data in [LocalStore] (sqflite) when network is unavailable.
/// - Retain queued data for at least 8 hours (one shift, ~17 MB).
/// - Trigger sync to backend when connectivity is restored (mock: simulated).
/// - Discard malformed packets without crashing (NFR-2.4).
class OfflineSyncService extends ChangeNotifier {
  OfflineSyncService({
    required LocalStore localStore,
    required ConnectivityService connectivityService,
    this.batchSize = 50,
    this.syncIntervalMs = 5000,
  })  : _localStore = localStore,
        _connectivityService = connectivityService;

  final LocalStore _localStore;
  final ConnectivityService _connectivityService;

  /// Maximum items to upload per sync batch.
  final int batchSize;

  /// Delay (milliseconds) between sync attempts when online.
  final int syncIntervalMs;

  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  ConnectivityStatus _networkStatus = ConnectivityStatus.online;
  ConnectivityStatus get networkStatus => _networkStatus;
  bool get isOnline => _networkStatus == ConnectivityStatus.online;
  bool get isOffline => _networkStatus == ConnectivityStatus.offline;

  /// Total items synced since the service started.
  int _totalSynced = 0;
  int get totalSynced => _totalSynced;

  /// Last sync time.
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Last error message.
  String? _lastError;
  String? get lastError => _lastError;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialize the service: set up the local store and connectivity listener.
  Future<void> init() async {
    await _localStore.init();
    await _refreshPendingCount();

    _networkStatus = _connectivityService.currentStatus;

    _connectivitySub = _connectivityService.statusStream.listen((status) {
      _networkStatus = status;
      notifyListeners();

      if (status == ConnectivityStatus.online) {
        _startSyncLoop();
      } else {
        _stopSyncLoop();
      }
    });

    // If already online, start sync loop to drain any stale queued items.
    if (_networkStatus == ConnectivityStatus.online) {
      _startSyncLoop();
    }
  }

  /// Shut down streams and timers.
  @override
  void dispose() {
    _stopSyncLoop();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Enqueue (FR-4.4 — queue data when offline)
  // ---------------------------------------------------------------------------

  /// Enqueue a sensor packet for later upload.
  ///
  /// If the device is online, attempts an immediate mock-sync instead of
  /// persisting to the queue (optimization). If offline, the packet is
  /// serialized and stored in sqflite.
  Future<void> enqueueSensorData(SensorPacket packet) async {
    try {
      final payload = packet.toJson();
      await _localStore.enqueue(kSensorBatchQueue, payload);
      await _refreshPendingCount();
    } catch (e) {
      debugPrint('[OfflineSyncService] enqueue error: $e');
      _lastError = 'Failed to queue sensor data: $e';
      notifyListeners();
    }
  }

  /// Enqueue a batch of sensor packets at once (more efficient for high-rate data).
  Future<void> enqueueSensorBatch(List<SensorPacket> packets) async {
    for (final packet in packets) {
      try {
        await _localStore.enqueue(kSensorBatchQueue, packet.toJson());
      } catch (e) {
        debugPrint('[OfflineSyncService] batch enqueue error: $e');
      }
    }
    await _refreshPendingCount();
  }

  /// Enqueue a generic payload (e.g. check-in submission) for sync.
  Future<void> enqueuePayload(String queueName, Map<String, dynamic> payload) async {
    try {
      await _localStore.enqueue(queueName, payload);
      await _refreshPendingCount();
    } catch (e) {
      debugPrint('[OfflineSyncService] enqueuePayload error: $e');
      _lastError = 'Failed to queue payload: $e';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Parse with malformed-packet safety (NFR-2.4)
  // ---------------------------------------------------------------------------

  /// Safely parse raw BLE bytes into a [SensorPacket], discarding malformed
  /// data without crashing. Returns `null` if the packet is invalid.
  static SensorPacket? safeParse(PacketParser parser, List<int> rawBytes) {
    try {
      // Guard: null or empty input
      if (rawBytes.isEmpty) {
        debugPrint('[OfflineSyncService] Discarded empty packet');
        return null;
      }

      return parser.parse(rawBytes);
    } on FormatException catch (e) {
      debugPrint('[OfflineSyncService] Discarded malformed packet: $e');
      return null;
    } catch (e) {
      // Catch-all: discard and log, never crash (NFR-2.4)
      debugPrint('[OfflineSyncService] Unexpected parse error, discarding: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Sync (FR-4.5 — upload when connectivity restored)
  // ---------------------------------------------------------------------------

  /// Attempt a single sync cycle: peek items from the queue, "upload" them
  /// (mock: simulate network call), then dequeue on success.
  Future<int> syncOnce() async {
    if (_isSyncing) return 0;

    _isSyncing = true;
    notifyListeners();

    int syncedThisCycle = 0;

    try {
      // Process sensor batches
      syncedThisCycle += await _syncQueue(kSensorBatchQueue);

      // Process check-in submissions
      syncedThisCycle += await _syncQueue(kCheckInQueue);

      if (syncedThisCycle > 0) {
        _totalSynced += syncedThisCycle;
        _lastSyncTime = DateTime.now();
        _lastError = null;
      }
    } catch (e) {
      _lastError = 'Sync failed: $e';
      debugPrint('[OfflineSyncService] sync error: $e');
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
      notifyListeners();
    }

    return syncedThisCycle;
  }

  /// Drain the entire queue by calling [syncOnce] repeatedly until empty.
  Future<int> syncAll() async {
    int total = 0;
    int synced;
    do {
      synced = await syncOnce();
      total += synced;
    } while (synced > 0);
    return total;
  }

  /// Clear all pending items (useful for debugging or shift reset).
  Future<void> clearQueue() async {
    await _localStore.clear(kSensorBatchQueue);
    await _localStore.clear(kCheckInQueue);
    await _refreshPendingCount();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<int> _syncQueue(String queueName) async {
    final items = await _localStore.peek(queueName, limit: batchSize);
    if (items.isEmpty) return 0;

    // Mock upload: simulate a network call with a short delay
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // In a real implementation, this would be:
    // final response = await http.post(uploadUrl, body: jsonEncode(items));
    // if (response.statusCode == 200) { ... }

    // Remove successfully "uploaded" items
    final ids = items.map((item) => item.id).toList();
    await _localStore.dequeue(queueName, ids);

    debugPrint(
      '[OfflineSyncService] Synced ${items.length} items from $queueName',
    );

    return items.length;
  }

  Future<void> _refreshPendingCount() async {
    final sensorCount = await _localStore.getQueueCount(kSensorBatchQueue);
    final checkinCount = await _localStore.getQueueCount(kCheckInQueue);
    _pendingCount = sensorCount + checkinCount;
  }

  void _startSyncLoop() {
    _stopSyncLoop();
    // Immediate first sync, then periodic
    syncOnce();
    _syncTimer = Timer.periodic(
      Duration(milliseconds: syncIntervalMs),
      (_) => syncOnce(),
    );
  }

  void _stopSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
