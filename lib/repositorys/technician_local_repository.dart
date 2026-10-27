import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/technician_task_model.dart';

class TechnicianLocalRepository {
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;

    final path = p.join(await getDatabasesPath(), 'technician_dashboard.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE technician_task_cache (
            technician_id TEXT NOT NULL,
            task_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            PRIMARY KEY (technician_id, task_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE technician_status_queue (
            technician_id TEXT NOT NULL,
            task_id TEXT NOT NULL,
            status TEXT NOT NULL,
            queued_at TEXT NOT NULL,
            PRIMARY KEY (technician_id, task_id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE technician_status_queue (
              technician_id TEXT NOT NULL,
              task_id TEXT NOT NULL,
              status TEXT NOT NULL,
              queued_at TEXT NOT NULL,
              PRIMARY KEY (technician_id, task_id)
            )
          ''');
        }
      },
    );

    return _database!;
  }

  Future<List<TechnicianTaskModel>> getTasks(String technicianId) async {
    final db = await _db;

    final rows = await db.query(
      'technician_task_cache',
      where: 'technician_id = ?',
      whereArgs: [technicianId],
      orderBy: 'cached_at DESC',
    );

    return rows.map((row) {
      return TechnicianTaskModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
      );
    }).toList();
  }

  Future<TechnicianTaskModel?> getCachedTask(
    String technicianId,
    String taskId,
  ) async {
    final db = await _db;

    final rows = await db.query(
      'technician_task_cache',
      where: 'technician_id = ? AND task_id = ?',
      whereArgs: [technicianId, taskId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return TechnicianTaskModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(rows.first['payload'] as String) as Map,
      ),
    );
  }

  Future<void> saveTasks(
    String technicianId,
    List<TechnicianTaskModel> tasks,
  ) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.delete(
        'technician_task_cache',
        where: 'technician_id = ?',
        whereArgs: [technicianId],
      );

      final batch = txn.batch();

      for (final task in tasks) {
        batch.insert('technician_task_cache', {
          'technician_id': technicianId,
          'task_id': task.id,
          'payload': jsonEncode(task.toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> saveTask(String technicianId, TechnicianTaskModel task) async {
    final db = await _db;

    await db.insert('technician_task_cache', {
      'technician_id': technicianId,
      'task_id': task.id,
      'payload': jsonEncode(task.toJson()),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> queueStatusUpdate({
    required String technicianId,
    required String taskId,
    required String status,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      // Keep the cached detail consistent with the pending status.
      final rows = await txn.query(
        'technician_task_cache',
        where: 'technician_id = ? AND task_id = ?',
        whereArgs: [technicianId, taskId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final payload = Map<String, dynamic>.from(
          jsonDecode(rows.first['payload'] as String) as Map,
        );

        payload['status'] = status;

        await txn.update(
          'technician_task_cache',
          {
            'payload': jsonEncode(payload),
            'cached_at': DateTime.now().toIso8601String(),
          },
          where: 'technician_id = ? AND task_id = ?',
          whereArgs: [technicianId, taskId],
        );
      }

      await txn.insert('technician_status_queue', {
        'technician_id': technicianId,
        'task_id': taskId,
        'status': status,
        'queued_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Map<String, dynamic>>> getPendingStatusUpdates(
    String technicianId,
  ) async {
    final db = await _db;

    return db.query(
      'technician_status_queue',
      where: 'technician_id = ?',
      whereArgs: [technicianId],
      orderBy: 'queued_at ASC',
    );
  }

  Future<void> removePendingStatusUpdate({
    required String technicianId,
    required String taskId,
  }) async {
    final db = await _db;

    await db.delete(
      'technician_status_queue',
      where: 'technician_id = ? AND task_id = ?',
      whereArgs: [technicianId, taskId],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
// import 'dart:convert';
//
// import 'package:path/path.dart' as p;
// import 'package:sqflite/sqflite.dart';
//
// import '../models/technician_task_model.dart';
//
// class TechnicianLocalRepository {
//   Database? _database;
//
//   Future<Database> get _db async {
//     if (_database != null) return _database!;
//
//     final dbPath = p.join(await getDatabasesPath(), 'technician_dashboard.db');
//
//     _database = await openDatabase(
//       dbPath,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE technician_task_cache (
//             technician_id TEXT NOT NULL,
//             task_id TEXT NOT NULL,
//             payload TEXT NOT NULL,
//             cached_at TEXT NOT NULL,
//             PRIMARY KEY (technician_id, task_id)
//           )
//         ''');
//       },
//     );
//
//     return _database!;
//   }
//
//   Future<List<TechnicianTaskModel>> getTasks(String technicianId) async {
//     final db = await _db;
//
//     final rows = await db.query(
//       'technician_task_cache',
//       where: 'technician_id = ?',
//       whereArgs: [technicianId],
//       orderBy: 'cached_at DESC',
//     );
//
//     return rows.map((row) {
//       final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
//       return TechnicianTaskModel.fromJson(json);
//     }).toList();
//   }
//
//   Future<void> saveTasks(
//     String technicianId,
//     List<TechnicianTaskModel> tasks,
//   ) async {
//     final db = await _db;
//
//     await db.transaction((txn) async {
//       // Replace this technician's snapshot to remove stale assignments.
//       await txn.delete(
//         'technician_task_cache',
//         where: 'technician_id = ?',
//         whereArgs: [technicianId],
//       );
//
//       final batch = txn.batch();
//
//       for (final task in tasks) {
//         batch.insert('technician_task_cache', {
//           'technician_id': technicianId,
//           'task_id': task.id,
//           'payload': jsonEncode(task.toJson()),
//           'cached_at': DateTime.now().toIso8601String(),
//         });
//       }
//
//       await batch.commit(noResult: true);
//     });
//   }
//
//   Future<void> close() async {
//     await _database?.close();
//     _database = null;
//   }
// }
