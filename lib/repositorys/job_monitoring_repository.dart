import 'package:supabase_flutter/supabase_flutter.dart';

class JobMonitoringRepository {
  final SupabaseClient _supabase;

  JobMonitoringRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getJobs() async {
    final taskResponse = await _supabase
        .from('tasks')
        .select(
          'id, service_request_id, technician_id, '
          'scheduled_at, status, notes, created_at',
        )
        .order('scheduled_at', ascending: true);

    final tasks = List<Map<String, dynamic>>.from(taskResponse);

    if (tasks.isEmpty) return [];

    final requestIds = tasks
        .map((task) => task['service_request_id'])
        .whereType<String>()
        .toSet()
        .toList();

    final technicianIds = tasks
        .map((task) => task['technician_id'])
        .whereType<String>()
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> requestMap = {};
    final Map<String, Map<String, dynamic>> technicianMap = {};

    if (requestIds.isNotEmpty) {
      final response = await _supabase
          .from('service_requests')
          .select('id, category, address, customer_id, status')
          .inFilter('id', requestIds);

      for (final row in response) {
        final request = Map<String, dynamic>.from(row);
        requestMap[request['id'].toString()] = request;
      }
    }

    if (technicianIds.isNotEmpty) {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', technicianIds);

      for (final row in response) {
        final technician = Map<String, dynamic>.from(row);
        technicianMap[technician['id'].toString()] = technician;
      }
    }

    return tasks.map((task) {
      final request = requestMap[task['service_request_id']?.toString()];
      final technician = technicianMap[task['technician_id']?.toString()];

      return {
        ...task,
        'category': request?['category'] ?? 'Service request',
        'address': request?['address'] ?? 'Address unavailable',
        'customer_id': request?['customer_id'],
        'request_status': request?['status'],
        'technician_name': technician?['full_name'] ?? 'Unknown technician',
      };
    }).toList();
  }
}
