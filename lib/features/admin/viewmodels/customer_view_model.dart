import 'package:flutter/foundation.dart';

import '../../../repositorys/customer_repository.dart';

class CustomerViewModel extends ChangeNotifier {
  final CustomerRepository _repository;

  CustomerViewModel(this._repository);

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Map<String, dynamic>> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers(search: _searchQuery);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchCustomers(String value) async {
    _searchQuery = value;
    await loadCustomers();
  }

  Future<List<Map<String, dynamic>>> getCustomerRequests(String customerId) {
    return _repository.getCustomerRequests(customerId);
  }

  Future<void> refresh() => loadCustomers();
}
