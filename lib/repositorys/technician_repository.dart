import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/technician_task_model.dart';
import 'technician_local_repository.dart';

class TechnicianTaskResult {
  final List<TechnicianTaskModel> tasks;
  final bool fromCache;

  const TechnicianTaskResult({required this.tasks, required this.fromCache});
}

class TechnicianRepository {
  final SupabaseClient client;
  final TechnicianLocalRepository localRepository;

  TechnicianRepository({required this.client, required this.localRepository});

  Future<TechnicianTaskResult> getTasks() async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    final technicianId = user.id;

    try {
      final response = await client
          .from('tasks')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);

      print('response123: $response');

      final tasks = (response as List)
          .map(
            (row) => TechnicianTaskModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      // Cache failure should not make a successful network request fail.
      try {
        await localRepository.saveTasks(technicianId, tasks);
      } catch (_) {
        // Continue using the data retrieved from Supabase.
      }

      return TechnicianTaskResult(tasks: tasks, fromCache: false);
    } catch (error) {
      try {
        final cached = await localRepository.getTasks(technicianId);

        if (cached.isNotEmpty) {
          return TechnicianTaskResult(tasks: cached, fromCache: true);
        }
      } catch (_) {
        // No usable cache.
      }

      throw Exception(
        'Unable to load tasks. Check your connection. Details: $error',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTechnicians({
    String search = '',
  }) async {
    var query = client
        .from('profiles')
        .select('id, full_name, role, created_at')
        .eq('role', 'technician');

    final response = await query.order('full_name');

    final technicians = List<Map<String, dynamic>>.from(response);

    if (search.trim().isEmpty) {
      return technicians;
    }

    final keyword = search.trim().toLowerCase();

    return technicians.where((technician) {
      final name = (technician['full_name'] ?? '').toString().toLowerCase();
      final id = (technician['id'] ?? '').toString().toLowerCase();

      return name.contains(keyword) || id.contains(keyword);
    }).toList();
  }
}
// import 'package:fsm/repository/technician_local_repository.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../models/technician_task_model.dart';
//
// class TechnicianRepository {
//   final SupabaseClient _supabase;
//   final TechnicianLocalRepository _local;
//
//   TechnicianRepository({required this._supabase, required this._local});
//
//   Future<List<Map<String, dynamic>>> getTechnicians({
//     String search = '',
//   }) async {
//     var query = _supabase
//         .from('profiles')
//         .select('id, full_name, role, created_at')
//         .eq('role', 'technician');
//
//     final response = await query.order('full_name');
//
//     final technicians = List<Map<String, dynamic>>.from(response);
//
//     if (search.trim().isEmpty) {
//       return technicians;
//     }
//
//     final keyword = search.trim().toLowerCase();
//
//     return technicians.where((technician) {
//       final name = (technician['full_name'] ?? '').toString().toLowerCase();
//       final id = (technician['id'] ?? '').toString().toLowerCase();
//
//       return name.contains(keyword) || id.contains(keyword);
//     }).toList();
//   }
//
//   Future<Map<String, dynamic>> getTechnicianById(String technicianId) async {
//     final response = await _supabase
//         .from('profiles')
//         .select('id, full_name, role, created_at')
//         .eq('id', technicianId)
//         .eq('role', 'technician')
//         .single();
//
//     return Map<String, dynamic>.from(response);
//   }
//
//   Future<List<TechnicianTaskModel>> getTasks({
//     required bool forceRefresh,
//   }) async {
//     final user = _supabase.auth.currentUser;
//
//     if (user == null) {
//       throw Exception('Please sign in to view your tasks.');
//     }
//
//     final technicianId = user.id;
//
//     if (!forceRefresh) {
//       try {
//         final cached = await _local.getCachedTasks(technicianId);
//
//         if (cached.isNotEmpty) return cached;
//       } catch (_) {
//         // Continue to Supabase if the local cache is unavailable.
//       }
//     }
//
//     try {
//       final response = await _supabase
//           .from('tasks')
//           .select()
//           .eq('technician_id', technicianId)
//           .order('created_at', ascending: false);
//
//       final tasks = (response as List)
//           .map(
//             (row) => TechnicianTaskModel.fromJson(
//               Map<String, dynamic>.from(row as Map),
//             ),
//           )
//           .toList();
//
//       await _local.saveTasks(technicianId, tasks);
//
//       return tasks;
//     } catch (error) {
//       try {
//         final cached = await _local.getCachedTasks(technicianId);
//
//         if (cached.isNotEmpty) return cached;
//       } catch (_) {
//         // No readable cache.
//       }
//
//       throw Exception(
//         'Unable to load tasks. Check your connection and try again. '
//         'Details: $error',
//       );
//     }
//   }
// }
