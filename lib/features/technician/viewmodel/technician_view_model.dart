import 'package:flutter/foundation.dart';

import '../../../repositorys/technician_repository.dart';

class TechnicianViewModel extends ChangeNotifier {
  final TechnicianRepository _repository;

  TechnicianViewModel(this._repository);

  List<Map<String, dynamic>> _technicians = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Map<String, dynamic>> get technicians => _technicians;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  Future<void> loadTechnicians() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _technicians = await _repository.getTechnicians(search: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchTechnicians(String value) async {
    _searchQuery = value;
    await loadTechnicians();
  }

  Future<void> refresh() async {
    await loadTechnicians();
  }
}
