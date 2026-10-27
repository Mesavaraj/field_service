import 'package:field_service/database/local_database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/api_config.dart';
import '../services/api_service.dart';

class ServiceRequestRepository {
  final LocalDatabase _localDatabase;
  final SupabaseClient _client;
  final ApiService _apiService;
  ServiceRequestRepository({
    required this._localDatabase,
    required this._client,
    required this._apiService,
  });

  final Uuid _uuid = const Uuid();

  Future<bool> createRequest(Map<String, dynamic> requestData) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in before creating a request.');
    }

    final requestId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    final request = <String, dynamic>{
      'id': requestId,
      'customer_id': user.id,
      'category': requestData['category'],
      'description': requestData['description'],
      'address': requestData['address'],
      'latitude': requestData['latitude'],
      'longitude': requestData['longitude'],
      'preferred_date': requestData['preferred_date'],
      'status': 'pending',
      'created_at': now,
      'is_synced': 0,
      'server_id': null,
    };

    // Save locally first. If this fails, throw an error.
    await _localDatabase.insertServiceRequest(request);

    try {
      await _client.from('service_requests').insert({
        'id': requestId,
        'customer_id': user.id,
        'category': request['category'],
        'description': request['description'],
        'address': request['address'],
        'latitude': request['latitude'],
        'longitude': request['longitude'],
        'preferred_date': request['preferred_date'],
        'status': 'pending',
        'created_at': now,
      });

      await _localDatabase.markServiceRequestSynced(requestId, requestId);

      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        try {
          final existing = await _apiService.get(
            ApiConfig.serviceRequests,
            query: {
              'select': 'id',
              'id': 'eq.$requestId',
              'customer_id': 'eq.${user.id}',
              'limit': '1',
            },
          );

          if (existing != null) {
            await _localDatabase.markServiceRequestSynced(requestId, requestId);
            return true;
          }
        } catch (_) {
          // Keep the local request pending if verification fails.
        }
      }

      // Request is stored in SQLite and awaits synchronization.
      return false;
    } catch (_) {
      // Network failure: keep the local request pending.
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentRequests(
    String customerId,
  ) async {
    // Implement using your existing SQLite query method.
    final localRequests = await _localDatabase.getServiceRequestsByCustomer(
      customerId,
    );

    try {
      final response = await Supabase.instance.client
          .from('service_requests')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(5);

      final onlineRequests = List<Map<String, dynamic>>.from(response);

      // TODO: Save online results into SQLite so they are
      // available offline on the next app launch.
      return onlineRequests;
    } catch (e) {
      debugPrint('Using offline requests: $e');
      return localRequests;
    }
  }
}
