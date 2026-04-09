import '../api/api_client.dart';
import '../config/api_config.dart';
import '../models/style.dart';

class StyleService {
  final ApiClient _client = ApiClient();

  /// Get all styles (sorted by popularity from backend)
  Future<List<DesignStyle>> getStyles() async {
    final response = await _client.get(ApiConfig.styles, withAuth: false);
    final styles = (response['data'] as List)
        .map((json) => DesignStyle.fromJson(json))
        .toList();
    return styles;
  }

  /// Get style by ID
  Future<DesignStyle> getStyle(String id) async {
    final response = await _client.get('${ApiConfig.styles}/$id');
    return DesignStyle.fromJson(response['style']);
  }

  /// Get room types
  Future<List<String>> getRoomTypes() async {
    final response = await _client.get(ApiConfig.roomTypes);
    return List<String>.from(response['roomTypes']);
  }

  /// Get style recommendations for room type
  Future<List<DesignStyle>> getRecommendations(String roomType) async {
    final response = await _client.get(
      '${ApiConfig.styles}/recommendations/$roomType',
    );
    final styles = (response['styles'] as List)
        .map((json) => DesignStyle.fromJson(json))
        .toList();
    return styles;
  }
}

