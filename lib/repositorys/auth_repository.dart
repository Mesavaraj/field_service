import 'package:field_service/core/config/api_config.dart';
import 'package:field_service/models/profile_model.dart';
import 'package:field_service/providers/internet_provider.dart';
import 'package:field_service/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database.dart';

class AuthRepository {
  AuthRepository({
    required this._apiService,
    required this._client,
    required this._internetProvider,
    required this._localDatabase,
  });

  final SupabaseClient _client;
  final InternetProvider _internetProvider;
  final ApiService _apiService;
  final LocalDatabase _localDatabase;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final hasInternet = await _internetProvider.checkInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please try again.');
    }

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
    );

    final user = response.user;

    if (user == null) {
      throw const AuthException('Account creation failed.');
    }

    // A session may be absent when email confirmation is required.
    if (response.session != null) {
      // online
      final profile = await _apiService.get(
        ApiConfig.profiles,
        query: {
          'select': 'id,full_name,role,created_at,updated_at',
          'id': 'eq.${user.id}',
        },
      );

      // offline
      final model = ProfileModel.fromMap(profile, email: user.email);
      await _localDatabase.saveUser(model.toMap());
    }
  }

  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    final hasInternet = await _internetProvider.checkInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please try again.');
    }

    try {
      print('LOGIN 1: Signing in to Supabase');

      final session = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = session.user;
      print('LOGIN 2: Authenticated user ID: ${user!.id}');
      print('LOGIN 3: Session exists: ${_client.auth.currentSession != null}');

      print('LOGIN 4: Fetching profile');

      // final profileData = await _client
      //     .from('profiles')
      //     .select('id, full_name, role, created_at, updated_at')
      //     .eq('id', user.id)
      //     .maybeSingle();

      final profileData = await _apiService.get(
        ApiConfig.profiles,
        query: {
          'select': 'id,full_name,role,created_at,updated_at',
          'id': 'eq.${user.id}',
        },
      );

      if (profileData == null) {
        throw Exception(
          'Profile not found. Check public.profiles and its RLS SELECT policy.',
        );
      }

      print('LOGIN 5: Profile received: $profileData');

      if (profileData is! List || profileData.isEmpty) {
        throw Exception(
          'No profile found for user ${user.id}. '
          'Check public.profiles and its RLS SELECT policy.',
        );
      }

      final profileMap = Map<String, dynamic>.from(profileData.first as Map);

      final profile = ProfileModel.fromMap(profileMap, email: user.email);

      print('LOGIN 6: Saving profile to SQLite');

      await _localDatabase.saveUser(profile.toMap());

      print('LOGIN 7: Login completed successfully');

      return profile;
    } catch (error, stackTrace) {
      print('LOGIN ERROR: $error');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final hasInternet = await _internetProvider.checkInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please try again.');
    }

    await _client.auth.signOut();
  }

  Future<ProfileModel?> getCachedUser(String userId) async {
    final result = await _localDatabase.getUser(userId);

    if (result == null) return null;

    return ProfileModel.fromMap(result);
  }

  Future<ProfileModel?> getCurrentUserOffline() async {
    final user = _client.auth.currentUser;

    if (user == null) return null;

    return getCachedUser(user.id);
  }
}
