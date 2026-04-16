import '../api/api_client.dart';
import '../config/api_config.dart';
import '../models/token_package.dart';

class TokenService {
  final ApiClient _client = ApiClient();

  /// Get token packages (public endpoint)
  Future<List<TokenPackage>> getPackages() async {
    final response = await _client.get(ApiConfig.tokenPackages, withAuth: false);
    final packages = (response['data'] as List)
        .map((json) => TokenPackage.fromJson(json))
        .toList();
    return packages;
  }

  /// Get token balance
  Future<Map<String, dynamic>> getBalance() async {
    final response = await _client.get(ApiConfig.tokenBalance);
    return response['data'] ?? response;
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '${ApiConfig.tokenTransactions}?page=$page&limit=$limit',
    );
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Purchase tokens
  Future<Map<String, dynamic>> purchase({
    required String packageId,
    required String receipt,
    required String platform,
  }) async {
    final response = await _client.post(
      ApiConfig.tokenPurchase,
      body: {
        'packageId': packageId,
        'receipt': receipt,
        'platform': platform,
      },
    );
    return response;
  }

  /// Apply promo code
  Future<Map<String, dynamic>> applyPromoCode(String code) async {
    final response = await _client.post(
      ApiConfig.tokenPromo,
      body: {'code': code},
    );
    return response['data'] ?? response;
  }

  /// Grant tokens to current user (used for premium monthly bonus)
  Future<Map<String, dynamic>> grantTokens({
    required int amount,
    String? reason,
  }) async {
    final response = await _client.post(
      ApiConfig.tokenGrant,
      body: {
        'amount': amount,
        if (reason != null) 'reason': reason,
      },
    );
    return response['data'] ?? response;
  }

  /// Refund tokens after a failed design generation
  Future<Map<String, dynamic>> refundTokens({
    String? designId,
    required int amount,
    String? reason,
  }) async {
    final response = await _client.post(
      ApiConfig.tokenRefund,
      body: {
        if (designId != null) 'designId': designId,
        'amount': amount,
        if (reason != null) 'reason': reason,
      },
    );
    return response['data'] ?? response;
  }
}

