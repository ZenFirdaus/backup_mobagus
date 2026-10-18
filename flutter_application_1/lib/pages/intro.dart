import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/common_widgets.dart';
import 'onboarding.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  static const _spotlights = [
    _Spotlight('Gudeg Kendil', 'Resep 1950', 'Wijilan', Icons.rice_bowl, [
      AppColors.orange,
      AppColors.red,
    ]),
    _Spotlight(
      'Mangut Lele',
      'Asap Kayu Bakar',
      'Bantul',
      Icons.local_fire_department,
      [AppColors.red, AppColors.orange],
    ),
    _Spotlight('Kopi Joss', 'Arang Membara', 'Tugu', Icons.coffee, [
      AppColors.green,
      AppColors.greenDark,
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: null),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _locationPill(),
                  const SizedBox(height: 10),
                  const Text(
                    '● GNSS RADIAL: 7.7956° S, 110.3695° E',
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(flex: 2),
                  _logo(),
                  const SizedBox(height: 14),
                  _editionBadge(),
                  const SizedBox(height: 14),
                  Text(
                    'FOODIE',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Menyingkap Warisan Rasa\nAutentik Nusantara',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(flex: 3),
                  _spotlightHeader(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final s in _spotlights) ...[
                        Expanded(child: _SpotlightCard(item: s)),
                        if (s != _spotlights.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  _loadingBar(),
                  const Spacer(flex: 2),
                  _startButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationPill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.tint(AppColors.orange, 0.18),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 13, color: AppColors.red),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'DIY & JAWA TENGAH',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _logo() => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.greenDark,
          border: Border.all(color: AppColors.orange, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.tint(AppColors.orange, 0.4),
              blurRadius: 26,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.restaurant, size: 38, color: AppColors.orange),
      ),
      Positioned(
        bottom: -8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 11, color: AppColors.green),
              SizedBox(width: 3),
              Text(
                '1756',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _editionBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.greenDark,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.stars, size: 12, color: AppColors.yellow),
        SizedBox(width: 6),
        Text(
          'PRO • MATARAMAN EDITION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.yellow,
          ),
        ),
      ],
    ),
  );

  Widget _spotlightHeader() => const Row(
    children: [
      Expanded(
        child: Text(
          'SOROTAN RASA HARI INI',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: AppColors.orange),
          SizedBox(width: 3),
          Text(
            '3 Dapur Pusaka',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _loadingBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.tint(AppColors.yellow, 0.6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
    ),
    child: const Row(
      children: [
        Icon(Icons.sync, size: 13, color: AppColors.textMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Memuat Basis Data Kuliner Offline (Hive)...',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ),
        Text(
          '100% Siap',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.greenDark,
          ),
        ),
      ],
    ),
  );

  Widget _startButton(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
    ),
    child: Container(
      height: 54,
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(AppColors.orange, 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Mulai Petualangan Kuliner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.arrow_forward,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Spotlight {
  final String title, subtitle, tag;
  final IconData icon;
  final List<Color> colors;
  const _Spotlight(this.title, this.subtitle, this.tag, this.icon, this.colors);
}

class _SpotlightCard extends StatelessWidget {
  final _Spotlight item;
  const _SpotlightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(AppColors.orange, 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              FoodImage(
                height: 52,
                width: double.infinity,
                icon: item.icon,
                colors: item.colors,
                borderRadius: BorderRadius.circular(9),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.tag,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellow,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
          Text(
            item.subtitle,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
