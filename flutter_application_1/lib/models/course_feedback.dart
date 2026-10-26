class CourseFeedback {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? userActiveBorder;
  final String kesan;
  final String saran;
  final int rating;
  final DateTime createdAt;

  const CourseFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.userActiveBorder,
    required this.kesan,
    required this.saran,
    this.rating = 5,
    required this.createdAt,
  });

  CourseFeedback copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? userActiveBorder,
    String? kesan,
    String? saran,
    int? rating,
    DateTime? createdAt,
  }) {
    return CourseFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userActiveBorder: userActiveBorder ?? this.userActiveBorder,
      kesan: kesan ?? this.kesan,
      saran: saran ?? this.saran,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CourseFeedback.fromJson(Map<String, dynamic> json) {
    return CourseFeedback(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String? ??
          (json['profiles'] != null && json['profiles'] is Map
              ? (json['profiles'] as Map)['display_name'] as String?
              : null) ??
          'Mahasiswa',
      userAvatar: json['user_avatar'] as String? ??
          (json['profiles'] != null && json['profiles'] is Map
              ? (json['profiles'] as Map)['avatar_url'] as String?
              : null),
      userActiveBorder: json['user_active_border'] as String? ??
          json['active_border_id'] as String? ??
          (json['profiles'] != null && json['profiles'] is Map
              ? (json['profiles'] as Map)['active_border_id'] as String?
              : null),
      kesan: json['kesan'] as String? ??
          json['comment'] as String? ??
          json['message'] as String? ??
          '',
      saran: json['saran'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_avatar': userAvatar,
        'user_active_border': userActiveBorder,
        'kesan': kesan,
        'saran': saran,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
      };
}

