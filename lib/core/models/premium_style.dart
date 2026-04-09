class PremiumStyle {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category; // 'movie', 'series', 'anime', 'game'
  final int tokenPrice;
  final double dollarPrice;
  final String franchise;
  final bool isOwned;

  const PremiumStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.tokenPrice = 30,
    this.dollarPrice = 0.99,
    required this.franchise,
    this.isOwned = false,
  });

  PremiumStyle copyWith({bool? isOwned}) {
    return PremiumStyle(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      category: category,
      tokenPrice: tokenPrice,
      dollarPrice: dollarPrice,
      franchise: franchise,
      isOwned: isOwned ?? this.isOwned,
    );
  }

  factory PremiumStyle.fromJson(Map<String, dynamic> json) {
    return PremiumStyle(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'movie',
      tokenPrice: json['tokenPrice'] ?? 30,
      dollarPrice: (json['dollarPrice'] as num?)?.toDouble() ?? 0.99,
      franchise: json['franchise'] ?? '',
      isOwned: json['isOwned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'tokenPrice': tokenPrice,
      'dollarPrice': dollarPrice,
      'franchise': franchise,
      'isOwned': isOwned,
    };
  }

  // All available premium styles
  static const List<PremiumStyle> all = [
    // Movies
    PremiumStyle(
      id: 'harry_potter',
      name: 'Hogwarts Magic',
      description: 'Wizarding world aesthetics with magical details',
      imageUrl: 'https://images.unsplash.com/photo-1551269901-5c5e14c25df7?w=400',
      category: 'movie',
      franchise: 'Harry Potter',
    ),
    PremiumStyle(
      id: 'lord_of_rings',
      name: 'Middle Earth',
      description: 'Elven elegance meets Hobbit comfort',
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
      category: 'movie',
      franchise: 'Lord of the Rings',
    ),
    PremiumStyle(
      id: 'star_wars',
      name: 'Galaxy Far Away',
      description: 'Futuristic meets ancient Jedi temple',
      imageUrl: 'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?w=400',
      category: 'movie',
      franchise: 'Star Wars',
    ),
    PremiumStyle(
      id: 'blade_runner',
      name: 'Cyberpunk Noir',
      description: 'Neon-lit dystopian future aesthetic',
      imageUrl: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400',
      category: 'movie',
      franchise: 'Blade Runner',
    ),
    PremiumStyle(
      id: 'the_matrix',
      name: 'Digital Reality',
      description: 'Green-tinted digital world design',
      imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400',
      category: 'movie',
      franchise: 'The Matrix',
    ),
    
    // Series
    PremiumStyle(
      id: 'game_of_thrones',
      name: 'Westeros Castle',
      description: 'Medieval fantasy castle interiors',
      imageUrl: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?w=400',
      category: 'series',
      franchise: 'Game of Thrones',
    ),
    PremiumStyle(
      id: 'stranger_things',
      name: '80s Nostalgia',
      description: 'Retro 80s with supernatural vibes',
      imageUrl: 'https://images.unsplash.com/photo-1557683316-973673baf926?w=400',
      category: 'series',
      franchise: 'Stranger Things',
    ),
    PremiumStyle(
      id: 'breaking_bad',
      name: 'Desert Modern',
      description: 'Southwest minimalism with edge',
      imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=400',
      category: 'series',
      franchise: 'Breaking Bad',
    ),
    PremiumStyle(
      id: 'peaky_blinders',
      name: 'Victorian Industrial',
      description: '1920s British industrial elegance',
      imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
      category: 'series',
      franchise: 'Peaky Blinders',
    ),
    PremiumStyle(
      id: 'the_witcher',
      name: 'Dark Fantasy',
      description: 'Medieval dark fantasy aesthetic',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      category: 'series',
      franchise: 'The Witcher',
    ),
    
    // Anime
    PremiumStyle(
      id: 'studio_ghibli',
      name: 'Ghibli Dreams',
      description: 'Whimsical Japanese animation style',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
      category: 'anime',
      franchise: 'Studio Ghibli',
    ),
    PremiumStyle(
      id: 'attack_titan',
      name: 'Titan Fortress',
      description: 'Medieval military architecture',
      imageUrl: 'https://images.unsplash.com/photo-1464817739973-0128fe77aaa1?w=400',
      category: 'anime',
      franchise: 'Attack on Titan',
    ),
    PremiumStyle(
      id: 'demon_slayer',
      name: 'Taisho Era',
      description: 'Traditional Japanese with demon aesthetic',
      imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400',
      category: 'anime',
      franchise: 'Demon Slayer',
    ),
    
    // Games
    PremiumStyle(
      id: 'minecraft',
      name: 'Block World',
      description: 'Pixelated cubic construction style',
      imageUrl: 'https://images.unsplash.com/photo-1587573089734-599d584d7b9a?w=400',
      category: 'game',
      franchise: 'Minecraft',
    ),
    PremiumStyle(
      id: 'zelda',
      name: 'Hyrule Kingdom',
      description: 'Fantasy adventure castle design',
      imageUrl: 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=400',
      category: 'game',
      franchise: 'Zelda',
    ),
    PremiumStyle(
      id: 'cyberpunk_2077',
      name: 'Night City',
      description: 'High-tech low-life urban aesthetic',
      imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=400',
      category: 'game',
      franchise: 'Cyberpunk 2077',
    ),
  ];

  static List<PremiumStyle> byCategory(String category) {
    return all.where((s) => s.category == category).toList();
  }
}

