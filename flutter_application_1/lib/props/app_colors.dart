import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color green = Color(0xFF7D9C65); // #7D9C65
  static const Color red = Color(0xFFB93636); // #B93636
  static const Color orange = Color(0xFFFF9C4C); // #FF9C4C
  static const Color yellow = Color(0xFFFFF2A0); // #FFF2A0

  static const Color greenDark = Color(0xFF4F6B3C);
  static const Color textDark = Color(0xFF2B2118);
  static const Color textMuted = Color(0xFF7A6F63);
  static const Color line = Color(0xFFEADFC4); // garis/border hangat
  static const Color surface = Colors.white;

  static final Color background = Color.lerp(yellow, Colors.white, 0.55)!;

  static final LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [yellow, background, Colors.white],
    stops: const [0.0, 0.45, 1.0],
  );

  static Color tint(Color c, double opacity) =>
      c.withAlpha((opacity * 255).round().clamp(0, 255));
}
