class Achievement {
  final String id;
  final String userId;
  final String badgeCode;
  final String badgeTier;
  final int pointsAwarded;
  final DateTime unlockedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.badgeCode,
    required this.badgeTier,
    required this.pointsAwarded,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeCode: json['badge_code'] as String,
      badgeTier: json['badge_tier'] as String? ?? 'Bronze',
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }
}

class BadgeInfo {
  final String code;
  final String name;
  final String description;
  final int requiredVisits;
  final int pointsReward;

  const BadgeInfo({
    required this.code,
    required this.name,
    required this.description,
    required this.requiredVisits,
    required this.pointsReward,
  });
}

const kBadges = <BadgeInfo>[
  BadgeInfo(
    code: 'gudeg_explorer',
    name: 'Penjelajah Gudeg',
    description: 'Kunjungi 5 warung gudeg terverifikasi di sentra Wijilan',
    requiredVisits: 5,
    pointsReward: 350,
  ),
  BadgeInfo(
    code: 'mangut_knight',
    name: 'Ksatria Mangut Lele',
    description: 'Kunjungi warung mangut lele di Sewon & Bantul',
    requiredVisits: 3,
    pointsReward: 200,
  ),
  BadgeInfo(
    code: 'bakmi_seeker',
    name: 'Pencari Bakmi Jawa',
    description: 'Kunjungi warung bakmi jawa legendaris',
    requiredVisits: 3,
    pointsReward: 200,
  ),
  BadgeInfo(
    code: 'kopi_lover',
    name: 'Pecinta Kopi Joss',
    description: 'Kunjungi 3 angkringan heritage kopi joss',
    requiredVisits: 3,
    pointsReward: 150,
  ),
  BadgeInfo(
    code: 'wedang_curator',
    name: 'Kurator Wedang Ronde',
    description: 'Kunjungi 3 warung wedang ronde tradisional',
    requiredVisits: 3,
    pointsReward: 250,
  ),
  BadgeInfo(
    code: 'soto_master',
    name: 'Maestro Soto',
    description: 'Kunjungi 5 warung soto terverifikasi',
    requiredVisits: 5,
    pointsReward: 300,
  ),
];
