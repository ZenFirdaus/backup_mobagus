import 'package:flutter/material.dart';

enum CaseDifficulty {
  pemula('Pemula', Color(0xFF2E7D32)),
  menengah('Menengah', Color(0xFFE65100)),
  sulit('Sulit', Color(0xFFC62828)),
  master('Tingkat Master', Color(0xFF6A1B9A));

  final String label;
  final Color color;
  const CaseDifficulty(this.label, this.color);
}

class CaseClue {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const CaseClue({
    required this.id,
    required this.title,
    required this.description,
    this.icon = Icons.search_rounded,
  });
}

class SceneChoice {
  final String text;
  final String actionDetail;
  final String feedback;
  final bool isCorrect;
  final bool losesLife;
  final int bossDamage; // Damage ke HP boss jika saat boss fight
  final CaseClue? foundClue;
  final String? nextSceneId;

  const SceneChoice({
    required this.text,
    required this.actionDetail,
    required this.feedback,
    this.isCorrect = true,
    this.losesLife = false,
    this.bossDamage = 0,
    this.foundClue,
    this.nextSceneId,
  });
}

class BossConfrontation {
  final String name;
  final String role;
  final String avatar;
  final String quote;
  final int maxHp;
  final List<String> weakPoints;

  const BossConfrontation({
    required this.name,
    required this.role,
    required this.avatar,
    required this.quote,
    this.maxHp = 100,
    required this.weakPoints,
  });
}

class CaseScene {
  final String id;
  final String title;
  final String location;
  final String narrative;
  final String speakerName;
  final String speakerRole;
  final String speakerAvatar;
  final bool isBossFight;
  final BossConfrontation? boss;
  final List<SceneChoice> choices;

  const CaseScene({
    required this.id,
    required this.title,
    required this.location,
    required this.narrative,
    required this.speakerName,
    required this.speakerRole,
    required this.speakerAvatar,
    this.isBossFight = false,
    this.boss,
    required this.choices,
  });
}

class CaseEnding {
  final String title;
  final String narrative;
  final String epilogue;
  final String badgeName;
  final int rewardPoints;

  const CaseEnding({
    required this.title,
    required this.narrative,
    required this.epilogue,
    required this.badgeName,
    required this.rewardPoints,
  });
}

class DetectiveCase {
  final int level;
  final String id;
  final String title;
  final String subtitle;
  final String location;
  final String targetRestaurant;
  final String suspectName;
  final CaseDifficulty difficulty;
  final int baseReward;
  final String synopsis;
  final String iconEmoji;
  final List<CaseScene> scenes;
  final CaseEnding goodEnding;
  final CaseEnding badEnding;

  const DetectiveCase({
    required this.level,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.targetRestaurant,
    required this.suspectName,
    required this.difficulty,
    required this.baseReward,
    required this.synopsis,
    required this.iconEmoji,
    required this.scenes,
    required this.goodEnding,
    required this.badEnding,
  });
}
