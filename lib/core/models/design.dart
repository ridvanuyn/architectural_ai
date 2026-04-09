class Design {
  final String id;
  final String userId;
  final String styleId;
  final String styleName;
  final String originalImageUrl;
  final String? transformedImageUrl;
  final String status;
  final bool isFavorite;
  final int tokensUsed;
  final DateTime createdAt;

  Design({
    required this.id,
    required this.userId,
    required this.styleId,
    required this.styleName,
    required this.originalImageUrl,
    this.transformedImageUrl,
    required this.status,
    this.isFavorite = false,
    this.tokensUsed = 2,
    required this.createdAt,
  });

  factory Design.fromJson(Map<String, dynamic> json) {
    // Backend sends nested originalImage.url / generatedImage.url
    final originalUrl = json['originalImageUrl'] ??
        (json['originalImage'] is Map ? json['originalImage']['url'] : null) ??
        '';
    final transformedUrl = json['transformedImageUrl'] ??
        (json['generatedImage'] is Map ? json['generatedImage']['url'] : null);
    final styleName = json['styleName'] ??
        (json['style'] is Map ? json['style']['name'] : null) ??
        json['title'] ??
        json['style'] ??
        'Unknown';

    return Design(
      id: json['_id'] ?? json['id'],
      userId: json['user'] ?? json['userId'] ?? '',
      styleId: json['styleId'] ?? (json['style'] is String ? json['style'] : '') ?? '',
      styleName: styleName,
      originalImageUrl: originalUrl,
      transformedImageUrl: transformedUrl,
      status: json['status'] ?? 'pending',
      isFavorite: json['isFavorite'] ?? false,
      tokensUsed: json['tokensUsed'] ?? 2,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'styleId': styleId,
      'styleName': styleName,
      'originalImageUrl': originalImageUrl,
      'transformedImageUrl': transformedImageUrl,
      'status': status,
      'isFavorite': isFavorite,
      'tokensUsed': tokensUsed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Design copyWith({
    String? id,
    String? userId,
    String? styleId,
    String? styleName,
    String? originalImageUrl,
    String? transformedImageUrl,
    String? status,
    bool? isFavorite,
    int? tokensUsed,
    DateTime? createdAt,
  }) {
    return Design(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      styleId: styleId ?? this.styleId,
      styleName: styleName ?? this.styleName,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      transformedImageUrl: transformedImageUrl ?? this.transformedImageUrl,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
}
