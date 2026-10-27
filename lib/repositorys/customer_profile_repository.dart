import 'package:field_service/database/local_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/api_config.dart';
import '../services/api_service.dart';

class CustomerProfileRepository {
  CustomerProfileRepository({
    required this._apiService,
    required this._localDatabase,
  });
  final ApiService _apiService;
  final LocalDatabase _localDatabase;

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.id != userId) {
      throw Exception('Please sign in again.');
    }

    try {
      final result = await _apiService.get(
        ApiConfig.profiles,
        query: {
          'select': 'id,full_name,address,latitude,longitude,updated_at',
          'id': 'eq.$userId',
          'limit': '1',
        },
      );

      if (result is! List || result.isEmpty) {
        throw Exception('Profile not found online.');
      }

      final profile = Map<String, dynamic>.from(result.first as Map);
      profile['email'] = user.email ?? '';
      return profile;
    } catch (error) {
      // Use SQLite when the online request fails.
      final localProfile = await _localDatabase.getUser(userId);

      if (localProfile == null) {
        throw Exception('Unable to load your profile online or offline.');
      }

      final profile = Map<String, dynamic>.from(localProfile);
      profile['email'] = profile['email']?.toString() ?? user.email ?? '';

      return profile;
    }
  }

  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required String address,
    required double? latitude,
    required double? longitude,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.id != userId) {
      throw Exception('Please sign in again.');
    }

    // Save the address and coordinates locally first.
    await _localDatabase.updateLocalAddress(
      userId: userId,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );

    // Update the profile using the REST API.
    await _apiService.patch(
      ApiConfig.profiles,
      query: {'id': 'eq.$userId'},
      body: {
        'full_name': fullName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await _localDatabase.markUserSynced(userId);
  }
}
