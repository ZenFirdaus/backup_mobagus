class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? activeBorderId;
  final int points;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.activeBorderId,
    required this.points,
    required this.createdAt,
  });

  Profile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? activeBorderId,
    int? points,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activeBorderId: activeBorderId ?? this.activeBorderId,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'].toString(),
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      activeBorderId: json['active_border_id'] as String?,
      points: json['points'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  int get curatorLevel => switch (points) {
        >= 2500 => 5,
        >= 1500 => 4,
        >= 800 => 3,
        >= 300 => 2,
        _ => 1,
      };

  String get levelTitle => switch (curatorLevel) {
        2 => 'Penjelajah Kuliner',
        3 => 'Kurator Kuliner',
        4 => 'Penjelajah Kuliner Sejati',
        5 => 'Kurator Utama',
        _ => 'Pemula Rasa',
      };

  int get nextLevelPoints => switch (curatorLevel) {
        1 => 300,
        2 => 800,
        3 => 1500,
        _ => 2500,
      };

  int get currentLevelBasePoints => switch (curatorLevel) {
        2 => 300,
        3 => 800,
        4 => 1500,
        >= 5 => 2500,
        _ => 0,
      };

  /// Sisa poin yang dibutuhkan untuk naik level
  int get pointsToNextLevel {
    if (curatorLevel >= 5) return 0;
    return (nextLevelPoints - points).clamp(0, nextLevelPoints);
  }

  /// Persentase progres dari level saat ini menuju level berikutnya (0.0 – 1.0)
  double get levelProgress {
    if (curatorLevel >= 5) return 1.0;
    final range = nextLevelPoints - currentLevelBasePoints;
    if (range <= 0) return 1.0;
    final current = points - currentLevelBasePoints;
    return (current / range).clamp(0.0, 1.0);
  }
}
