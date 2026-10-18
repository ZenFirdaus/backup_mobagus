import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/restaurant.dart';
import '../pages/detail_page.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';

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
        color: Color(0xFFFFF8EA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.greenDark, 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text('Shake to Decide', style: AppText.display(22)),
          const SizedBox(height: 6),
          const Text(
            'Goyangkan HP-mu atau tekan tombol di bawah.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.orange, 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.casino,
                size: 48,
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
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'HARI INI MAKAN DI',
                            style: TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.yellow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_result!.address.split(',').first} - ${_result!.province}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.tint(AppColors.yellow, 0.75),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _result!.priceRange,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.yellow,
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
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
