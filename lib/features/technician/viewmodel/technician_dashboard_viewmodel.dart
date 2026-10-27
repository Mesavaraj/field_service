import 'package:flutter/foundation.dart';

import '../../../models/technician_task_model.dart';
import '../../../repositorys/technician_repository.dart';

class TechnicianDashboardViewModel extends ChangeNotifier {
  final TechnicianRepository repository;

  TechnicianDashboardViewModel(this.repository);

  List<TechnicianTaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;
  String _filter = 'all';

  List<TechnicianTaskModel> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;
  String get filter => _filter;

  int get assignedCount => _tasks.where((task) => task.isAssigned).length;

  int get inProgressCount => _tasks.where((task) => task.isInProgress).length;

  int get completedCount => _tasks.where((task) => task.isCompleted).length;

  List<TechnicianTaskModel> get filteredTasks {
    switch (_filter) {
      case 'assigned':
        return _tasks.where((task) => task.isAssigned).toList();
      case 'in_progress':
        return _tasks.where((task) => task.isInProgress).toList();
      case 'completed':
        return _tasks.where((task) => task.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.getTasks();

      _tasks = result.tasks;
      _isOffline = result.fromCache;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
