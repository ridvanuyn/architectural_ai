import '../api/api_client.dart';
import '../models/specialty_world.dart';

class WorldService {
  final ApiClient _client = ApiClient();

  /// Get all specialty worlds
  Future<List<SpecialtyWorld>> getWorlds({String? category}) async {
    String endpoint = '/worlds';
    if (category != null) {
      endpoint += '?category=$category';
    }

    final response = await _client.get(endpoint, withAuth: false);
    final worlds = (response['data'] as List)
        .map((json) => SpecialtyWorld.fromJson(json))
        .toList();
    return worlds;
  }

  /// Get featured worlds
  Future<List<SpecialtyWorld>> getFeaturedWorlds() async {
    final response = await _client.get('/worlds/featured', withAuth: false);
    final worlds = (response['data'] as List)
        .map((json) => SpecialtyWorld.fromJson(json))
        .toList();
    return worlds;
  }

  /// Get world by ID
  Future<SpecialtyWorld> getWorld(String id) async {
    final response = await _client.get('/worlds/$id', withAuth: false);
    return SpecialtyWorld.fromJson(response['data']);
  }

  /// Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.get('/worlds/categories', withAuth: false);
    return List<Map<String, dynamic>>.from(response['data']);
  }
}

