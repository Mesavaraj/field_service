import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/api_config.dart';
import '../services/api_service.dart';

class CustomerRequestTrackingRepository {
  CustomerRequestTrackingRepository({
    required this._apiService,
    required this._client,
  });
  final ApiService _apiService;
  final SupabaseClient _client;

  Future<void> cancelRequest(String requestId) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again to cancel this request.');
    }

    final updatedRows = await _apiService.patch(
      ApiConfig.serviceRequests,
      query: {
        'select': 'id,status',
        'id': 'eq.$requestId',
        'customer_id': 'eq.${user.id}',
        'status': 'in.(pending,assigned)',
      },
      body: {'status': 'cancelled'},
    );

    // Assumes PATCH returns decoded JSON rows when "select" is supplied.
    if (updatedRows is! List || updatedRows.isEmpty) {
      throw Exception(
        'The request could not be cancelled. It may already be updated, '
        'you may not own it, or cancellation is no longer allowed.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerTasks(String requestId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    final request = await _client
        .from('service_requests')
        .select('id')
        .eq('id', requestId)
        .eq('customer_id', user.id)
        .maybeSingle();

    if (request == null) {
      throw Exception('Service request not found.');
    }

    final result = await _client
        .from('tasks')
        .select(
          'id, service_request_id, technician_id, '
          'scheduled_at, status, notes',
        )
        .eq('service_request_id', requestId)
        .order('scheduled_at');

    final tasks = List<Map<String, dynamic>>.from(result);

    final technicianIds = tasks
        .map((task) => task['technician_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (technicianIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', technicianIds);

      final names = <String, String>{
        for (final profile in profiles)
          profile['id'].toString(): (profile['full_name'] ?? 'Technician')
              .toString(),
      };

      for (final task in tasks) {
        task['technician_name'] =
            names[task['technician_id'].toString()] ?? 'Technician';
      }
    }

    return tasks;
  }
}
