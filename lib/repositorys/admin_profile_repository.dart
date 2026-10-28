import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProfileRepository {
  final SupabaseClient _supabase;

  AdminProfileRepository(this._supabase);

  Future<Map<String, dynamic>> getAdminProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    final response = await _supabase
        .from('profiles')
        .select('id, full_name, role, created_at')
        .eq('id', user.id)
        .single();

    final profile = Map<String, dynamic>.from(response);

    if (profile['role'] != 'admin') {
      throw Exception('This page is only available to admins.');
    }

    profile['email'] = user.email ?? '';

    return profile;
  }

  Future<void> updateAdminName(String fullName) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in again.');
    }

    final name = fullName.trim();

    if (name.isEmpty) {
      throw Exception('Name cannot be empty.');
    }

    await _supabase
        .from('profiles')
        .update({
          'full_name': name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
