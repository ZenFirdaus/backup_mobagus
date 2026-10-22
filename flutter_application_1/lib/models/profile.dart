class Profile {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final int points;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.points,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'].toString(),
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
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
}
