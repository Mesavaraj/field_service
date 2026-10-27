import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'fixmate.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE local_users (
            id TEXT PRIMARY KEY,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL,
            email TEXT,
            created_at TEXT,
            updated_at TEXT,
            address TEXT NOT NULL DEFAULT '',
            latitude REAL,
            longitude REAL,
            is_synced INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE technician_jobs (
            id TEXT PRIMARY KEY,
            technician_id TEXT NOT NULL,
            service_title TEXT NOT NULL,
            customer_name TEXT NOT NULL,
            address TEXT NOT NULL,
            status TEXT NOT NULL,
            scheduled_time TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS service_requests (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            address TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            preferred_date TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            server_id TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> saveUser(Map<String, Object?> user) async {
    final db = await database;

    await db.insert(
      'local_users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> getUser(String id) async {
    final db = await database;

    final results = await db.query(
      'local_users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isEmpty ? null : results.first;
  }

  Future<void> deleteUser(String id) async {
    final db = await database;

    await db.delete('local_users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveTechnicianJobs(List<Map<String, Object?>> jobs) async {
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final job in jobs) {
        batch.insert(
          'technician_jobs',
          job,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> getTechnicianJobs(
    String technicianId,
  ) async {
    final db = await database;

    return db.query(
      'technician_jobs',
      where: 'technician_id = ?',
      whereArgs: [technicianId],
      orderBy: 'scheduled_time ASC',
    );
  }

  Future<void> updateLocalAddress({
    required String userId,
    required String address,
    required double? latitude,
    required double? longitude,
  }) async {
    final db = await database;

    await db.update(
      'local_users',
      {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> markUserSynced(String userId) async {
    final db = await database;

    await db.update(
      'local_users',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> insertServiceRequest(Map<String, dynamic> request) async {
    final db = await database;

    await db.insert('service_requests', {
      ...request,
      'server_id': request['server_id'],
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> markServiceRequestSynced(String localId, String serverId) async {
    final db = await database;

    await db.update(
      'service_requests',
      {'is_synced': 1, 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<Map<String, Object?>>> getPendingServiceRequests(
    String customerId,
  ) async {
    final db = await database;

    return db.query(
      'service_requests',
      where: 'customer_id = ? AND is_synced = 0',
      whereArgs: [customerId],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getServiceRequestsByCustomer(
    String customerId,
  ) async {
    final db = await database;

    final result = await db.query(
      'service_requests',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
      limit: 5,
    );

    return result;
  }
}
