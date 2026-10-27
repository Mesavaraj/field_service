import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // for init
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  static void validate() {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError('Supabase configuration is missing from .env');
    }
  }

  // for rest
  static final String baseUrl = '${dotenv.env['SUPABASE_URL']}/rest/v1';

  static const String profiles = '/profiles';
  static const String tasks = '/tasks';
  static const String serviceRequests = '/service_requests';
}
