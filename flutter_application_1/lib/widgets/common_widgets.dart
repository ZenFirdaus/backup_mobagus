import 'dart:convert';
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

/// Avatar visual yang mendukung URL internet, data base64, maupun inisial teks.
class AvatarImage extends StatelessWidget {
  final String? url;
  final double size;
  final String fallbackText;
  final Color backgroundColor;

  const AvatarImage({
    super.key,
    required this.url,
    required this.size,
    this.fallbackText = 'F',
    this.backgroundColor = AppColors.orange,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim()[0].toUpperCase()
        : 'F';

    final fallbackWidget = Container(
      width: size,
      height: size,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    if (url == null || url!.trim().isEmpty) {
      return fallbackWidget;
    }

    final trimmed = url!.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final comma = trimmed.indexOf(',');
        if (comma != -1) {
          final b64 = trimmed.substring(comma + 1);
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallbackWidget,
          );
        }
      } catch (_) {
        return fallbackWidget;
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallbackWidget,
      );
    }

    return fallbackWidget;
  }
}
