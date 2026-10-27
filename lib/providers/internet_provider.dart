import 'dart:async';

import 'package:field_service/services/network_service.dart';
import 'package:flutter/material.dart';

class InternetProvider extends ChangeNotifier {
  final NetworkService _networkService;
  InternetProvider(this._networkService) {
    _initialize();
  }

  bool _hasInternet = false;
  bool _isChecking = true;

  bool get hasInternet => _hasInternet;
  bool get isChecking => _isChecking;

  StreamSubscription<bool>? _subscription;

  Future<void> _initialize() async {
    _isChecking = true;
    notifyListeners();

    _hasInternet = await _networkService.checkInternet();
    notifyListeners();

    _subscription = _networkService.internetStream.listen((bool status) {
      if (_hasInternet != status) {
        _hasInternet = status;
        notifyListeners();
      }
    });
    _isChecking = false;
    notifyListeners();
  }

  Future<bool> checkInternet() async {
    bool connected = await _networkService.checkInternetConnection();
    return connected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
