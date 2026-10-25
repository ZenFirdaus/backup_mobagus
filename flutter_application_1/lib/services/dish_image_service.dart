import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Satu foto Unsplash untuk satu jenis sajian (hanya alamat, bukan file).
class DishImage {
  final String url;
  final String photographer;
  final String photographerUrl;
  final String photoUrl;

  const DishImage({
    required this.url,
    required this.photographer,
    required this.photographerUrl,
    required this.photoUrl,
  });
}

/// Memuat tabel dish_images sekali (setelah login), lalu dipakai semua kartu.
class DishImageService {
  DishImageService._();
  static final DishImageService instance = DishImageService._();

  /// Widget mendengarkan ini supaya otomatis menampilkan foto setelah data tiba.
  final ValueNotifier<Map<String, DishImage>> images =
      ValueNotifier<Map<String, DishImage>>({});

  Future<void> load() async {
    try {
      final rows = await Supabase.instance.client.from('dish_images').select();
      final result = <String, DishImage>{};
      for (final row in rows) {
        final dishType = row['dish_type'] as String?;
        final url = row['image_url'] as String?;
        if (dishType == null || url == null) continue;
        result[dishType] = DishImage(
          url: url,
          photographer: (row['photographer'] as String?) ?? 'Unsplash',
          photographerUrl: (row['photographer_url'] as String?) ?? '',
          photoUrl: (row['photo_url'] as String?) ?? '',
        );
      }
      images.value = result;
    } catch (_) {
      // Gagal (offline, dll): biarkan kosong, tampilan jatuh ke ikon.
    }
  }
}
