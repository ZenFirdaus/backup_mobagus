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

  int get curatorLevel {
    if (points >= 2500) return 5;
    if (points >= 1500) return 4;
    if (points >= 800) return 3;
    if (points >= 300) return 2;
    return 1;
  }

  String get levelTitle {
    switch (curatorLevel) {
      case 1:
        return 'Pemula Rasa';
      case 2:
        return 'Penjelajah Kuliner';
      case 3:
        return 'Kurator Kuliner';
      case 4:
        return 'Penjelajah Kuliner Sejati';
      case 5:
        return 'Kurator Utama';
      default:
        return 'Pemula Rasa';
    }
  }

  /// Target poin untuk mencapai tingkatan level berikutnya
  int get nextLevelPoints {
    if (curatorLevel == 1) return 300;
    if (curatorLevel == 2) return 800;
    if (curatorLevel == 3) return 1500;
    if (curatorLevel == 4) return 2500;
    return 2500; // Level 5 (Maksimal)
  }

  /// Batas minimal poin tingkatan level saat ini
  int get currentLevelBasePoints {
    if (curatorLevel == 1) return 0;
    if (curatorLevel == 2) return 300;
    if (curatorLevel == 3) return 800;
    if (curatorLevel == 4) return 1500;
    return 2500;
  }

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
