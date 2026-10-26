import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_recommendation_result.dart';
import '../models/restaurant.dart';
import '../models/user_ai_profile.dart';
import 'location_service.dart';

/// Service mesin kecerdasan buatan (AI) yang memproses data diri,
/// gaya hidup, daya beli, dan selera kuliner pengguna untuk menghasilkan
/// rekomendasi makanan yang personal dan terpersonalisasi secara akurat.
class AiRecommendationService {
  AiRecommendationService._();
  static final AiRecommendationService instance = AiRecommendationService._();

  static const _kProfileKey = 'foodie_user_ai_profile';

  final ValueNotifier<UserAiProfile?> profileNotifier =
      ValueNotifier<UserAiProfile?>(null);

  bool _initialized = false;

  /// Inisialisasi dan memuat profil AI yang tersimpan
  Future<UserAiProfile?> init() async {
    if (_initialized && profileNotifier.value != null) {
      return profileNotifier.value;
    }
    final profile = await getProfile();
    profileNotifier.value = profile;
    _initialized = true;
    return profile;
  }

  /// Membaca profil AI pengguna dari SharedPreferences
  Future<UserAiProfile?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileKey);
      if (raw == null || raw.isEmpty) return null;
      final profile = UserAiProfile.fromJson(raw);
      profileNotifier.value = profile;
      return profile;
    } catch (e) {
      debugPrint('Error reading AI profile: $e');
      return null;
    }
  }

  /// Menyimpan profil AI pengguna ke SharedPreferences dan memperbarui notifier
  Future<void> saveProfile(UserAiProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, profile.toJson());
      // Notifikasi secara asynchronous via microtask agar transisi route pop berjalan mulus
      Future.microtask(() {
        profileNotifier.value = profile;
      });
    } catch (e) {
      debugPrint('Error saving AI profile: $e');
    }
  }

  /// Menghapus profil AI (reset)
  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileKey);
      profileNotifier.value = null;
    } catch (e) {
      debugPrint('Error clearing AI profile: $e');
    }
  }

  /// Memproses seluruh restoran dengan Multi-Factor AI Matching Algorithm
  /// berdasarkan persona dan preferensi pengguna.
  List<AiRecommendationResult> rankRestaurants({
    required List<Restaurant> restaurants,
    required UserAiProfile profile,
    double? userLat,
    double? userLng,
  }) {
    if (restaurants.isEmpty) return [];

    final results = <AiRecommendationResult>[];

    for (final r in restaurants) {
      // 1. Pilar Ekonomi & Budget (Bobot 25%)
      final budgetScore = _calcBudgetScore(r, profile);

      // 2. Pilar Selera Rasa (Bobot 25%)
      final tasteScore = _calcTasteScore(r, profile);

      // 3. Pilar Gaya Hidup, Pekerjaan & Hunian (Bobot 20%)
      final lifestyleScore = _calcLifestyleScore(r, profile);

      // 4. Pilar Jarak & Lokasi (Bobot 20%)
      final distanceInfo = _calcProximityScore(r, profile, userLat, userLng);
      final distanceScore = distanceInfo.score;
      final distanceKm = distanceInfo.distanceKm;

      // 5. Pilar Kualitas / Rating (Bobot 10%)
      final ratingScore = ((r.rating / 5.0) * 100).clamp(50.0, 100.0);

      // Total Skor Terbobot AI
      final totalScore = (budgetScore * 0.25) +
          (tasteScore * 0.25) +
          (lifestyleScore * 0.20) +
          (distanceScore * 0.20) +
          (ratingScore * 0.10);

      // Normalisasi nilai akhir (65.0% - 99.2%)
      final finalMatchScore = (totalScore.clamp(65.0, 99.2) * 10).round() / 10;

      // Buat label dan tag alasan AI yang kontekstual
      final tags = _generateReasonTags(
        r,
        profile,
        budgetScore,
        tasteScore,
        lifestyleScore,
        distanceKm,
      );

      final explanation = _generateNaturalExplanation(
        r,
        profile,
        finalMatchScore,
        distanceKm,
      );

      results.add(AiRecommendationResult(
        restaurant: r,
        matchScore: finalMatchScore,
        matchBadge: '${finalMatchScore.toStringAsFixed(0)}% Cocok',
        tags: tags,
        explanation: explanation,
        distanceKm: distanceKm,
        breakdown: {
          'Budget & Pendapatan': budgetScore,
          'Selera Rasa': tasteScore,
          'Gaya Hidup & Hunian': lifestyleScore,
          'Jarak & Lokasi': distanceScore,
          'Kualitas Kuliner': ratingScore,
        },
      ));
    }

    // Urutkan dari skor kecocokan tertinggi
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return results;
  }

  // ---------------------------------------------------------------------------
  // Algoritma Internal Perhitungan Skor
  // ---------------------------------------------------------------------------

  double _calcBudgetScore(Restaurant r, UserAiProfile p) {
    final budgetStr = (p.mealBudget ?? '').toLowerCase();
    final incomeStr = (p.monthlyIncome ?? '').toLowerCase();
    final isStudent = (p.occupation ?? '').toLowerCase().contains('mahasiswa') ||
        (p.occupation ?? '').toLowerCase().contains('pelajar');
    final isKos = (p.housingType ?? '').toLowerCase().contains('kos');

    // Profil Hemat / Mahasiswa / Anak Kos / Pendapatan Rendah
    if (budgetStr.contains('hemat') ||
        incomeStr.contains('< rp 2') ||
        (isStudent && isKos)) {
      if (r.priceMin <= 15000) return 98.0;
      if (r.priceMin <= 25000) return 92.0;
      if (r.priceMin <= 40000) return 75.0;
      return 55.0;
    }

    // Profil Menengah / Karyawan Standar
    if (budgetStr.contains('menengah') || incomeStr.contains('2 - 5')) {
      if (r.priceMin >= 15000 && r.priceMin <= 45000) return 96.0;
      if (r.priceMin < 15000) return 88.0;
      if (r.priceMin <= 70000) return 80.0;
      return 60.0;
    }

    // Profil Santai / Kafe / Pendapatan Mapan
    if (budgetStr.contains('santai') || incomeStr.contains('5 - 10')) {
      if (r.priceMin >= 25000 && r.priceMax >= 50000) return 97.0;
      if (r.priceMin < 25000) return 82.0;
      return 90.0;
    }

    // Profil Eksklusif / High Income
    if (budgetStr.contains('eksklusif') || incomeStr.contains('> rp 10')) {
      if (r.priceMax >= 75000) return 99.0;
      if (r.priceMin >= 40000) return 90.0;
      return 75.0;
    }

    // Default umum
    if (r.priceMin <= 30000) return 90.0;
    return 80.0;
  }

  double _calcTasteScore(Restaurant r, UserAiProfile p) {
    if (p.favoriteTastes.isEmpty) return 82.0;

    final text = '${r.name} ${r.category} ${r.description ?? ''}'.toLowerCase();
    int matchCount = 0;

    const tasteKeywords = {
      'pedas': ['pedas', 'pedes', 'sambal', 'rawit', 'geprek', 'lele', 'mercon', 'seblak'],
      'manis': ['manis', 'gudeg', 'areh', 'bakpia', 'roti', 'kue', 'dessert', 'es '],
      'gurih': ['gurih', 'asin', 'soto', 'bakso', 'bakmi', 'sate', 'ayam', 'bebek', 'kuah'],
      'asin': ['gurih', 'asin', 'soto', 'bakso', 'bakmi', 'sate', 'ayam', 'bebek', 'kuah'],
      'rempah': ['rempah', 'tradisional', 'khas', 'pawon', 'klampok', 'bakar', 'gule', 'tongseng'],
      'asam': ['asam', 'segar', 'jus', 'rujak', 'es'],
    };

    for (final taste in p.favoriteTastes) {
      final t = taste.toLowerCase();
      final hasMatch = tasteKeywords.entries.any((entry) =>
          t.contains(entry.key) && entry.value.any((kw) => text.contains(kw)));
      if (hasMatch) matchCount++;
    }

    if (matchCount >= 2) return 98.0;
    if (matchCount == 1) return 90.0;
    return 72.0; // Netral
  }

  double _calcLifestyleScore(Restaurant r, UserAiProfile p) {
    final text = '${r.name} ${r.category} ${r.description ?? ''}'.toLowerCase();
    final occ = (p.occupation ?? '').toLowerCase();
    final house = (p.housingType ?? '').toLowerCase();
    final vibe = (p.preferredVibe ?? '').toLowerCase();

    double score = 80.0;

    // Anak Kos & Mahasiswa
    if (house.contains('kos') || occ.contains('mahasiswa')) {
      const kosKeywords = ['soto', 'warung', 'gudeg', 'lele', 'kafe', 'cafe', 'santai'];
      if (kosKeywords.any((kw) => text.contains(kw))) score += 15.0;
    }

    // Suasana WFC / Nugas
    if (vibe.contains('wfc') || vibe.contains('nugas')) {
      const wfcKeywords = ['cafe', 'kafe', 'coffee', 'kopi'];
      if (wfcKeywords.any((kw) => text.contains(kw)) || (r.website?.isNotEmpty ?? false)) {
        score += 18.0;
      }
    }

    // Suasana Warung Tradisional / Legendaris
    if (vibe.contains('tradisional') || vibe.contains('warung')) {
      const tradKeywords = ['tradisional', 'legendaris', 'mbah', 'pawon', 'wijilan'];
      if (tradKeywords.any((kw) => text.contains(kw))) score += 18.0;
    }

    // Pekerja Kantoran / Apartemen / Keluarga
    if (house.contains('apartemen') || occ.contains('karyawan') || occ.contains('pns')) {
      if (r.rating >= 4.7 || text.contains('restoran') || text.contains('kafe')) {
        score += 12.0;
      }
    }

    // Preferensi Tipe Tempat Pilihan
    if (p.preferredPlaces.isNotEmpty) {
      final cat = r.category.toLowerCase();
      for (final place in p.preferredPlaces) {
        final pl = place.toLowerCase();
        final matches = (pl.contains('cafe') && (text.contains('cafe') || text.contains('kafe') || text.contains('kopi') || cat.contains('cafe'))) ||
            ((pl.contains('warung') || pl.contains('angkringan')) && (text.contains('warung') || text.contains('angkringan') || text.contains('lesehan') || cat.contains('warung'))) ||
            (pl.contains('gudeg') && (text.contains('gudeg') || cat.contains('gudeg'))) ||
            (pl.contains('soto') && (text.contains('soto') || cat.contains('soto'))) ||
            (pl.contains('bakmi') && (text.contains('bakmi') || cat.contains('bakmi'))) ||
            ((pl.contains('rumah makan') || pl.contains('restoran')) && (cat.contains('restoran') || text.contains('resto') || text.contains('rumah makan'))) ||
            (pl.contains('fast food') && (text.contains('fast food') || text.contains('burger') || text.contains('fried chicken'))) ||
            (pl.contains('food court') && text.contains('food court'));
        if (matches) score += 15.0;
      }
    }

    return score.clamp(60.0, 100.0);
  }

  _ProximityResult _calcProximityScore(
    Restaurant r,
    UserAiProfile p,
    double? userLat,
    double? userLng,
  ) {
    double distanceKm = 0.0;
    double score = 75.0;

    // 1. Cek dari koordinat GPS aktual
    if (userLat != null && userLng != null && (userLat != 0 || userLng != 0)) {
      final meters = LocationService.instance.distanceM(
        userLat,
        userLng,
        r.lat,
        r.lng,
      );
      distanceKm = (meters / 1000.0 * 10).round() / 10;

      if (distanceKm <= 2.0) {
        score = 98.0;
      } else if (distanceKm <= 5.0) {
        score = 90.0;
      } else if (distanceKm <= 10.0) {
        score = 80.0;
      } else if (distanceKm <= 15.0) {
        score = 70.0;
      } else {
        score = 60.0;
      }
    }

    // 2. Cek kecocokan teks alamat yang dimasukkan pengguna
    final userAddr = (p.address ?? '').toLowerCase().trim();
    if (userAddr.isNotEmpty) {
      final restoAddr = '${r.address} ${r.province}'.toLowerCase();
      final words = userAddr.split(RegExp(r'[, -]+'));
      for (final w in words) {
        if (w.length >= 4 && restoAddr.contains(w)) {
          score = min(100.0, score + 12.0);
          break;
        }
      }
    }

    return _ProximityResult(score: score, distanceKm: distanceKm);
  }

  // ---------------------------------------------------------------------------
  // Pembuat Tag & Penjelasan Alami AI
  // ---------------------------------------------------------------------------

  List<String> _generateReasonTags(
    Restaurant r,
    UserAiProfile p,
    double budgetScore,
    double tasteScore,
    double lifestyleScore,
    double distanceKm,
  ) {
    final tags = <String>[];

    // Tag Tipe Tempat Favorit
    if (p.preferredPlaces.isNotEmpty) {
      for (final place in p.preferredPlaces) {
        final pl = place.toLowerCase();
        final text = '${r.name} ${r.category}'.toLowerCase();
        if ((pl.contains('cafe') && (text.contains('cafe') || text.contains('kafe') || text.contains('kopi'))) ||
            (pl.contains('gudeg') && text.contains('gudeg')) ||
            (pl.contains('soto') && text.contains('soto')) ||
            (pl.contains('bakmi') && text.contains('bakmi')) ||
            (pl.contains('warung') && text.contains('warung'))) {
          tags.add('Tipe $place Favorit');
          break;
        }
      }
    }

    // Tag Budget
    if (budgetScore >= 90) {
      if ((p.housingType ?? '').toLowerCase().contains('kos')) {
        tags.add('Sesuai Kantong Kos');
      } else {
        tags.add('Budget Pas');
      }
    }

    // Tag Rasa
    if (tasteScore >= 90 && p.favoriteTastes.isNotEmpty) {
      tags.add('Favorit ${p.favoriteTastes.first}');
    }

    // Tag Jarak
    if (distanceKm > 0 && distanceKm <= 3.5) {
      tags.add('${distanceKm.toStringAsFixed(1)} km dari Lokasimu');
    }

    // Tag Gaya Hidup
    if (lifestyleScore >= 90) {
      if ((p.preferredVibe ?? '').toLowerCase().contains('nugas')) {
        tags.add('Nyaman Buat Nugas');
      } else if ((p.preferredVibe ?? '').toLowerCase().contains('tradisional')) {
        tags.add('Rasa Otentik');
      } else {
        tags.add('Sesuai Aktivitasmu');
      }
    }

    if (tags.isEmpty) {
      tags.add('Rekomendasi Pilihan');
    }

    return tags.take(3).toList();
  }

  String _generateNaturalExplanation(
    Restaurant r,
    UserAiProfile p,
    double matchScore,
    double distanceKm,
  ) {
    final parts = <String>[];

    // Alasan Profesi & Hunian
    final occ = p.occupation ?? 'pengguna';
    final house = p.housingType ?? 'tempat tinggalmu';
    parts.add('Direkomendasikan khusus untuk profil $occ ($house)');

    // Alasan Rasa
    if (p.favoriteTastes.isNotEmpty) {
      parts.add('selera rasa ${p.favoriteTastes.join(" & ")} yang kamu sukai');
    }

    // Alasan Harga
    final priceStr = r.priceRange;
    parts.add('kisaran harga ramah ($priceStr)');

    // Alasan Jarak
    if (distanceKm > 0) {
      parts.add('berjarak hanya ${distanceKm.toStringAsFixed(1)} km');
    }

    return 'AI memilihkan ${r.name} (${matchScore.toStringAsFixed(0)}% Cocok) karena ${parts.join(", ")}. Sangat pas untuk menu santap Anda berikutnya!';
  }
}

class _ProximityResult {
  final double score;
  final double distanceKm;
  const _ProximityResult({required this.score, required this.distanceKm});
}
