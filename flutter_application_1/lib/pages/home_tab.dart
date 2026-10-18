import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/decide.dart';

/// Tab "Home": sapaan, kategori cepat, rekomendasi hari ini, dan Shake to Decide.
class HomeTab extends StatelessWidget {
  final String name;
  const HomeTab({super.key, required this.name});

  static const _categories = [
    (Icons.rice_bowl, 'Gudeg'),
    (Icons.soup_kitchen, 'Soto'),
    (Icons.local_fire_department, 'Pedas'),
    (Icons.icecream, 'Jajanan'),
    (Icons.local_cafe, 'Kopi'),
  ];

  static const _picks = [
    ('Gudeg Yu Djum', 'Kraton • 1.2 km', '4.8'),
    ('Mangut Lele Mbah Marto', 'Sewon • 4.3 km', '4.9'),
    ('Soto Bathok Mbah Katro', 'Kalasan • 3.1 km', '4.7'),
  ];

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isEmpty ? 'Foodie' : name.trim().split(' ').first;
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ---- Sapaan ----
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELAMAT DATANG',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Halo, $first 👋', style: AppText.display(22)),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.tint(AppColors.greenDark, 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Banner Shake to Decide ----
            GestureDetector(
              onTap: () => showDecideSheet(context),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bingung mau makan apa?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.yellow,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Goyangkan HP-mu dan biarkan FOODIE yang memilih.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.5,
                              color: AppColors.tint(AppColors.yellow, 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Shake to Decide',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.orange, 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.casino,
                        size: 32,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Kategori ----
            Text('Kategori', style: AppText.display(16)),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  return Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.tint(AppColors.yellow, 0.45),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(c.$1, size: 24, color: AppColors.greenDark),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        c.$2,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ---- Rekomendasi ----
            Row(
              children: [
                Expanded(
                  child: Text('Pilihan Hari Ini', style: AppText.display(16)),
                ),
                const Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._picks.map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenDark.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.tint(AppColors.orange, 0.55),
                            AppColors.greenDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.ramen_dining,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.$1, style: AppText.display(14)),
                          const SizedBox(height: 3),
                          Text(
                            p.$2,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      p.$3,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
