import 'dart:convert';

import 'package:field_service/core/config/api_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception('Supabase publishable key is missing.');
    }

    if (session == null) {
      throw Exception('Please sign in again.');
    }

    return {
      'apikey': publishableKey,
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  Uri _buildUri(String endpoint, {Map<String, String>? query}) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    return uri.replace(queryParameters: query);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    throw Exception('HTTP ${response.statusCode}: $body');
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? query}) async {
    final response = await _client.get(
      _buildUri(endpoint, query: query),
      headers: _headers,
    );

    return _decodeResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      _buildUri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<dynamic> patch(
    String endpoint, {
    required Map<String, String> query,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      _buildUri(endpoint, query: query),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    required Map<String, String> query,
  }) async {
    final response = await _client.delete(
      _buildUri(endpoint, query: query),
      headers: _headers,
    );

    return _decodeResponse(response);
  }

  void dispose() {
    _client.close();
  }
}
