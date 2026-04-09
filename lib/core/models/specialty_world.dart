class SpecialtyWorld {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final String prompt;
  final double price;
  final bool isProOnly;
  final bool isFeatured;

  SpecialtyWorld({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.prompt,
    this.price = 0,
    this.isProOnly = false,
    this.isFeatured = false,
  });

  factory SpecialtyWorld.fromJson(Map<String, dynamic> json) {
    return SpecialtyWorld(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      prompt: json['prompt'],
      price: (json['price'] as num?)?.toDouble() ?? 0.99,
      isProOnly: json['isProOnly'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'prompt': prompt,
      'price': price,
      'isProOnly': isProOnly,
      'isFeatured': isFeatured,
    };
  }
}

