class TokenPackage {
  final String id;
  final String name;
  final int tokens;
  final double price;
  final String? description;
  final double? savings;
  final bool isPopular;

  TokenPackage({
    required this.id,
    required this.name,
    required this.tokens,
    required this.price,
    this.description,
    this.savings,
    this.isPopular = false,
  });

  factory TokenPackage.fromJson(Map<String, dynamic> json) {
    return TokenPackage(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      tokens: json['tokens'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      savings: (json['savings'] as num?)?.toDouble(),
      isPopular: json['isPopular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'tokens': tokens,
      'price': price,
      'description': description,
      'savings': savings,
      'isPopular': isPopular,
    };
  }
}

class Transaction {
  final String id;
  final String type; // 'purchase', 'usage', 'bonus', 'promo'
  final int amount;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'],
      type: json['type'] ?? 'usage',
      amount: json['amount'] ?? 0,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
