import 'package:flutter/material.dart';

import '../props/app_colors.dart';

/// Bar langkah (mis. Langkah 2 dari 3) untuk memperjelas alur pendaftaran.
class StepBar extends StatelessWidget {
  final int current;
  final int total;

  const StepBar({super.key, required this.current, this.total = 3});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final done = i < current;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: done
                  ? AppColors.orange
                  : AppColors.tint(AppColors.orange, 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

/// Pill kecil "LANGKAH x DARI y".
class StepPill extends StatelessWidget {
  final int current;
  final int total;

  const StepPill({super.key, required this.current, this.total = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LANGKAH $current DARI $total',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.yellow,
            ),
          ),
        ],
      ),
    );
  }
}
