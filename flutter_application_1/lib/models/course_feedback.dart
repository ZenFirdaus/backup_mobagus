class CourseFeedback {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String kesan;
  final String saran;
  final int rating;
  final DateTime createdAt;

  const CourseFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.kesan,
    required this.saran,
    this.rating = 5,
    required this.createdAt,
  });

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
        'kesan': kesan,
        'saran': saran,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
      };
}
