import 'package:field_service/models/profile_model.dart';
import 'package:field_service/repositorys/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<ProfileModel?> login({
    required String email,
    required String password,
  }) async {
    _startLoading();

    try {
      final profile = await _repository.signIn(
        email: email,
        password: password,
      );

      if (![
        'admin',
        'technician',
        'customer',
      ].contains(profile.role.toLowerCase())) {
        throw Exception('Your account has an invalid role.');
      }

      return profile;
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _startLoading();

    try {
      await _repository.signUp(name: name, email: email, password: password);

      _successMessage =
          'Account created. Check your email if verification is required.';

      return true;
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    _startLoading();

    try {
      await _repository.signOut();
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
    } finally {
      _stopLoading();
    }
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  String _friendlyMessage(Object error) {
    final message = error.toString();

    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('User already registered')) {
      return 'This email is already registered.';
    }

    if (message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'No internet connection. Please try again.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}
