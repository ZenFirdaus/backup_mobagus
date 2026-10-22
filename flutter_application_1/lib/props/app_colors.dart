import 'package:flutter/material.dart';

/// Palet warna resmi FOODIE (PRO EDITION)
/// Mengacu pada PRD & Desain Culinary Editorial Futurism:
/// - Roasted Charcoal: #252D30 (Warna utama / primary)
/// - Slate Blue: #607783 (Warna pendukung / secondary)
/// - Saffron: #F5BD50 (Aksen utama / CTA / Star)
/// - Paprika: #EF8235 (Aksen eksplorasi rasa / warm badge)
/// - Tomato: #A92F27 (Penekanan tertentu / alert / status tutup)
/// - Cream: #FFF7E8 (Warna netral seperlunya)
class AppColors {
  AppColors._();

  // ─── PALET WARNA RESMI PRD ───
  static const Color charcoal = Color(0xFF252D30); // Roasted Charcoal #252D30
  static const Color slateBlue = Color(0xFF607783); // Slate Blue #607783
  static const Color saffron = Color(0xFFF5BD50); // Saffron #F5BD50
  static const Color paprika = Color(0xFFEF8235); // Paprika #EF8235
  static const Color tomato = Color(0xFFA92F27); // Tomato #A92F27
  static const Color cream = Color(0xFFFFF7E8); // Cream #FFF7E8

  // ─── SEMANTIC ALIASES & COMPATIBILITY ───
  static const Color primary = charcoal;
  static const Color secondary = slateBlue;
  static const Color orange = paprika; // #EF8235
  static const Color yellow = saffron; // #F5BD50
  static const Color red = tomato; // #A92F27
  static const Color green = Color(0xFF3B6E47); // Heritage forest green (verified checkmark)
  static const Color greenDark = charcoal; // #252D30 (Roasted Charcoal)

  static const Color textDark = charcoal; // #252D30 (Kontras tinggi, tegas)
  static const Color textMuted = slateBlue; // #607783 (Slate Blue)
  static const Color line = Color(0xFFE2DDD5); // Border netral bersih
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = cream; // #FFF7E8 (Cream netral)

  // Canvas latar belakang bersih, solid, kontras tinggi
  static const Color background = Color(0xFFFAF8F5);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCFBF8), Color(0xFFFAF8F5), Color(0xFFF6F4ED)],
    stops: [0.0, 0.5, 1.0],
  );

  static Color tint(Color c, double opacity) =>
      c.withValues(alpha: opacity.clamp(0.0, 1.0));
}
