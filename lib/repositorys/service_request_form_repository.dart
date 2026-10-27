import 'package:field_service/database/local_database.dart';
import 'package:field_service/repositorys/service_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/api_config.dart';
import '../services/api_service.dart';
import 'auth_repository.dart';

class ServiceRequestFormRepository {
  ServiceRequestFormRepository({
    required this._apiService,
    required this._database,
    required this._authRepository,
    required this._serviceRequestRepository,
  });

  final ApiService _apiService;
  final LocalDatabase _database;
  final AuthRepository _authRepository;
  final ServiceRequestRepository _serviceRequestRepository;

  Future<Map<String, dynamic>> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    try {
      final result = await _apiService.get(
        ApiConfig.profiles,
        query: {
          'select': 'full_name,address,latitude,longitude',
          'id': 'eq.${user.id}',
          'limit': '1',
        },
      );

      if (result is! List || result.isEmpty) {
        throw Exception('Profile not found online.');
      }

      return Map<String, dynamic>.from(result.first as Map);
    } catch (error) {
      // Fall back to SQLite if the REST request fails.
      final localProfile = await _database.getUser(user.id);

      if (localProfile == null) {
        throw Exception(
          'No saved profile found. Please connect to the internet.',
        );
      }

      return Map<String, dynamic>.from(localProfile);
    }
  }

  Future<bool> submitRequest(Map<String, dynamic> requestData) async {
    final user = _authRepository.currentUser;

    if (user == null) {
      throw Exception('Please sign in before submitting a request.');
    }

    // Ensure the request belongs to the currently authenticated customer.
    final data = Map<String, dynamic>.from(requestData);
    data['customer_id'] = user.id;

    // Existing repository handles local-first storage and online sync.
    return _serviceRequestRepository.createRequest(data);
  }
}
