import 'dart:convert';

/// Model untuk data diri dan preferensi kuliner pengguna yang digunakan
/// oleh mesin rekomendasi AI FOODIE.
class UserAiProfile {
  final String? gender; // 'Laki-laki' | 'Perempuan'
  final int? age;
  final String? occupation; // 'Mahasiswa / Pelajar', 'Karyawan Swasta', 'PNS / BUMN', 'Wirausaha', 'Freelancer', dll.
  final String? monthlyIncome; // '< Rp 2.000.000', 'Rp 2 - 5 Juta', 'Rp 5 - 10 Juta', '> Rp 10 Juta'
  final String? housingType; // 'Kos', 'Kontrakan', 'Rumah Sendiri', 'Rumah Orang Tua', 'Apartemen'
  final String? address; // e.g. "Pogung, Sleman" atau "Seturan"
  final List<String> favoriteTastes; // ['Pedas', 'Manis', 'Gurih / Asin', 'Asam Segar', 'Rempah']
  final String? mealBudget; // 'Hemat (< Rp 20k)', 'Menengah (Rp 20k - 45k)', 'Santai (Rp 45k - 80k)', 'Eksklusif (> Rp 80k)'
  final String? preferredVibe; // 'WFC / Nugas', 'Nongkrong Santai', 'Cepat Saji', 'Warung Tradisional', 'Keluarga'
  final String? dietaryPreference; // 'Halal', 'Bebas Santan', 'Vegetarian', 'Semua Makanan'

  const UserAiProfile({
    this.gender,
    this.age,
    this.occupation,
    this.monthlyIncome,
    this.housingType,
    this.address,
    this.favoriteTastes = const [],
    this.mealBudget,
    this.preferredVibe,
    this.dietaryPreference = 'Semua Makanan',
  });

  /// Cek apakah profil sudah cukup lengkap untuk menghasilkan rekomendasi AI
  bool get isCompleted {
    return (gender != null && gender!.isNotEmpty) &&
        (age != null && age! > 0) &&
        (occupation != null && occupation!.isNotEmpty) &&
        (monthlyIncome != null && monthlyIncome!.isNotEmpty) &&
        (housingType != null && housingType!.isNotEmpty) &&
        favoriteTastes.isNotEmpty &&
        (mealBudget != null && mealBudget!.isNotEmpty);
  }

  /// Menghitung persentase kelengkapan profil (0 - 100%)
  int get completionPercentage {
    int total = 8;
    int filled = 0;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (age != null && age! > 0) filled++;
    if (occupation != null && occupation!.isNotEmpty) filled++;
    if (monthlyIncome != null && monthlyIncome!.isNotEmpty) filled++;
    if (housingType != null && housingType!.isNotEmpty) filled++;
    if (address != null && address!.trim().isNotEmpty) filled++;
    if (favoriteTastes.isNotEmpty) filled++;
    if (mealBudget != null && mealBudget!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  /// Ringkasan persona singkat untuk badge UI (misal: "Mahasiswa • Kos • Suka Pedas")
  String get personaSummary {
    final parts = <String>[];
    if (occupation != null && occupation!.isNotEmpty) {
      parts.add(occupation!.split(' ').first);
    }
    if (housingType != null && housingType!.isNotEmpty) {
      parts.add(housingType!);
    }
    if (favoriteTastes.isNotEmpty) {
      parts.add('Suka ${favoriteTastes.first}');
    }
    if (mealBudget != null && mealBudget!.isNotEmpty) {
      parts.add(mealBudget!.split(' ').first);
    }
    return parts.isEmpty ? 'Belum Diatur' : parts.join(' • ');
  }

  UserAiProfile copyWith({
    String? gender,
    int? age,
    String? occupation,
    String? monthlyIncome,
    String? housingType,
    String? address,
    List<String>? favoriteTastes,
    String? mealBudget,
    String? preferredVibe,
    String? dietaryPreference,
  }) {
    return UserAiProfile(
      gender: gender ?? this.gender,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      housingType: housingType ?? this.housingType,
      address: address ?? this.address,
      favoriteTastes: favoriteTastes ?? this.favoriteTastes,
      mealBudget: mealBudget ?? this.mealBudget,
      preferredVibe: preferredVibe ?? this.preferredVibe,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'age': age,
      'occupation': occupation,
      'monthly_income': monthlyIncome,
      'housing_type': housingType,
      'address': address,
      'favorite_tastes': favoriteTastes,
      'meal_budget': mealBudget,
      'preferred_vibe': preferredVibe,
      'dietary_preference': dietaryPreference,
    };
  }

  factory UserAiProfile.fromMap(Map<String, dynamic> map) {
    return UserAiProfile(
      gender: map['gender'] as String?,
      age: (map['age'] as num?)?.toInt(),
      occupation: map['occupation'] as String?,
      monthlyIncome: map['monthly_income'] as String?,
      housingType: map['housing_type'] as String?,
      address: map['address'] as String?,
      favoriteTastes: (map['favorite_tastes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mealBudget: map['meal_budget'] as String?,
      preferredVibe: map['preferred_vibe'] as String?,
      dietaryPreference: map['dietary_preference'] as String? ?? 'Semua Makanan',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserAiProfile.fromJson(String source) =>
      UserAiProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
