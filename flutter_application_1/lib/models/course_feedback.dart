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
  }) =>
      CourseFeedback(
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

  factory CourseFeedback.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] is Map ? json['profiles'] as Map : null;
    final rawAvatar = json['user_avatar'] as String? ?? profile?['avatar_url'] as String?;

    // Resolusi border (prioritas: kolom database -> tag border di avatar)
    String? border = json['user_active_border'] as String? ??
        json['active_border_id'] as String? ??
        profile?['active_border_id'] as String?;
    String? avatar = rawAvatar;

    if (rawAvatar != null && rawAvatar.contains('border')) {
      final match = RegExp(r'[#|]border[:=](\w+)').firstMatch(rawAvatar);
      if (match != null) {
        border ??= match.group(1);
        final clean = rawAvatar.replaceAll(match.group(0)!, '').trim();
        avatar = clean.isNotEmpty ? clean : null;
      }
    }

    return CourseFeedback(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String? ?? profile?['display_name'] as String? ?? 'Mahasiswa',
      userAvatar: avatar,
      userActiveBorder: border,
      kesan: json['kesan'] as String? ?? json['comment'] as String? ?? json['message'] as String? ?? '',
      saran: json['saran'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  /// Encode tag border ke dalam string avatar agar persist secara publik
  static String? encodeAvatar(String? avatar, String? borderId) {
    if (borderId == null || borderId.isEmpty) {
      if (avatar == null) return null;
      final clean = avatar.replaceAll(RegExp(r'[#|]border[:=]\w+'), '').trim();
      return clean.isNotEmpty ? clean : null;
    }
    final clean = (avatar != null && avatar.isNotEmpty)
        ? avatar.replaceAll(RegExp(r'[#|]border[:=]\w+'), '').trim()
        : '';
    return clean.isNotEmpty ? '$clean#border=$borderId' : '#border=$borderId';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_avatar': encodeAvatar(userAvatar, userActiveBorder),
        'user_active_border': userActiveBorder,
        'kesan': kesan,
        'saran': saran,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
      };
}

