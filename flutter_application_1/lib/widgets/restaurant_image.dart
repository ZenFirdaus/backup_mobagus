import 'package:flutter/material.dart';

import '../core/constants/dish_types.dart';
import '../services/dish_image_service.dart';

/// Urutan pilihan gambar:
///  1. foto asli tempat (image_url) bila ada dan berhasil dimuat
///  2. foto Unsplash sesuai jenis sajian (dish_type), dengan atribusi fotografer
///  3. ikon sesuai jenis sajian / kategori (tanpa file gambar sama sekali)
/// Selain foto asli, gambar diberi label supaya tidak dikira foto tempat aslinya.
class RestaurantImage extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final String? dishType;

  const RestaurantImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.dishType,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) return _illustration();

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _illustration(),
    );
  }

  Widget _illustration() {
    return ValueListenableBuilder<Map<String, DishImage>>(
      valueListenable: DishImageService.instance.images,
      builder: (context, images, _) {
        final dishImage = images[dishType];
        if (dishImage == null) return _iconBox();

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              dishImage.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _iconBox(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _iconBox(),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              right: 6,
              child: _Badge(
                text: 'Foto ilustrasi · ${dishImage.photographer} / Unsplash',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _iconBox() {
    final emoji =
        dishTypes[dishType]?.emoji ?? categoryEmoji[category] ?? '🍽️';
    return ColoredBox(
      color: const Color(0xFFEFE3CC),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
