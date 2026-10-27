import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get internetStream {
    return _connectivity.onConnectivityChanged.asyncMap((
      List<ConnectivityResult> results,
    ) async {
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      return await InternetConnection().hasInternetAccess;
    });
  }

  Future<bool> checkInternet() async {
    debugPrint(
      'check Internet: ${await InternetConnection().hasInternetAccess}',
    );
    return await InternetConnection().hasInternetAccess;
  }

  Future<bool> checkInternetConnection() async {
    List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }
    return await InternetConnection().hasInternetAccess;
  }
}
