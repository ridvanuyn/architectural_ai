import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;

  bool get isAuthenticated => _accessToken != null;

  /// Initialize client and load saved tokens
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _initialized = true;
  }

  /// Save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  /// Build headers
  Map<String, String> _headers({bool withAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (withAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    return headers;
  }

  /// Parse response
  dynamic _parseResponse(http.Response response) {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Unknown error',
    );
  }

  /// Refresh access token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authRefresh}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
    } catch (e) {
      // Ignore
    }
    
    await clearTokens();
    return false;
  }

  /// GET request
  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(withAuth: withAuth),
    );
    
    // Handle token expiration
    if (response.statusCode == 401 && withAuth) {
      if (await _refreshAccessToken()) {
        return get(endpoint, withAuth: withAuth);
      }
    }
    
    return _parseResponse(response);
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    
    if (response.statusCode == 401 && withAuth) {
      if (await _refreshAccessToken()) {
        return post(endpoint, body: body, withAuth: withAuth);
      }
    }
    
    return _parseResponse(response);
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(withAuth: withAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    
    if (response.statusCode == 401 && withAuth) {
      if (await _refreshAccessToken()) {
        return put(endpoint, body: body, withAuth: withAuth);
      }
    }
    
    return _parseResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers(withAuth: withAuth),
    );
    
    if (response.statusCode == 401 && withAuth) {
      if (await _refreshAccessToken()) {
        return delete(endpoint, withAuth: withAuth);
      }
    }
    
    return _parseResponse(response);
  }

  /// Upload file
  Future<dynamic> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    bool withAuth = true,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
    );
    
    if (withAuth && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    // Add file with explicit content type
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
    }[ext] ?? 'image/jpeg';

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      file.path,
      contentType: MediaType.parse(contentType),
    ));
    
    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 401 && withAuth) {
      if (await _refreshAccessToken()) {
        return uploadFile(endpoint, file, fields: fields, withAuth: withAuth);
      }
    }
    
    return _parseResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
