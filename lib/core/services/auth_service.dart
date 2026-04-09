import '../api/api_client.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  /// Register with email
  Future<User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _client.post(
      ApiConfig.authRegister,
      body: {
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      },
    );

    await _client.saveTokens(
      response['accessToken'],
      response['refreshToken'],
    );

    return User.fromJson(response['user']);
  }

  /// Login with email
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConfig.authLogin,
      body: {
        'email': email,
        'password': password,
      },
    );

    await _client.saveTokens(
      response['accessToken'],
      response['refreshToken'],
    );

    return User.fromJson(response['user']);
  }

  /// OAuth login (Google/Apple)
  Future<User> oAuthLogin({
    required String provider,
    required String idToken,
  }) async {
    final response = await _client.post(
      ApiConfig.authOAuth,
      body: {
        'provider': provider,
        'idToken': idToken,
      },
    );

    await _client.saveTokens(
      response['accessToken'],
      response['refreshToken'],
    );

    return User.fromJson(response['user']);
  }

  /// Get current user
  Future<User> getCurrentUser() async {
    final response = await _client.get(ApiConfig.authMe);
    return User.fromJson(response['user']);
  }

  /// Update profile
  Future<User> updateProfile({String? name, String? avatar}) async {
    final response = await _client.put(
      ApiConfig.authMe,
      body: {
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
      },
    );
    return User.fromJson(response['user']);
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _client.post(ApiConfig.authOnboarding);
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _client.post(ApiConfig.authLogout);
    } finally {
      await _client.clearTokens();
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client.isAuthenticated;
}

