import 'package:flutter/foundation.dart';

import '../../../repositorys/job_monitoring_repository.dart';

class JobMonitoringViewModel extends ChangeNotifier {
  final JobMonitoringRepository _repository;

  JobMonitoringViewModel(this._repository);

  List<Map<String, dynamic>> _allJobs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  List<Map<String, dynamic>> get allJobs => _allJobs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  List<Map<String, dynamic>> get filteredJobs {
    return _allJobs.where((job) {
      final status = (job['status'] ?? '').toString().toLowerCase();

      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;

      final query = _searchQuery.toLowerCase().trim();

      final searchableText = [
        job['id'],
        job['service_request_id'],
        job['technician_id'],
        job['technician_name'],
        job['category'],
        job['address'],
      ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

      return matchesStatus && searchableText.contains(query);
    }).toList();
  }

  int get totalJobs => _allJobs.length;

  int get activeJobs => _allJobs.where((job) {
    final status = _status(job);
    return status == 'assigned' ||
        status == 'accepted' ||
        status == 'in_progress';
  }).length;

  int get completedJobs =>
      _allJobs.where((job) => _status(job) == 'completed').length;

  int get cancelledJobs =>
      _allJobs.where((job) => _status(job) == 'cancelled').length;

  String _status(Map<String, dynamic> job) =>
      (job['status'] ?? '').toString().toLowerCase();

  Future<void> loadJobs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allJobs = await _repository.getJobs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchJobs(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void filterByStatus(String value) {
    _selectedStatus = value;
    notifyListeners();
  }

  Future<void> refresh() => loadJobs();
}
