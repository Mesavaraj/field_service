import 'package:flutter/foundation.dart';

import '../../../models/technician_task_model.dart';
import '../../../repositorys/technician_task_details_repository.dart';

class TechnicianTaskDetailsViewModel extends ChangeNotifier {
  final TechnicianTaskDetailsRepository repository;
  final String taskId;

  TechnicianTaskDetailsViewModel({
    required this.repository,
    required this.taskId,
  });

  TechnicianTaskModel? _task;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isOffline = false;
  String? _error;

  TechnicianTaskModel? get task => _task;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Future<void> loadTask() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.getTask(taskId);

      _task = result.task;
      _isOffline = result.fromCache;

      print('result.task ${result.task.scheduledAt}');
    } catch (e) {
      _error = e.toString();
      print('_error3 $_error');
      debugPrint('Load task error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String newStatus) async {
    final current = _task;

    if (current == null || _isUpdating) return false;

    final allowed = switch (current.normalizedStatus) {
      'assigned' => newStatus == 'in_progress',
      'in_progress' => newStatus == 'completed',
      _ => false,
    };

    if (!allowed) {
      throw StateError('This status transition is not allowed.');
    }

    _isUpdating = true;
    _error = null;
    print('_error2 $_error');
    notifyListeners();

    try {
      final queuedOffline = await repository.updateStatus(
        taskId: current.id,
        status: newStatus,
      );

      _task = TechnicianTaskModel(
        id: current.id,
        title: current.title,
        description: current.description,
        status: newStatus,
        address: current.address,
        customerId: current.customerId,
        preferredDate: current.preferredDate,
        latitude: current.latitude,
        longitude: current.longitude,
      );

      _isOffline = queuedOffline;
      return queuedOffline;
    } catch (e) {
      print('_error1 $_error');
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
