import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/technician_task_model.dart';
import 'technician_local_repository.dart';

class TaskDetailsResult {
  final TechnicianTaskModel task;
  final bool fromCache;

  const TaskDetailsResult({required this.task, required this.fromCache});
}

class TechnicianTaskDetailsRepository {
  final SupabaseClient client;
  final TechnicianLocalRepository local;

  TechnicianTaskDetailsRepository({required this.client, required this.local});

  String get _technicianId {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    return user.id;
  }

  bool _isNetworkError(Object error) {
    return error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException;
  }

  Future<void> syncPendingUpdates() async {
    final technicianId = _technicianId;
    final pending = await local.getPendingStatusUpdates(technicianId);

    for (final item in pending) {
      final taskId = item['task_id'] as String;
      final status = item['status'] as String;

      try {
        final response = await client
            .from('tasks')
            .update({'status': status})
            .eq('id', taskId)
            .eq('technician_id', technicianId)
            .select('id')
            .maybeSingle();

        if (response == null) {
          // Task no longer assigned, deleted, or blocked by RLS.
          // Keep the pending item for inspection/retry.
          continue;
        }

        await local.removePendingStatusUpdate(
          technicianId: technicianId,
          taskId: taskId,
        );
      } catch (error) {
        if (_isNetworkError(error)) return;
        rethrow;
      }
    }
  }

  Future<TaskDetailsResult> getTask(String requestId) async {
    final technicianId = _technicianId;
    print('Request ID: $requestId');

    try {
      await syncPendingUpdates();
      final response1 = await client
          .from('tasks')
          .select()
          .eq('id', requestId)
          .eq('technician_id', technicianId)
          .maybeSingle();

      print('Task ID: $requestId');
      print('Task response: $response1');

      if (response1 == null) {
        throw Exception('Task not found or not assigned to you.');
      }

      final serviceRequestId = response1['service_request_id'];
      final scheduledAt = response1['scheduled_at'];
      final taskId = response1['id'];
      print('serviceRequestId4656: $serviceRequestId');

      if (serviceRequestId == null) {
        throw Exception('No service request is linked to this task.');
      }

      final response = await client
          .from('service_requests')
          .select()
          .eq('id', serviceRequestId)
          .maybeSingle();

      print('Service Request ID: $serviceRequestId');
      print('Service Request Response: $response');

      if (response == null) {
        throw Exception('Service request details not found.');
      }

      final task = TechnicianTaskModel.fromJson({
        ...Map<String, dynamic>.from(response),
        'scheduled_at': scheduledAt,
        'id': taskId,
      });

      await local.saveTask(technicianId, task);

      return TaskDetailsResult(task: task, fromCache: false);
    } catch (error) {
      final cached = await local.getCachedTask(technicianId, requestId);

      if (cached != null &&
          (error is SocketException ||
              error is http.ClientException ||
              error is TimeoutException)) {
        return TaskDetailsResult(task: cached, fromCache: true);
      }

      if (cached != null && error is! PostgrestException) {
        return TaskDetailsResult(task: cached, fromCache: true);
      }

      rethrow;
    }
  }

  Future<bool> updateStatus({
    required String taskId,
    required String status,
  }) async {
    final technicianId = _technicianId;

    if (!['assigned', 'in_progress', 'completed'].contains(status)) {
      throw ArgumentError('Unsupported task status: $status');
    }

    try {
      // 1. Update the task and retrieve its service_request_id.
      final taskResponse = await client
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId)
          .eq('technician_id', technicianId)
          .select()
          .maybeSingle();

      if (taskResponse == null) {
        throw Exception(
          'Task not updated. Check task ID, technician ID, and RLS policies.',
        );
      }

      final serviceRequestId = taskResponse['service_request_id']?.toString();

      if (serviceRequestId == null || serviceRequestId.isEmpty) {
        throw Exception('Task has no associated service request.');
      }

      // 2. Update the related service request status.
      final requestResponse = await client
          .from('service_requests')
          .update({'status': status})
          .eq('id', serviceRequestId)
          .select()
          .maybeSingle();

      if (requestResponse == null) {
        throw Exception(
          'Task updated, but service request was not updated. '
          'Check the service request ID and RLS policies.',
        );
      }

      // 3. Save the updated task locally.
      final task = TechnicianTaskModel.fromJson(
        Map<String, dynamic>.from(taskResponse),
      );

      await local.saveTask(technicianId, task);

      await local.removePendingStatusUpdate(
        technicianId: technicianId,
        taskId: taskId,
      );

      return false; // Both updates completed online.
    } catch (error, stackTrace) {
      debugPrint('updateStatus error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_isNetworkError(error)) rethrow;

      await local.queueStatusUpdate(
        technicianId: technicianId,
        taskId: taskId,
        status: status,
      );

      return true; // Queued for offline synchronization.
    }
  }
  // Future<bool> updateStatus({
  //   required String taskId,
  //   required String status,
  // }) async
  // {
  //   print('taskId1234: $taskId');
  //   final technicianId = _technicianId;
  //
  //   if (!['assigned', 'in_progress', 'completed'].contains(status)) {
  //     throw ArgumentError('Unsupported task status: $status');
  //   }
  //
  //   try {
  //     final response = await client
  //         .from('tasks')
  //         .update({'status': status})
  //         .eq('id', taskId)
  //         .eq('technician_id', technicianId)
  //         .select();
  //
  //     if (response.isEmpty) {
  //       throw Exception(
  //         'No task was updated. Verify taskId, technicianId, and RLS policies.',
  //       );
  //     }
  //
  //     final task = TechnicianTaskModel.fromJson(
  //       Map<String, dynamic>.from(response.first),
  //     );
  //
  //     await local.saveTask(technicianId, task);
  //
  //     await local.removePendingStatusUpdate(
  //       technicianId: technicianId,
  //       taskId: taskId,
  //     );
  //
  //     return false; // Saved online.
  //   } catch (error, stackTrace) {
  //     debugPrint('updateStatus error: $error');
  //     debugPrintStack(stackTrace: stackTrace);
  //
  //     if (!_isNetworkError(error)) rethrow;
  //
  //     await local.queueStatusUpdate(
  //       technicianId: technicianId,
  //       taskId: taskId,
  //       status: status,
  //     );
  //
  //     return true; // Queued offline.
  //   }
  // }
}
