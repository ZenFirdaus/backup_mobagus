class Review {
  final String id;
  final String userId;
  final String restaurantId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? restaurantName;

  const Review({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.restaurantName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final restMap = json['restaurants'] as Map<String, dynamic>?;
    return Review(
      id: json['id'].toString(),
      userId: json['user_id'] as String? ?? '',
      restaurantId: json['restaurant_id'].toString(),
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      userName: json['user_name'] as String? ?? profile?['display_name'] as String?,
      restaurantName: restMap?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'restaurant_id': restaurantId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
    'user_name': userName,
    'restaurant_name': restaurantName,
  };
}
