class DesignStyle {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int tokenCost;
  final bool isPremium;
  final String category;
  final List<String> tags;
  final int usageCount;

  DesignStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.tokenCost = 1,
    this.isPremium = false,
    this.category = 'base',
    this.tags = const [],
    this.usageCount = 0,
  });

  factory DesignStyle.fromJson(Map<String, dynamic> json) {
    return DesignStyle(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      tokenCost: json['tokenCost'] ?? json['tokens'] ?? 1,
      isPremium: json['isPremium'] ?? false,
      category: json['category'] ?? 'base',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      usageCount: json['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'tokenCost': tokenCost,
      'isPremium': isPremium,
      'category': category,
      'tags': tags,
    };
  }
}
