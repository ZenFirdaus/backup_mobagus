import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nama font. Didaftarkan di pubspec.yaml (lihat panduan font).
/// Kalau file font belum dipasang, Flutter otomatis memakai font bawaan,
/// jadi aplikasi tetap jalan tanpa error.
class AppFonts {
  AppFonts._();

  static const String body = 'Manrope'; // teks umum
  static const String display = 'PlayfairDisplay'; // judul / aksen elegan
}

class AppText {
  AppText._();

  /// Gaya judul (serif elegan Playfair Display).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    bool italic = false,
    Color color = AppColors.textDark,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Gaya teks sans-serif modern (Manrope).
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textDark,
    double? height = 1.45,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Label kecil / pill badge.
  static TextStyle caption({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textMuted,
    double letterSpacing = 0.2,
  }) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
