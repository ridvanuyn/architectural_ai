import '../api/api_client.dart';
import '../models/specialty_world.dart';

class WorldService {
  final ApiClient _client = ApiClient();

  // Cache the full world list so repeated search/pagination calls do not
  // hit the network every time. The production backend returns the complete
  // catalog (~281 items) in a single response and does not support
  // server-side filtering/pagination, so we paginate/filter on the client.
  List<SpecialtyWorld>? _cachedWorlds;
  DateTime? _cacheFetchedAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Fetch (and cache) the full list of worlds from the deployed backend.
  /// Handles both `{data: [...]}` and top-level-array response shapes.
  Future<List<SpecialtyWorld>> _fetchAllWorlds({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedWorlds != null &&
        _cacheFetchedAt != null &&
        now.difference(_cacheFetchedAt!) < _cacheTtl) {
      return _cachedWorlds!;
    }

    final response = await _client.get('/worlds', withAuth: false);

    List<dynamic> rawList;
    if (response is List) {
      rawList = response;
    } else if (response is Map && response['data'] is List) {
      rawList = response['data'] as List;
    } else if (response is Map && response['worlds'] is List) {
      rawList = response['worlds'] as List;
    } else {
      rawList = const [];
    }

    final worlds = rawList
        .map((json) => SpecialtyWorld.fromJson(json as Map<String, dynamic>))
        .toList();

    _cachedWorlds = worlds;
    _cacheFetchedAt = now;
    return worlds;
  }

  /// Get all specialty worlds (optionally filtered by category).
  Future<List<SpecialtyWorld>> getWorlds({String? category}) async {
    final worlds = await _fetchAllWorlds();
    if (category == null || category.isEmpty) return worlds;
    return worlds.where((w) => w.category == category).toList();
  }

  /// Search worlds with pagination.
  ///
  /// The production backend does not support `?q=` / `?page=` / `?limit=`,
  /// so we fetch the full list once and filter + paginate client-side.
  /// Return shape is preserved:
  ///   `{'worlds': List<SpecialtyWorld>, 'total': int, 'page': int, 'totalPages': int}`
  Future<Map<String, dynamic>> searchWorlds({
    String query = '',
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final all = await _fetchAllWorlds();

    Iterable<SpecialtyWorld> filtered = all;

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((w) => w.category == category);
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((w) {
        return w.name.toLowerCase().contains(q) ||
            w.description.toLowerCase().contains(q) ||
            w.category.toLowerCase().contains(q);
      });
    }

    final list = filtered.toList();
    final total = list.length;
    final safeLimit = limit > 0 ? limit : 20;
    final totalPages = total == 0 ? 1 : ((total + safeLimit - 1) ~/ safeLimit);
    final safePage = page < 1 ? 1 : (page > totalPages ? totalPages : page);

    final start = (safePage - 1) * safeLimit;
    final end = (start + safeLimit) > total ? total : (start + safeLimit);
    final pageItems = start >= total ? <SpecialtyWorld>[] : list.sublist(start, end);

    return {
      'worlds': pageItems,
      'total': total,
      'page': safePage,
      'totalPages': totalPages,
    };
  }

  /// Get featured worlds.
  /// `/worlds/featured` is broken on production, so derive from the full list.
  Future<List<SpecialtyWorld>> getFeaturedWorlds() async {
    final all = await _fetchAllWorlds();
    final featured = all.where((w) => w.isFeatured).toList();
    // If none are explicitly marked, fall back to the first handful so the
    // caller still gets something usable.
    if (featured.isNotEmpty) return featured;
    return all.take(10).toList();
  }

  /// Get world by ID.
  Future<SpecialtyWorld> getWorld(String id) async {
    final response = await _client.get('/worlds/$id', withAuth: false);
    if (response is Map && response['data'] != null) {
      return SpecialtyWorld.fromJson(response['data'] as Map<String, dynamic>);
    }
    return SpecialtyWorld.fromJson(response as Map<String, dynamic>);
  }

  /// Get categories.
  /// `/worlds/categories` may not exist on prod; derive from the full list.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final all = await _fetchAllWorlds();
    final counts = <String, int>{};
    for (final w in all) {
      if (w.category.isEmpty) continue;
      counts[w.category] = (counts[w.category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => <String, dynamic>{'name': e.key, 'count': e.value})
        .toList();
  }
}
