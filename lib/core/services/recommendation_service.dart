import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/design.dart';
import 'style_service.dart';
import 'world_service.dart';

/// Unified item for recommendations — wraps both styles and worlds.
/// [prompt] is non-null only for world items — styles rely on style.id instead.
class RecommendationItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final int popularity;
  final String? prompt;

  const RecommendationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.tags = const [],
    this.popularity = 0,
    this.prompt,
  });

  bool get isWorld => prompt != null;
}

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  static const int _maxCacheSize = 100;

  final StyleService _styleService = StyleService();
  final WorldService _worldService = WorldService();

  // FIFO cache: key = cacheKey, value = recommendations
  final LinkedHashMap<String, List<RecommendationItem>> _cache =
      LinkedHashMap<String, List<RecommendationItem>>();

  // Cached pool from API
  List<RecommendationItem>? _pool;
  DateTime? _poolFetchedAt;
  static const _cacheTtl = Duration(minutes: 10);

  // Keyword clusters for franchise/theme matching
  static const Map<String, List<String>> _themeClusters = {
    'harry_potter': ['harry', 'potter', 'hogwarts', 'gryffindor', 'slytherin', 'hufflepuff', 'ravenclaw', 'wizard', 'magic', 'dumbledore'],
    'star_wars': ['star', 'wars', 'jedi', 'sith', 'millennium', 'falcon', 'lightsaber', 'galaxy', 'force'],
    'lord_of_rings': ['lord', 'rings', 'hobbit', 'middle', 'earth', 'elven', 'gondor', 'shire', 'mordor'],
    'game_of_thrones': ['thrones', 'westeros', 'winterfell', 'iron', 'throne', 'stark', 'lannister', 'targaryen', 'dragon'],
    'cyberpunk': ['cyberpunk', 'neon', 'blade', 'runner', 'dystopian', 'cyber', 'night', 'city', 'futuristic'],
    'matrix': ['matrix', 'neo', 'digital', 'construct', 'nebuchadnezzar'],
    'stranger_things': ['stranger', 'things', 'upside', 'down', '80s', 'retro', 'hawkins'],
    'minecraft': ['minecraft', 'block', 'pixel', 'voxel', 'craft'],
    'anime': ['anime', 'ghibli', 'manga', 'taisho', 'demon', 'slayer', 'titan', 'attack'],
    'zelda': ['zelda', 'hyrule', 'link', 'kingdom'],
    'historical': ['victorian', 'egyptian', 'gatsby', '1800s', 'gothic', 'renaissance', 'medieval', 'roman', 'palace'],
    'fantasy': ['fantasy', 'magical', 'enchanted', 'castle', 'dragon', 'elf', 'fairy'],
    'modern': ['modern', 'minimal', 'contemporary', 'scandinavian', 'japandi', 'clean'],
    'industrial': ['industrial', 'loft', 'brick', 'concrete', 'factory', 'urban'],
    'nature': ['boho', 'tropical', 'zen', 'garden', 'organic', 'natural', 'forest'],
  };

  /// Get recommendations for the current design.
  /// [currentStyleId] - styleId of current design
  /// [currentStyleName] - styleName of current design (used for keyword matching)
  /// [userDesigns] - user's designs to filter out already-used items
  Future<List<RecommendationItem>> getRecommendations({
    required String currentStyleId,
    required String currentStyleName,
    required List<Design> userDesigns,
  }) async {
    final cacheKey = '${currentStyleId}_$currentStyleName';

    // Check cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    await _ensurePoolLoaded();
    if (_pool == null || _pool!.isEmpty) return [];

    // IDs the user already used
    final usedIds = <String>{};
    final usedNames = <String>{};
    for (final d in userDesigns) {
      usedIds.add(d.styleId);
      usedNames.add(d.styleName.toLowerCase());
    }

    // Detect which theme clusters the current design belongs to
    final currentNameLower = currentStyleName.toLowerCase();
    final matchedClusters = <String>{};
    for (final entry in _themeClusters.entries) {
      for (final keyword in entry.value) {
        if (currentNameLower.contains(keyword)) {
          matchedClusters.add(entry.key);
          break;
        }
      }
    }

    // Score and rank candidates
    final scored = <_ScoredItem>[];
    for (final item in _pool!) {
      // Skip current and already-used
      if (item.id == currentStyleId) continue;
      if (usedIds.contains(item.id)) continue;
      if (usedNames.contains(item.name.toLowerCase())) continue;

      final score = _scoreItem(item, currentNameLower, matchedClusters);
      scored.add(_ScoredItem(item, score));
    }

    // Sort by score descending, then popularity
    scored.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      return b.item.popularity.compareTo(a.item.popularity);
    });

    final result = scored.take(10).map((s) => s.item).toList();

    _addToCache(cacheKey, result);
    return result;
  }

  int _scoreItem(
    RecommendationItem item,
    String currentNameLower,
    Set<String> matchedClusters,
  ) {
    int score = 0;
    final itemNameLower = item.name.toLowerCase();
    final itemDescLower = item.description.toLowerCase();
    final combined = '$itemNameLower $itemDescLower ${item.category.toLowerCase()}';

    // Same theme cluster = highest relevance (+100 per cluster match)
    for (final cluster in matchedClusters) {
      final keywords = _themeClusters[cluster]!;
      for (final keyword in keywords) {
        if (combined.contains(keyword)) {
          score += 100;
          break;
        }
      }
    }

    // Same category bonus
    // Extract category keywords from current name for matching
    if (item.category.isNotEmpty) {
      for (final cluster in matchedClusters) {
        if (item.category.toLowerCase().contains(cluster)) {
          score += 50;
        }
      }
    }

    // Shared word bonus (direct name similarity)
    final currentWords = currentNameLower.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    for (final word in currentWords) {
      if (itemNameLower.contains(word)) {
        score += 30;
      }
    }

    // Base popularity bonus (small, so relevance dominates)
    score += (item.popularity ~/ 10).clamp(0, 20);

    return score;
  }

  void _addToCache(String key, List<RecommendationItem> value) {
    while (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  Future<void> _ensurePoolLoaded() async {
    final now = DateTime.now();
    if (_pool != null &&
        _poolFetchedAt != null &&
        now.difference(_poolFetchedAt!) < _cacheTtl) {
      return;
    }

    final items = <RecommendationItem>[];

    // Fetch styles
    try {
      final styles = await _styleService.getStyles();
      for (final s in styles) {
        items.add(RecommendationItem(
          id: s.id,
          name: s.name,
          description: s.description,
          imageUrl: s.imageUrl,
          category: s.category,
          tags: s.tags,
          popularity: s.usageCount,
        ));
      }
    } catch (e) {
      debugPrint('RecommendationService: failed to load styles: $e');
    }

    // Fetch worlds
    try {
      final worlds = await _worldService.getWorlds();
      for (final w in worlds) {
        // Avoid duplicates by id
        if (items.any((i) => i.id == w.id)) continue;
        items.add(RecommendationItem(
          id: w.id,
          name: w.name,
          description: w.description,
          imageUrl: w.imageUrl,
          category: w.category,
          prompt: w.prompt,
        ));
      }
    } catch (e) {
      debugPrint('RecommendationService: failed to load worlds: $e');
    }

    if (items.isNotEmpty) {
      _pool = items;
      _poolFetchedAt = now;
    }
  }

  void clearCache() {
    _cache.clear();
    _pool = null;
    _poolFetchedAt = null;
  }
}

class _ScoredItem {
  final RecommendationItem item;
  final int score;
  _ScoredItem(this.item, this.score);
}
