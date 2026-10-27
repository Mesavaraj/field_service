import 'package:flutter/foundation.dart';

import '../../../repositorys/admin_profile_repository.dart';

class AdminProfileViewModel extends ChangeNotifier {
  final AdminProfileRepository _repository;

  AdminProfileViewModel(this._repository);

  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSigningOut = false;
  String? _errorMessage;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSigningOut => _isSigningOut;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.getAdminProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateName(String fullName) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateAdminName(fullName);

      _profile = {...?_profile, 'full_name': fullName.trim()};

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    _isSigningOut = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSigningOut = false;
      notifyListeners();
    }
  }
}
