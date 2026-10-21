import 'restaurant.dart';

/// Hasil analisis dan rekomendasi tempat makan oleh AI FOODIE
/// yang disesuaikan secara personal dengan persona pengguna.
class AiRecommendationResult {
  final Restaurant restaurant;
  final double matchScore; // 0.0 - 100.0
  final String matchBadge; // e.g. "✨ 98% Match"
  final List<String> tags; // e.g. ["Sesuai Kantong Kos", "Pencinta Pedas", "Dekat Lokasimu"]
  final String explanation; // Kalimat penjelasan cerdas dari AI
  final Map<String, double> breakdown; // Skor per pilar: 'budget', 'taste', 'lifestyle', 'location'
  final double distanceKm; // Jarak aktual dari lokasi saat ini / alamat

  const AiRecommendationResult({
    required this.restaurant,
    required this.matchScore,
    required this.matchBadge,
    required this.tags,
    required this.explanation,
    required this.breakdown,
    this.distanceKm = 0.0,
  });

  /// Label warna untuk persentase kecocokan
  String get scoreTier {
    if (matchScore >= 90) return 'Sangat Cocok';
    if (matchScore >= 80) return 'Direkomendasikan';
    if (matchScore >= 70) return 'Pilihan Menarik';
    return 'Cukup Cocok';
  }
}
