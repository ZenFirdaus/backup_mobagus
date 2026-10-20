import 'package:flutter/material.dart';

import '../props/app_colors.dart';

/// Path konstanta logo FOODIE dari assets.
class FoodieLogo {
  FoodieLogo._();

  /// Icon mark saja (2 lingkaran + garis), warna oranye — untuk background terang
  static const String markOrange = 'assets/logo/logo orange.png';

  /// Icon mark saja, warna putih/krem — untuk background gelap/oranye
  static const String markWhite = 'assets/logo/logo putih.png';

  /// Wordmark "foodie" + sendok, warna oranye — untuk background terang
  static const String textOrange = 'assets/logo/logo teks orange.png';

  /// Wordmark "foodie" + sendok, warna putih/krem — untuk background gelap/oranye
  static const String textWhite = 'assets/logo/logo teks putih.png';
}

/// Widget logo FOODIE yang dapat digunakan ulang di seluruh aplikasi.
///
/// [variant] menentukan varian logo:
/// - [FoodieLogoVariant.markOrange] → icon mark oranye (light bg)
/// - [FoodieLogoVariant.markWhite]  → icon mark putih (dark/orange bg)
/// - [FoodieLogoVariant.textOrange] → wordmark oranye (light bg)
/// - [FoodieLogoVariant.textWhite]  → wordmark putih (dark/orange bg)
enum FoodieLogoVariant {
  markOrange,
  markWhite,
  textOrange,
  textWhite,
}

class FoodieLogoWidget extends StatelessWidget {
  final FoodieLogoVariant variant;
  final double? width;
  final double? height;

  const FoodieLogoWidget({
    super.key,
    this.variant = FoodieLogoVariant.textOrange,
    this.width,
    this.height,
  });

  String get _assetPath {
    switch (variant) {
      case FoodieLogoVariant.markOrange:
        return FoodieLogo.markOrange;
      case FoodieLogoVariant.markWhite:
        return FoodieLogo.markWhite;
      case FoodieLogoVariant.textOrange:
        return FoodieLogo.textOrange;
      case FoodieLogoVariant.textWhite:
        return FoodieLogo.textWhite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

/// Logo kecil untuk AppBar / header row (icon mark + badge DIY).
class FoodieHeaderLogo extends StatelessWidget {
  /// Jika [onDark] true, gunakan mark putih (untuk bg gelap/oranye).
  final bool onDark;

  const FoodieHeaderLogo({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          onDark ? FoodieLogo.markWhite : FoodieLogo.markOrange,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        //   decoration: BoxDecoration(
        //     color: onDark
        //         ? Colors.white.withValues(alpha: 0.2)
        //         : AppColors.paprika,
        //     borderRadius: BorderRadius.circular(6),
        //   ),
          
        // ),
      ],
    );
  }
}
