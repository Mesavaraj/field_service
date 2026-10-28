import 'package:flutter/foundation.dart';

import '../../../core/di/service_locator.dart';
import '../../../repositorys/auth_repository.dart';
import '../../../repositorys/service_request_repository.dart';

class CustomerHomeViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _recentRequests = [];

  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get recentRequests =>
      List.unmodifiable(_recentRequests);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecentRequests() async {
    print('loadRecentRequests ca;lee');
    if (_disposed || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final user = getIt<AuthRepository>().currentUser;

      if (user == null) {
        throw Exception('Please sign in to view your requests.');
      }
      _recentRequests = [];
      final requests = await getIt<ServiceRequestRepository>()
          .getRecentRequests(user.id);

      if (_disposed) return;

      _recentRequests = requests;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Unable to load customer requests: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_disposed) {
        _errorMessage = 'Unable to load service requests. Please try again.';
      }
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;

    // Do not start another request while one is running.
    if (_isLoading) return;

    await loadRecentRequests();
  }

  bool isSynced(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
