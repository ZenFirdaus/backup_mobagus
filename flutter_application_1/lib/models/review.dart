class Review {
  final String id;
  final String userId;
  final String restaurantId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;
  final String? userActiveBorder;
  final String? restaurantName;

  const Review({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.userAvatar,
    this.userActiveBorder,
    this.restaurantName,
  });

  Review copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? userName,
    String? userAvatar,
    String? userActiveBorder,
    String? restaurantName,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userActiveBorder: userActiveBorder ?? this.userActiveBorder,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final restMap = json['restaurants'] as Map<String, dynamic>?;
    final rawName =
        json['restaurant_name'] as String? ?? restMap?['name'] as String?;
    return Review(
      id: json['id'].toString(),
      userId: json['user_id'] as String? ?? '',
      restaurantId: json['restaurant_id'].toString(),
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      userName: json['user_name'] as String? ?? profile?['display_name'] as String?,
      userAvatar: json['user_avatar'] as String? ?? profile?['avatar_url'] as String?,
      userActiveBorder: json['user_active_border'] as String? ??
          profile?['active_border_id'] as String?,
      restaurantName: (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : null,
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
    'user_avatar': userAvatar,
    'user_active_border': userActiveBorder,
    'restaurant_name': restaurantName,
  };
}
