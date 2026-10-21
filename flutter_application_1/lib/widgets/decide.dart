import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/restaurant.dart';
import '../pages/detail_page.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import 'common_widgets.dart';

/// Membuka bottom sheet "Shake to Decide".
Future<void> showDecideSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DecideSheet(),
  );
}

class _DecideSheet extends StatefulWidget {
  const _DecideSheet();

  @override
  State<_DecideSheet> createState() => _DecideSheetState();
}

class _DecideSheetState extends State<_DecideSheet>
    with SingleTickerProviderStateMixin {
  List<Restaurant> _options = [];
  final _rng = Random();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  Restaurant? _result;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    try {
      _sub = accelerometerEventStream().listen((e) {
        final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81;
        if (g > 2.4) _decide();
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _loadRestaurants() async {
    final list = await SupabaseService.instance.getRestaurants();
    if (mounted) setState(() => _options = list);
  }

  Future<void> _decide() async {
    if (_options.isEmpty) return;
    final now = DateTime.now();
    if (_rolling || now.difference(_lastShake).inMilliseconds < 1500) return;
    _lastShake = now;
    setState(() => _rolling = true);
    _shake.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _shake.stop();
    _shake.value = 0;
    setState(() {
      _result = _options[_rng.nextInt(_options.length)];
      _rolling = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Shake to Decide', style: AppText.display(22)),
          const SizedBox(height: 6),
          const Text(
            'Goyangkan HP-mu atau tekan tombol di bawah.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 22),

          // ikon bergoyang
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.rotate(
              angle: sin(_shake.value * pi * 2) * 0.35,
              child: child,
            ),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.casino_rounded,
                size: 44,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // hasil
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _result == null
                ? Text(
                    _rolling ? 'Memilih untukmu...' : 'Belum ada pilihan',
                    key: ValueKey(_rolling),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailPage(restaurant: _result!),
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(_result!.id),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x15000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'HARI INI MAKAN DI',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FoodImage(
                            imageUrl: _result!.imageUrl,
                            width: 64,
                            height: 64,
                            borderRadius: BorderRadius.circular(16),
                            icon: Icons.restaurant_rounded,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_result!.address.split(',').first} - ${_result!.province}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _result!.priceRange,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _decide,
            child: Container(
              height: 50,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _result == null ? 'Acak Sekarang' : 'Acak Lagi',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
