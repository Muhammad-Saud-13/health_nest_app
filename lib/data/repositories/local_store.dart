import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Item stored in the offline queue.
class QueuedItem {
  final int id;
  final String queueName;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const QueuedItem({
    required this.id,
    required this.queueName,
    required this.payload,
    required this.createdAt,
  });
}

/// Abstract interface for local persistence and offline queuing (D-09).
abstract class LocalStore {
  /// Factory constructor to create platform-appropriate LocalStore:
  /// Uses [SqfliteLocalStore] on mobile/native, or [InMemoryLocalStore] on web.
  factory LocalStore.create({String dbName = 'healthnest_local.db'}) {
    if (kIsWeb) {
      return InMemoryLocalStore();
    }
    return SqfliteLocalStore(dbName: dbName);
  }

  /// Initialize database schema.
  Future<void> init();

  /// Enqueue an item into a named queue (e.g., 'sensor_batches', 'checkins').
  Future<int> enqueue(String queueName, Map<String, dynamic> payload);

  /// Inspect the oldest items in the queue without removing them (FIFO).
  Future<List<QueuedItem>> peek(String queueName, {int limit = 50});

  /// Remove processed items by their IDs.
  Future<void> dequeue(String queueName, List<int> ids);

  /// Count pending items in a queue.
  Future<int> getQueueCount(String queueName);

  /// Clear all items in a queue.
  Future<void> clear(String queueName);

  /// Close database connections.
  Future<void> close();
}

/// High-performance in-memory implementation of [LocalStore].
/// Used on Web (Chrome) where native sqflite FFI is unavailable, as well as in tests.
class InMemoryLocalStore implements LocalStore {
  final Map<String, List<QueuedItem>> _queues = {};
  int _autoId = 0;
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  void _checkInit() {
    if (!_initialized) {
      throw StateError('InMemoryLocalStore must be initialized with init() before use.');
    }
  }

  @override
  Future<int> enqueue(String queueName, Map<String, dynamic> payload) async {
    _checkInit();
    _autoId++;
    final item = QueuedItem(
      id: _autoId,
      queueName: queueName,
      payload: Map<String, dynamic>.from(payload),
      createdAt: DateTime.now(),
    );
    _queues.putIfAbsent(queueName, () => []).add(item);
    return _autoId;
  }

  @override
  Future<List<QueuedItem>> peek(String queueName, {int limit = 50}) async {
    _checkInit();
    final items = _queues[queueName] ?? [];
    return items.take(limit).toList();
  }

  @override
  Future<void> dequeue(String queueName, List<int> ids) async {
    _checkInit();
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _queues[queueName]?.removeWhere((item) => idSet.contains(item.id));
  }

  @override
  Future<int> getQueueCount(String queueName) async {
    _checkInit();
    return _queues[queueName]?.length ?? 0;
  }

  @override
  Future<void> clear(String queueName) async {
    _checkInit();
    _queues[queueName]?.clear();
  }

  @override
  Future<void> close() async {
    _queues.clear();
  }
}

/// Production-ready Sqflite implementation of LocalStore for offline queuing.
/// Includes automatic graceful fallback to InMemoryLocalStore on web/test platforms.
class SqfliteLocalStore implements LocalStore {
  Database? _db;
  final String dbName;
  InMemoryLocalStore? _webFallback;

  SqfliteLocalStore({this.dbName = 'healthnest_local.db'});

  @override
  Future<void> init() async {
    if (kIsWeb) {
      _webFallback = InMemoryLocalStore();
      await _webFallback!.init();
      return;
    }

    if (_db != null || _webFallback != null) return;

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, dbName);

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE offline_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              queue_name TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_queue_name ON offline_queue (queue_name, id ASC)
          ''');
        },
      );
    } catch (e) {
      // In web or environments without native sqflite databaseFactory, fall back gracefully
      debugPrint('[SqfliteLocalStore] Native SQLite not available ($e); falling back to InMemoryLocalStore.');
      _webFallback = InMemoryLocalStore();
      await _webFallback!.init();
    }
  }

  Database get _database {
    if (_db == null) {
      throw StateError('SqfliteLocalStore must be initialized with init() before use.');
    }
    return _db!;
  }

  @override
  Future<int> enqueue(String queueName, Map<String, dynamic> payload) async {
    if (_webFallback != null) {
      return _webFallback!.enqueue(queueName, payload);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final jsonStr = jsonEncode(payload);

    return await _database.insert('offline_queue', {
      'queue_name': queueName,
      'payload': jsonStr,
      'created_at': now,
    });
  }

  @override
  Future<List<QueuedItem>> peek(String queueName, {int limit = 50}) async {
    if (_webFallback != null) {
      return _webFallback!.peek(queueName, limit: limit);
    }

    final rows = await _database.query(
      'offline_queue',
      where: 'queue_name = ?',
      whereArgs: [queueName],
      orderBy: 'id ASC',
      limit: limit,
    );

    return rows.map((row) {
      final id = row['id'] as int;
      final qName = row['queue_name'] as String;
      final payloadJson = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int);

      return QueuedItem(
        id: id,
        queueName: qName,
        payload: payloadJson,
        createdAt: createdAt,
      );
    }).toList();
  }

  @override
  Future<void> dequeue(String queueName, List<int> ids) async {
    if (_webFallback != null) {
      return _webFallback!.dequeue(queueName, ids);
    }

    if (ids.isEmpty) return;

    final placeholders = List.filled(ids.length, '?').join(',');
    await _database.delete(
      'offline_queue',
      where: 'queue_name = ? AND id IN ($placeholders)',
      whereArgs: [queueName, ...ids],
    );
  }

  @override
  Future<int> getQueueCount(String queueName) async {
    if (_webFallback != null) {
      return _webFallback!.getQueueCount(queueName);
    }

    final count = Sqflite.firstIntValue(await _database.rawQuery(
      'SELECT COUNT(*) FROM offline_queue WHERE queue_name = ?',
      [queueName],
    ));
    return count ?? 0;
  }

  @override
  Future<void> clear(String queueName) async {
    if (_webFallback != null) {
      return _webFallback!.clear(queueName);
    }

    await _database.delete(
      'offline_queue',
      where: 'queue_name = ?',
      whereArgs: [queueName],
    );
  }

  @override
  Future<void> close() async {
    if (_webFallback != null) {
      await _webFallback!.close();
      _webFallback = null;
    }
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
