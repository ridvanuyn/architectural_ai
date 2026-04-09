import 'dart:io';

import '../api/api_client.dart';
import '../config/api_config.dart';
import '../models/design.dart';

class DesignService {
  final ApiClient _client = ApiClient();

  /// Get all designs
  Future<List<Design>> getDesigns({
    int page = 1,
    int limit = 20,
    String? status,
    bool? isFavorite,
  }) async {
    String endpoint = '${ApiConfig.designs}?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';
    if (isFavorite != null) endpoint += '&favorite=$isFavorite';

    final response = await _client.get(endpoint);
    final designs = (response['data'] as List)
        .map((json) => Design.fromJson(json))
        .toList();
    return designs;
  }

  /// Upload image and get URL
  Future<Map<String, dynamic>> uploadImage(File image) async {
    final response = await _client.uploadFile(
      '${ApiConfig.designs}/upload',
      image,
    );
    return response['data'];
  }

  /// Create new design
  Future<Design> createDesign({
    required String originalImageUrl,
    String? originalImageKey,
    String? styleId,
    String? roomType,
    String? title,
    String? customPrompt,
    bool isPremium = false,
    String tier = 'free',
  }) async {
    final response = await _client.post(
      ApiConfig.designs,
      body: {
        'originalImageUrl': originalImageUrl,
        if (originalImageKey != null) 'originalImageKey': originalImageKey,
        if (styleId != null) 'style': styleId,
        if (roomType != null) 'roomType': roomType,
        if (title != null) 'title': title,
        if (customPrompt != null) 'customPrompt': customPrompt,
        'isPremium': isPremium,
        'tier': tier,
      },
    );
    return Design.fromJson(response['data']);
  }

  /// Get design by ID
  Future<Design> getDesign(String id) async {
    final response = await _client.get('${ApiConfig.designs}/$id');
    return Design.fromJson(response['data']);
  }

  /// Get design status
  Future<Map<String, dynamic>> getDesignStatus(String id) async {
    final response = await _client.get('${ApiConfig.designs}/$id/status');
    return response['data'];
  }

  /// Delete design
  Future<void> deleteDesign(String id) async {
    await _client.delete('${ApiConfig.designs}/$id');
  }

  /// Toggle favorite
  Future<Design> toggleFavorite(String id) async {
    final response = await _client.put('${ApiConfig.designs}/$id/favorite');
    return Design.fromJson(response['data']);
  }

  /// Retry failed design
  Future<Design> retryDesign(String id) async {
    final response = await _client.post('${ApiConfig.designs}/$id/retry');
    return Design.fromJson(response['data']);
  }

  /// Get design stats
  Future<Map<String, dynamic>> getStats() async {
    final response = await _client.get(ApiConfig.designStats);
    return response['data'];
  }
}

