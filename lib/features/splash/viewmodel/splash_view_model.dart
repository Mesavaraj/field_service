import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../database/local_database.dart';
import '../../../repositorys/auth_repository.dart';
import '../../../services/api_service.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;
  String? _destination;
  String? _errorMessage;

  bool _disposed = false;
  bool _hasStarted = false;

  bool get isLoading => _isLoading;
  String? get destination => _destination;
  String? get errorMessage => _errorMessage;

  Future<void> start() async {
    if (_hasStarted || _disposed) return;

    _hasStarted = true;
    await _initialize();
  }

  Future<void> retry() async {
    if (_disposed || _isLoading) return;

    _destination = null;
    _errorMessage = null;
    _isLoading = true;
    _notifySafely();

    await _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _notifySafely();

      // Preserve the splash screen display duration.
      await Future<void>.delayed(const Duration(seconds: 2));

      if (_disposed) return;

      final client = Supabase.instance.client;
      final session = client.auth.currentSession;

      // No active session: onboarding or login.
      if (session == null) {
        await _openOnboardingOrLogin();
        return;
      }

      final userId = session.user.id;

      // 1. Try the locally cached user first.
      final authRepository = getIt<AuthRepository>();

      final cachedUser = await authRepository.getCachedUser(userId);

      if (_disposed) return;

      if (cachedUser != null) {
        _setDestinationForRole(cachedUser.role);
        return;
      }

      // 2. Fetch the profile from Supabase REST API.
      final apiService = getIt<ApiService>();

      final response = await apiService.get(
        ApiConfig.profiles,
        query: {
          'select': 'id,full_name,role,created_at,updated_at',
          'id': 'eq.$userId',
        },
      );

      if (_disposed) return;

      if (response is! List || response.isEmpty) {
        throw Exception('Profile not found. Please sign in again.');
      }

      final profile = Map<String, dynamic>.from(response.first as Map);

      final role = profile['role']?.toString().toLowerCase();

      if (role == null || role.isEmpty) {
        throw Exception('Your profile has no assigned role.');
      }

      // Validate the role before caching.
      _setDestinationForRole(role);

      // 3. Cache the profile for future offline startup.
      await getIt<LocalDatabase>().saveUser({
        'id': userId,
        'full_name': profile['full_name'] ?? '',
        'role': role,
        'email': session.user.email ?? '',
      });
    } catch (error, stackTrace) {
      debugPrint('Splash initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!_disposed) {
        _destination = null;
        _errorMessage = 'Unable to load your profile. Please try again.';
      }
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> _openOnboardingOrLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (_disposed) return;

    _destination = (prefs.getBool('hasSeenOnboarding') ?? false)
        ? '/login'
        : '/onboarding';
  }

  void _setDestinationForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        _destination = '/admin';
        break;

      case 'technician':
        _destination = '/technician';
        break;

      case 'customer':
        _destination = '/customer';
        break;

      default:
        throw Exception('Unknown user role: $role');
    }
  }

  void clearDestination() {
    _destination = null;
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
