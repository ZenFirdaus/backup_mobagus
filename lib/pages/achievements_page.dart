import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/profile.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  Profile? _profile;
  Map<String, int>? _stats;
  bool _loading = true;
  String? _error;
  int _selectedTab = 0;

  static const _rewards = [
    (
      'Voucher Makan Rp25.000',
      'Sentra Gudeg Wijilan & Resto Mitra',
      500,
      Icons.confirmation_number_outlined,
    ),
    (
      'Gratis 1 Cangkir Kopi Joss',
      'Angkringan Lik Man Stasiun Tugu',
      200,
      Icons.local_cafe_outlined,
    ),
    (
      'Paket Besek Oleh-oleh',
      'Eksklusif Dapur Kuliner Keraton',
      1500,
      Icons.card_giftcard_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await SupabaseService.instance.getProfile();
      final s = await SupabaseService.instance.getUserStats();
      if (mounted) {
        setState(() {
          _profile = p;
          _stats = s;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redeem(String title, int cost) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tukarkan Poin?'),
        content: Text('Tukarkan $cost Foodie Points untuk mendapatkan $title?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tukarkan'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await SupabaseService.instance.redeemPoints(cost);
      if (!mounted) return;
      if (success) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat! $title berhasil ditukarkan.'),
            backgroundColor: AppColors.greenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poin Anda belum mencukupi untuk penukaran ini.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orange,
                      ),
                    )
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.orange,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              _curatorCard(),
                              const SizedBox(height: 12),
                              _statsRow(),
                              const SizedBox(height: 16),
                              _tabSwitcher(),
                              const SizedBox(height: 14),
                              _selectedTab == 0
                                  ? _badgesList()
                                  : _rewardsList(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pencapaian & Poin', style: AppText.display(18)),
                const Text(
                  'Hadiah Gastronomi Mataraman',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _curatorCard() {
    final name = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : 'Kurator Rasa';
    final points = _profile?.points ?? 0;
    final level = _profile?.curatorLevel ?? 1;
    final levelTitle = _profile?.levelTitle ?? 'Pemula Rasa';

    const maxPoints = 2500;
    final progress = (points / maxPoints).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.orange,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level $level: $levelTitle',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.tint(AppColors.yellow, 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$points Poin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menuju Level Berikutnya',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.tint(AppColors.yellow, 0.75),
                ),
              ),
              Text(
                '$points / $maxPoints',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final checkins = _stats?['checkins'] ?? 0;
    final reviews = _stats?['reviews'] ?? 0;
    final favs = _stats?['favorites'] ?? 0;

    return Row(
      children: [
        _miniStat('$checkins', 'Check-in Sah'),
        const SizedBox(width: 8),
        _miniStat('$reviews', 'Ulasan Kurator'),
        const SizedBox(width: 8),
        _miniStat('$favs', 'Favorit Tersimpan'),
      ],
    );
  }

  Widget _miniStat(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(val, style: AppText.display(18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabItem(
              0,
              'Lencana Kuliner',
              Icons.stars_rounded,
            ),
          ),
          Expanded(
            child: _tabItem(
              1,
              'Katalog Hadiah',
              Icons.redeem_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, IconData icon) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: active ? AppColors.greenDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.yellow : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgesList() {
    final checkins = _stats?['checkins'] ?? 0;
    return Column(
      children: kBadges.map((badge) {
        final unlocked = checkins >= badge.requiredVisits;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked ? AppColors.orange : AppColors.line,
              width: unlocked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.tint(AppColors.orange, 0.2)
                      : AppColors.line.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.verified : Icons.lock_outline,
                  color: unlocked ? AppColors.orange : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${badge.pointsReward} Poin',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: unlocked ? AppColors.greenDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: unlocked
                      ? AppColors.tint(AppColors.greenDark, 0.15)
                      : AppColors.line.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  unlocked ? 'Koleksi' : '$checkins/${badge.requiredVisits}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? AppColors.greenDark : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _rewardsList() {
    return Column(
      children: _rewards.map((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.yellow, 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(r.$4, color: AppColors.greenDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.$1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.$3} Poin',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _redeem(r.$1, r.$3),
                child: const Text(
                  'Tukar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.red),
          const SizedBox(height: 8),
          const Text('Gagal memuat data pencapaian'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
