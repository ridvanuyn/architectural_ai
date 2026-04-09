class User {
  final String id;
  final String? email;
  final String? name;
  final String? avatar;
  final int tokens;
  final bool isPremium;
  final bool onboardingCompleted;
  final DateTime createdAt;

  User({
    required this.id,
    this.email,
    this.name,
    this.avatar,
    this.tokens = 0,
    this.isPremium = false,
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      tokens: json['tokens'] ?? 0,
      isPremium: json['isPremium'] ?? false,
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'tokens': tokens,
      'isPremium': isPremium,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
