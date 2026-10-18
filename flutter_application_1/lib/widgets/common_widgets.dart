import 'package:flutter/material.dart';

import '../props/app_colors.dart';

/// Placeholder gambar makanan. Ganti dengan Image.asset('assets/images/xxx.jpg')
/// kalau sudah punya fotonya (daftarkan di pubspec.yaml bagian assets).
class FoodImage extends StatelessWidget {
  final String? asset;
  final IconData icon;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final List<Color> colors;

  const FoodImage({
    super.key,
    this.asset,
    this.icon = Icons.restaurant,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.colors = const [AppColors.orange, AppColors.red],
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(icon, color: AppColors.tint(Colors.white, 0.85), size: 32),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: asset == null
            ? fallback
            : Image.asset(
                asset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

/// Chip kecil (pill) dengan ikon opsional.
class InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.yellow,
    this.foreground = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.red),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
