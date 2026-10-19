import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';

/// Komponen gambar kuliner dengan dukungan URL jaringan, aset lokal,
/// loading state halus, dan fallback visual yang elegan.
class FoodImage extends StatelessWidget {
  final String? asset;
  final String? imageUrl;
  final IconData icon;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final List<Color> colors;
  final BoxFit fit;

  const FoodImage({
    super.key,
    this.asset,
    this.imageUrl,
    this.icon = Icons.restaurant_rounded,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.colors = const [AppColors.paprika, AppColors.charcoal],
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.charcoal,
      child: Center(
        child: Icon(icon, color: AppColors.saffron, size: 28),
      ),
    );

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.cream,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.paprika,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else if (asset != null && asset!.trim().isNotEmpty) {
      imageWidget = Image.asset(
        asset!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      imageWidget = fallback;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      ),
    );
  }
}

/// Chip kecil (pill) dengan tampilan clean dan modern.
class InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;

  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.surfaceSubtle,
    this.foreground = AppColors.textDark,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? AppColors.line.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header bagian (Section Title + Action)
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppText.display(17)),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
