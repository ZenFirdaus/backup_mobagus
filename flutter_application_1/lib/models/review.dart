class Review {
  final String id;
  final String userId;
  final String restaurantId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;

  const Review({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return Review(
      id: json['id'].toString(),
      userId: json['user_id'] as String? ?? '',
      restaurantId: json['restaurant_id'].toString(),
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      userName: profile?['display_name'] as String?,
    );
  }
}
