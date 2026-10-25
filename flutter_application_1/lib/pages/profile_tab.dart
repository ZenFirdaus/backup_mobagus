import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/restaurant.dart';
import '../models/review.dart';
import '../models/seed_data.dart';
import '../models/user_ai_profile.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/ai_recommendation_service.dart';
import '../services/face_biometric_service.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/face_id_scanner_sheet.dart';
import 'ai_profile_page.dart';
import 'converter_page.dart';
import 'detail_page.dart';
import 'favorites_page.dart';
import 'game_page.dart';
import 'intro.dart';
import 'saran_kesan_page.dart';
import 'rewards_shop_page.dart';
import '../widgets/profile_border_avatar.dart';
import '../widgets/modern_time_picker.dart';
import '../services/reward_border_service.dart';

class ProfileTab extends StatefulWidget {
  final String name;
  final bool fromRegister;
  final bool biometricOn;
  final void Function(String? url)? onAvatarChanged;
  final void Function(String name)? onNameChanged;

  const ProfileTab({
    super.key,
    required this.name,
    this.fromRegister = false,
    this.biometricOn = false,
    this.onAvatarChanged,
    this.onNameChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late bool _biometric = widget.biometricOn;
  bool _notif = true;
  bool _mealIsSet = false;
  int _mealHour = 12;
  int _mealMinute = 0;
  String _mealLabel = 'Makan Siang';
  Profile? _profile;
  UserAiProfile? _aiProfile;
  Map<String, int> _stats = {'favorites': 0, 'checkins': 0, 'reviews': 0};
  bool _loading = true;

  // Tab controller untuk JEJAK KULINER (Ulasan, Favorit, Pencarian)
  late final TabController _histTab = TabController(length: 3, vsync: this);

  // Data history pencarian, ulasan & resto favorit
  List<Map<String, dynamic>> _searchHistory = [];
  List<Review> _myReviews = [];
  List<Restaurant> _favRestaurants = [];
  bool _histLoading = true;

  StreamSubscription<void>? _profileSub;
  StreamSubscription<void>? _rewardSub;
  StreamSubscription<Review>? _reviewAddedSub;
  StreamSubscription<Set<String>>? _favSub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
    _loadHistory();
    _subscribeRealtime();
    AiRecommendationService.instance.profileNotifier.addListener(
      _onAiProfileChanged,
    );
    _loadAiProfile();
  }

  void _onAiProfileChanged() {
    if (mounted) {
      setState(() {
        _aiProfile = AiRecommendationService.instance.profileNotifier.value;
      });
    }
  }

  Future<void> _loadAiProfile() async {
    final p = await AiRecommendationService.instance.getProfile();
    if (mounted) setState(() => _aiProfile = p);
  }

  void _subscribeRealtime() {
    final svc = SupabaseService.instance;
    _profileSub = svc.onProfileChanged.listen((_) {
      if (!mounted) return;
      _load();
    });

    _rewardSub = RewardBorderService.instance.onChange.listen((_) {
      if (!mounted) return;
      _load();
    });

    _reviewAddedSub = svc.onReviewAdded.listen((rev) {
      if (!mounted) return;
      setState(() {
        if (!_myReviews.any((r) => r.id == rev.id)) {
          _myReviews.insert(0, rev);
        }
        _stats['reviews'] = (_stats['reviews'] ?? 0) + 1;
        if (_profile != null) {
          _profile = Profile(
            id: _profile!.id,
            displayName: _profile!.displayName,
            avatarUrl: _profile!.avatarUrl,
            activeBorderId: _profile!.activeBorderId,
            points: _profile!.points + 20,
            createdAt: _profile!.createdAt,
          );
        }
      });
      _load();
      _loadHistory();
    });

    _favSub = svc.favoritesStream.listen((favs) {
      if (!mounted) return;
      setState(() {
        _stats['favorites'] = favs.length;
      });
      _load();
      _loadHistory();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && widget.name.trim().isNotEmpty) {
      if (_profile != null) {
        setState(() {
          _profile = Profile(
            id: _profile!.id,
            displayName: widget.name,
            avatarUrl: _profile!.avatarUrl,
            activeBorderId: _profile!.activeBorderId,
            points: _profile!.points,
            createdAt: _profile!.createdAt,
          );
        });
      } else {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    AiRecommendationService.instance.profileNotifier.removeListener(
      _onAiProfileChanged,
    );
    _profileSub?.cancel();
    _rewardSub?.cancel();
    _reviewAddedSub?.cancel();
    _favSub?.cancel();
    _histTab.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final currentEmail = Supabase.instance.client.auth.currentUser?.email;
      if (currentEmail != null && currentEmail.isNotEmpty) {
        _biometric = await FaceBiometricService.instance.isFaceEnrolled(
          email: currentEmail,
        );
      } else {
        _biometric = await FaceBiometricService.instance.isFaceEnrolled();
      }
      _notif = HiveService.instance.isNotificationsEnabled();

      final mealPref = HiveService.instance.getMealReminderPreference();
      _mealIsSet = mealPref['isSet'] as bool? ?? false;
      _mealHour = mealPref['hour'] as int? ?? 12;
      _mealMinute = mealPref['minute'] as int? ?? 0;
      _mealLabel = mealPref['label'] as String? ?? 'Makan Siang';

      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool val) async {
    final currentEmail =
        Supabase.instance.client.auth.currentUser?.email ??
        (_profile?.displayName != null
            ? '${_profile!.displayName.toLowerCase().replaceAll(' ', '.')}@foodie.id'
            : 'kurator@foodie.id');
    final currentName = _profile?.displayName ?? widget.name;

    if (val) {
      final prefs = await SharedPreferences.getInstance();
      final savedPwd = prefs.getString('foodie_saved_password');

      if (!mounted) return;

      // Buka FaceIdScannerSheet dengan preview kamera depan
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (ctx) => FaceIdScannerSheet(
          userName: currentName,
          userEmail: currentEmail,
          savedPassword: savedPwd,
          isEnrollment: true,
          onSuccess: () async {
            Navigator.of(ctx).pop();
            setState(() => _biometric = true);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.face_unlock_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Apple Face ID berhasil diaktifkan untuk $currentName.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.greenDark,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      );
      return;
    }

    setState(() => _biometric = false);
    try {
      await FaceBiometricService.instance.removeEnrolledFace(
        email: currentEmail,
      );
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Face ID dinonaktifkan'),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleNotif(bool val) async {
    setState(() => _notif = val);
    try {
      await HiveService.instance.setNotificationsEnabled(val);
      await HiveService.instance.saveMealReminderPreference(
        enabled: val && _mealIsSet,
        isSet: _mealIsSet,
        hour: _mealHour,
        minute: _mealMinute,
        label: _mealLabel,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_notifications_enabled', val);

      if (val && _mealIsSet) {
        await NotificationService.instance.requestPermissions();
        await NotificationService.instance.scheduleDailyMealReminder(
          hour: _mealHour,
          minute: _mealMinute,
          label: _mealLabel,
        );
      } else {
        await NotificationService.instance.cancelAll();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              val
                  ? (_mealIsSet
                        ? 'Notifikasi aktif (Jadwal: $_mealLabel $_mealHour:${_mealMinute.toString().padLeft(2, '0')} WIB)'
                        : 'Notifikasi aktif')
                  : 'Semua notifikasi dinonaktifkan',
            ),
            backgroundColor: val ? AppColors.greenDark : AppColors.charcoal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _showMealReminderPicker() async {
    if (!_notif) {
      setState(() => _notif = true);
      await HiveService.instance.setNotificationsEnabled(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_notifications_enabled', true);
      await NotificationService.instance.requestPermissions();
    }

    if (!mounted) return;

    if (_mealIsSet) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Pengingat Makan Harian', style: AppText.display(16)),
          content: Text(
            'Saat ini diatur untuk $_mealLabel pukul ${_mealHour.toString().padLeft(2, '0')}:${_mealMinute.toString().padLeft(2, '0')} WIB.',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text(
                'Hapus Pengingat',
                style: TextStyle(color: AppColors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Ubah Jam'),
            ),
          ],
        ),
      );

      if (action == 'delete') {
        setState(() {
          _mealIsSet = false;
        });
        await HiveService.instance.removeMealReminderPreference();
        await NotificationService.instance.cancelNotification(9999);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengingat makan harian dihapus'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      } else if (action != 'edit') {
        return;
      }
    }

    if (!mounted) return;

    final pickedTime = await showModernTimePicker(
      context,
      initialTime: TimeOfDay(hour: _mealHour, minute: _mealMinute),
      title: 'Pilih Jam Pengingat Makan',
    );

    if (pickedTime == null) return;

    String newLabel = 'Makan Siang';
    if (pickedTime.hour >= 5 && pickedTime.hour < 11) {
      newLabel = 'Sarapan Pagi';
    } else if (pickedTime.hour >= 11 && pickedTime.hour < 16) {
      newLabel = 'Makan Siang';
    } else if (pickedTime.hour >= 16 && pickedTime.hour < 21) {
      newLabel = 'Santap Malam Gudeg';
    } else {
      newLabel = 'Kuliner Dini Hari Jogja';
    }

    setState(() {
      _notif = true;
      _mealIsSet = true;
      _mealHour = pickedTime.hour;
      _mealMinute = pickedTime.minute;
      _mealLabel = newLabel;
    });

    await HiveService.instance.setNotificationsEnabled(true);
    await HiveService.instance.saveMealReminderPreference(
      enabled: true,
      isSet: true,
      hour: pickedTime.hour,
      minute: pickedTime.minute,
      label: newLabel,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('foodie_notifications_enabled', true);

    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleDailyMealReminder(
      hour: pickedTime.hour,
      minute: pickedTime.minute,
      label: newLabel,
    );

    if (mounted) {
      NotificationService.showInAppBanner(
        context,
        title: 'Pengingat Makan Diatur',
        body:
            '$newLabel • Pukul ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} WIB',
        icon: Icons.schedule_rounded,
      );
    }
  }

  Future<void> _loadHistory() async {
    final svc = SupabaseService.instance;
    final results = await Future.wait([
      svc.getSearchHistory(),
      svc.getUserReviews(),
      svc.getFavoriteRestaurants(),
    ]);
    if (!mounted) return;
    setState(() {
      _searchHistory = results[0] as List<Map<String, dynamic>>;
      _myReviews = results[1] as List<Review>;
      _favRestaurants = results[2] as List<Restaurant>;
      _stats['favorites'] = _favRestaurants.length;
      _stats['reviews'] = _myReviews.length;
      _histLoading = false;
    });
  }

  void _showCoverageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            Text('Cakupan Wilayah', style: AppText.display(18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FOODIE mengkurasi warisan kuliner secara eksklusif pada wilayah:',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Daerah Istimewa Yogyakarta (DIY)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Kota Yogyakarta, Sleman, Bantul, Kulon Progo, Gunungkidul',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Provinsi Jawa Tengah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Surakarta (Solo), Semarang, Magelang, Klaten, dan sekitarnya',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ─── INFORMASI LEVEL & POIN KURATOR ───

  void _showLevelInfoSheet() {
    final p = _profile;
    final currentLv = p?.curatorLevel ?? 1;
    final currentTitle = p?.levelTitle ?? 'Pemula Rasa';
    final currentPts = p?.points ?? 100;
    final neededPts = p?.pointsToNextLevel ?? (300 - currentPts).clamp(0, 300);

    final levels = [
      {
        'lv': 1,
        'title': 'Pemula Rasa',
        'range': '0 - 299 Poin',
        'desc': 'Baru memulai petualangan kuliner di Jogja & Jateng.',
      },
      {
        'lv': 2,
        'title': 'Penjelajah Kuliner',
        'range': '300 - 799 Poin',
        'desc': 'Mulai rajin menjelajahi warung & kuliner legendaris.',
      },
      {
        'lv': 3,
        'title': 'Kurator Kuliner',
        'range': '800 - 1499 Poin',
        'desc': 'Rasa dan ulasan Anda menjadi rujukan sesama pencinta rasa.',
      },
      {
        'lv': 4,
        'title': 'Penjelajah Kuliner Sejati',
        'range': '1500 - 2499 Poin',
        'desc': 'Koleksi pengalaman rasa yang luas dan berwawasan tinggi.',
      },
      {
        'lv': 5,
        'title': 'Kurator Utama',
        'range': '≥ 2500 Poin',
        'desc': 'Gelar tertinggi kurator kuliner kehormatan FOODIE.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tingkatan Kurator Kuliner',
                          style: AppText.display(17),
                        ),
                        const Text(
                          'Sistem reputasi dan akumulasi poin kurator FOODIE',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Kartu Pengguna Saat Ini
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.charcoal, Color(0xFF333333)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Level $currentLv',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$currentPts Poin',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p?.levelProgress ?? 0.3,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD54F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentLv >= 5
                          ? 'Selamat! Anda telah mencapai tingkatan kurator tertinggi.'
                          : 'Butuh $neededPts poin lagi untuk naik ke Level ${currentLv + 1} (${levels[currentLv]['title']}).',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Cara Mendapatkan Poin',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildPointActionTile(
                icon: Icons.rate_review_rounded,
                color: AppColors.orange,
                title: 'Tulis Ulasan & Rating',
                reward: '+20 Poin',
                desc: 'Bagikan ulasan jujur kuliner yang Anda nikmati.',
              ),
              const SizedBox(height: 6),
              _buildPointActionTile(
                icon: Icons.location_on_rounded,
                color: AppColors.greenDark,
                title: 'Check-in di Restoran',
                reward: '+50 Poin',
                desc: 'Verifikasi kunjungan langsung saat bersantap di lokasi.',
              ),
              const SizedBox(height: 6),
              _buildPointActionTile(
                icon: Icons.sports_esports_rounded,
                color: const Color(0xFF6C5CE7),
                title: 'Mainkan Mini-Game',
                reward: 's/d +350 Poin',
                desc: 'Selesaikan tebak rasa Kulinerdle dan Kasus Detektif.',
              ),

              const SizedBox(height: 18),
              const Text(
                'Daftar Tingkatan Level',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...levels.map((item) {
                final lvNum = item['lv'] as int;
                final isCurrent = lvNum == currentLv;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.orange.withValues(alpha: 0.08)
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.orange
                          : AppColors.line.withValues(alpha: 0.5),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.orange
                              : AppColors.charcoal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$lvNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.charcoal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isCurrent
                                        ? AppColors.orange
                                        : AppColors.textDark,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Level Anda',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['range'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                  label: const Text(
                    'Tukar Poin di Toko Border Hadiah',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RewardsShopPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String reward,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reward,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EDIT PROFILE SHEET ───

  void _showEditProfile() {
    final nameCtrl = TextEditingController(
      text: _profile?.displayName ?? widget.name,
    );
    String? tempAvatarUrl = _profile?.avatarUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text('Edit Profil', style: AppText.display(20)),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Avatar area ──
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _showPhotoSourceSheet(
                            parentContext: ctx,
                            hasExistingPhoto:
                                tempAvatarUrl != null &&
                                tempAvatarUrl!.trim().isNotEmpty,
                            onPicked: (url) {
                              tempAvatarUrl = url;
                              setSheet(() {});
                            },
                            onDeletePhoto: () {
                              tempAvatarUrl = null;
                              setSheet(() {});
                            },
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AvatarImage(
                                url: tempAvatarUrl,
                                size: 84,
                                fallbackText: nameCtrl.text.isNotEmpty
                                    ? nameCtrl.text
                                    : 'F',
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.charcoal,
                              side: const BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_a_photo_rounded,
                              size: 16,
                              color: AppColors.orange,
                            ),
                            label: Text(
                              (tempAvatarUrl != null &&
                                      tempAvatarUrl!.trim().isNotEmpty)
                                  ? 'Ubah Foto'
                                  : 'Pilih Foto',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () async {
                              await _showPhotoSourceSheet(
                                parentContext: ctx,
                                hasExistingPhoto:
                                    tempAvatarUrl != null &&
                                    tempAvatarUrl!.trim().isNotEmpty,
                                onPicked: (url) {
                                  tempAvatarUrl = url;
                                  setSheet(() {});
                                },
                                onDeletePhoto: () {
                                  tempAvatarUrl = null;
                                  setSheet(() {});
                                },
                              );
                            },
                          ),
                          if (tempAvatarUrl != null &&
                              tempAvatarUrl!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(color: AppColors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                tempAvatarUrl = null;
                                setSheet(() {});
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Nama ──
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nama kurator Anda',
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.orange,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tombol simpan ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) return;
                      Navigator.pop(ctx);

                      final cleanAvatar =
                          (tempAvatarUrl != null &&
                              tempAvatarUrl!.trim().isNotEmpty)
                          ? tempAvatarUrl!.trim()
                          : null;

                      final activeBorder = _profile?.activeBorderId;

                      // 1. Update UI langsung tanpa delay
                      setState(() {
                        _profile = Profile(
                          id:
                              _profile?.id ??
                              SupabaseService.instance.userId ??
                              'curator_user',
                          displayName: newName,
                          avatarUrl: cleanAvatar,
                          activeBorderId: activeBorder,
                          points: _profile?.points ?? 100,
                          createdAt: _profile?.createdAt ?? DateTime.now(),
                        );
                      });
                      widget.onNameChanged?.call(newName);
                      widget.onAvatarChanged?.call(cleanAvatar);

                      // 2. Simpan permanen ke SharedPreferences & Supabase
                      await SupabaseService.instance.upsertProfile(
                        displayName: newName,
                        avatarUrl: cleanAvatar,
                        activeBorderId: activeBorder,
                      );
                      await _load();
                      await _loadHistory();

                      if (mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Profil berhasil diperbarui.'),
                              backgroundColor: AppColors.greenDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      }
                    },
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar({
    required ImageSource source,
    required void Function(String?) onPicked,
  }) async {
    final picker = ImagePicker();
    XFile? picked;
    final sourceName = source == ImageSource.camera ? 'kamera' : 'galeri';
    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengakses $sourceName: ${e.toString().split(':').first}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (picked == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Memproses foto dari $sourceName...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.charcoal,
      ),
    );

    final uid = SupabaseService.instance.userId ?? 'curator_user';
    String? uploadedUrl;
    try {
      final bytes = await picked.readAsBytes();
      String ext = 'jpg';
      if (picked.name.contains('.')) {
        ext = picked.name.split('.').last.toLowerCase();
      }
      final mimeType = (ext == 'png')
          ? 'image/png'
          : (ext == 'webp')
          ? 'image/webp'
          : 'image/jpeg';
      final filePath = '$uid/profile.$ext';
      final supabase = Supabase.instance.client;

      try {
        await supabase.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );

        uploadedUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        uploadedUrl = '$uploadedUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      } catch (storageErr) {
        debugPrint('Supabase storage upload fallback to base64: $storageErr');
        final b64 = base64Encode(bytes);
        uploadedUrl = 'data:$mimeType;base64,$b64';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memproses foto: ${e.toString().split(':').first}',
              ),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    onPicked(uploadedUrl);
  }

  Future<void> _showPhotoSourceSheet({
    required BuildContext parentContext,
    required void Function(String?) onPicked,
    required VoidCallback onDeletePhoto,
    required bool hasExistingPhoto,
  }) async {
    final act = await showModalBottomSheet<String>(
      context: parentContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Sumber Foto Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _photoSourceTile(
                ctx: sheetCtx,
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Foto dari Kamera',
                subtitle: 'Gunakan kamera perangkat untuk mengambil foto baru',
                color: AppColors.orange,
                action: 'camera',
              ),
              const SizedBox(height: 10),
              _photoSourceTile(
                ctx: sheetCtx,
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri',
                subtitle: 'Pilih foto yang tersimpan di album perangkat',
                color: AppColors.slateBlue,
                action: 'gallery',
              ),
              if (hasExistingPhoto) ...[
                const SizedBox(height: 10),
                _photoSourceTile(
                  ctx: sheetCtx,
                  icon: Icons.delete_outline_rounded,
                  title: 'Hapus Foto Profil',
                  subtitle: 'Gunakan inisial nama Anda sebagai avatar',
                  color: AppColors.red,
                  action: 'delete',
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (act == 'camera') {
      await _pickAvatar(source: ImageSource.camera, onPicked: onPicked);
    } else if (act == 'gallery') {
      await _pickAvatar(source: ImageSource.gallery, onPicked: onPicked);
    } else if (act == 'delete') {
      onDeletePhoto();
    }
  }

  Widget _photoSourceTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String action,
  }) {
    final isDelete = action == 'delete';
    return InkWell(
      onTap: () => Navigator.pop(ctx, action),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDelete ? AppColors.red : AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.getProfile(),
        SupabaseService.instance.getUserStats(),
        RewardBorderService.instance.getActiveBorderId(),
        RewardBorderService.instance.getUserPoints(),
      ]);
      if (!mounted) return;
      var prof = results[0] as Profile?;
      final stats = results[1] as Map<String, int>;
      final activeBorder = results[2] as String?;
      final pts = results[3] as int;

      if (prof != null) {
        prof = Profile(
          id: prof.id,
          displayName: prof.displayName,
          avatarUrl: prof.avatarUrl,
          activeBorderId: activeBorder ?? prof.activeBorderId,
          points: pts,
          createdAt: prof.createdAt,
        );
      }

      setState(() {
        _profile = prof;
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text('Kamu perlu login lagi untuk masuk ke FOODIE.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await SupabaseService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const IntroPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final name = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : widget.name.trim().isNotEmpty
        ? widget.name.trim()
        : (currentUser?.userMetadata?['name'] as String? ?? 'Kurator Rasa');
    final email =
        currentUser?.email ??
        (widget.name.isNotEmpty
            ? '${widget.name.toLowerCase().replaceAll(' ', '.')}@culinary.id'
            : 'kurator@foodie.id');
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : RefreshIndicator(
                color: AppColors.orange,
                onRefresh: () async {
                  await _load();
                  await _loadHistory();
                },
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Text('Profil', style: AppText.display(22)),
                    const SizedBox(height: 16),
                    _accountCard(name, email),
                    if (widget.fromRegister) ...[
                      const SizedBox(height: 12),
                      _welcomeBanner(),
                    ],
                    const SizedBox(height: 14),
                    _aiPersonaCard(),
                    const SizedBox(height: 14),
                    _statsRow(),
                    const SizedBox(height: 18),

                    // ── Arena Gamifikasi & Rewards ──
                    _sectionLabel('ARENA GAMIFIKASI & REWARDS'),
                    const SizedBox(height: 8),
                    _gamificationBentoGrid(),
                    const SizedBox(height: 20),

                    // ── Jejak Kuliner ──
                    _sectionLabel('JEJAK KULINER KURATOR'),
                    const SizedBox(height: 8),
                    _historySection(),
                    const SizedBox(height: 20),
                    const SizedBox(height: 16),
                    _sectionLabel('UTILITAS WISATAWAN'),
                    const SizedBox(height: 8),
                    _group([
                      _tile(
                        Icons.currency_exchange,
                        'Konverter Kurs & Zona Waktu',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConverterPage(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('PREFERENSI SISTEM'),
                    const SizedBox(height: 8),
                    _group([
                      _switchTile(
                        Icons.face_retouching_natural_rounded,
                        'Autentikasi Wajah (Face ID)',
                        _biometric,
                        _toggleBiometric,
                      ),
                      _switchTile(
                        Icons.notifications_rounded,
                        'Notifikasi',
                        _notif,
                        _toggleNotif,
                      ),
                      _tile(
                        _notif ? Icons.alarm_rounded : Icons.alarm_off_rounded,
                        'Jadwal Pengingat Makan',
                        trailing: _notif
                            ? (_mealIsSet
                                  ? '${_mealHour.toString().padLeft(2, '0')}:${_mealMinute.toString().padLeft(2, '0')} WIB'
                                  : 'Belum Diatur >')
                            : 'Notifikasi Nonaktif',
                        onTap: _showMealReminderPicker,
                      ),
                      _tile(
                        Icons.map_rounded,
                        'Cakupan Wilayah',
                        trailing: 'DIY & Jateng',
                        onTap: _showCoverageDialog,
                      ),
                      _tile(
                        Icons.rate_review_rounded,
                        'Saran & Kesan',
                        trailing: 'Mata Kuliah',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SaranKesanPage(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _logoutButton(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'FOODIE INDONESIA\nv1.0.0\nDaerah Istimewa Yogyakarta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── HISTORY SECTION ───

  // ─── JEJAK KULINER SECTION (TAB: ULASAN, FAVORIT, PENCARIAN) ───

  Widget _historySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Segmented Tab Bar Modern
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F4F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: TabBar(
              controller: _histTab,
              labelColor: AppColors.charcoal,
              unselectedLabelColor: AppColors.textMuted,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              labelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 13),
                      const SizedBox(width: 4),
                      Text('Favorit (${_favRestaurants.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rate_review_rounded, size: 13),
                      const SizedBox(width: 4),
                      Text('Ulasan (${_myReviews.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 13),
                      const SizedBox(width: 4),
                      Text('Pencarian (${_searchHistory.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 290,
            child: _histLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  )
                : TabBarView(
                    controller: _histTab,
                    children: [
                      _favoritesTab(),
                      _reviewsTab(),
                      _searchHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsTab() {
    if (_myReviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  size: 26,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum Ada Ulasan Ditulis',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kunjungi restoran favoritmu dan bagikan pengalaman rasa pertama Anda!',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: _myReviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final rev = _myReviews[i];
        final restoName =
            (rev.restaurantName != null &&
                rev.restaurantName!.isNotEmpty &&
                rev.restaurantName != rev.restaurantId)
            ? rev.restaurantName!
            : (kDefaultRestaurants
                      .where(
                        (r) =>
                            r.id == rev.restaurantId ||
                            r.id == 'resto_${rev.restaurantId}' ||
                            (rev.restaurantId.startsWith('resto_') &&
                                r.id ==
                                    rev.restaurantId.replaceFirst(
                                      'resto_',
                                      '',
                                    )),
                      )
                      .firstOrNull
                      ?.name ??
                  'Tempat Kuliner');

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final resto =
                await SupabaseService.instance.getRestaurant(
                  rev.restaurantId,
                ) ??
                kDefaultRestaurants
                    .where(
                      (r) =>
                          r.id == rev.restaurantId ||
                          r.id == 'resto_${rev.restaurantId}' ||
                          (rev.restaurantId.startsWith('resto_') &&
                              r.id ==
                                  rev.restaurantId.replaceFirst('resto_', '')),
                    )
                    .firstOrNull;
            if (resto != null && mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailPage(restaurant: resto),
                ),
              );
              _load();
              _loadHistory();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    size: 18,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restoName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: List.generate(
                          5,
                          (j) => Icon(
                            j < rev.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 12.5,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rev.comment.isNotEmpty
                            ? rev.comment
                            : 'Tidak ada ulasan tertulis',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _favoritesTab() {
    if (_favRestaurants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 26,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum Ada Restoran Favorit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tandai ikon hati pada kuliner yang kamu suka untuk diakses cepat di sini.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_favRestaurants.length} Kuliner Tersimpan',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesPage()),
                  );
                  _load();
                  _loadHistory();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka Halaman Favorit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            itemCount: _favRestaurants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final r = _favRestaurants[i];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailPage(restaurant: r),
                    ),
                  );
                  _load();
                  _loadHistory();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.line.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      FoodImage(
                        imageUrl: r.effectiveImageUrl.isNotEmpty
                            ? r.effectiveImageUrl
                            : null,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(10),
                        icon: Icons.restaurant_rounded,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12.5,
                                  color: AppColors.orange,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  r.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '• ${r.category}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.priceRange.isNotEmpty
                                  ? r.priceRange
                                  : 'Harga terjangkau',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchHistoryTab() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  size: 26,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum Ada Riwayat Pencarian',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kata kunci pencarian kuliner Anda akan tersimpan otomatis di sini.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchHistory.length} kata kunci tersimpan',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Hapus Semua Riwayat?'),
                      content: const Text(
                        'Semua jejak kata kunci pencarian Anda akan dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus Semua'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await SupabaseService.instance.clearSearchHistory();
                    setState(() => _searchHistory = []);
                  }
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 13,
                      color: AppColors.red,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Hapus semua',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((item) {
                final q = item['query'] as String? ?? '';
                if (q.trim().isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.line.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        q,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          await SupabaseService.instance.removeSearchItem(q);
                          setState(
                            () => _searchHistory.removeWhere(
                              (e) => e['query'] == q,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiPersonaCard() {
    final p = _aiProfile;
    final bool isComplete = p != null && p.isCompleted;
    final int progress = p?.completionPercentage ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AiProfilePage()));
        _loadAiProfile();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete
                ? [const Color(0xFF1C1D1F), const Color(0xFF2C2E33)]
                : [const Color(0xFF202024), const Color(0xFF382F24)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.orange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Preferensi & Persona Kuliner',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isComplete
                            ? p.personaSummary
                            : 'Lengkapi data diri untuk rekomendasi personal',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete ? AppColors.greenDark : AppColors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isComplete ? 'Aktif' : '$progress%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100.0,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? AppColors.green : AppColors.orange,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isComplete
                      ? 'Data diri, selera rasa & tempat tinggal terhubung'
                      : 'Kelengkapan: $progress% • Klik untuk lengkapi profil',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Atur',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.yellow,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar — bisa foto atau inisial
          GestureDetector(
            onTap: _showEditProfile,
            child: Stack(
              children: [
                ProfileBorderAvatar(
                  avatarUrl: _profile?.avatarUrl,
                  borderId: _profile?.activeBorderId,
                  size: 56,
                  fallbackText: name.isNotEmpty ? name : 'F',
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showLevelInfoSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 13,
                          color: Color(0xFFFFD54F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _profile != null
                              ? 'Level ${_profile!.curatorLevel}: ${_profile!.levelTitle}'
                              : 'Kurator Yogyakarta',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_profile != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showLevelInfoSheet,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_profile!.points} Poin',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFE082),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _profile!.curatorLevel >= 5
                                  ? 'Level Maksimal'
                                  : 'Target Lv ${_profile!.curatorLevel + 1}: ${_profile!.nextLevelPoints} Poin',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _profile!.levelProgress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFD54F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.celebration_rounded, size: 20, color: AppColors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akun berhasil dibuat! Lengkapi profilmu agar rekomendasi makin pas.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final favCount = _favRestaurants.isNotEmpty
        ? _favRestaurants.length
        : (_stats['favorites'] ?? 0);
    final revCount = _myReviews.isNotEmpty
        ? _myReviews.length
        : (_stats['reviews'] ?? 0);
    final pts = _profile?.points ?? 100;

    return Row(
      children: [
        _stat(
          '$favCount',
          'Favorit',
          icon: Icons.favorite_rounded,
          onTap: () {
            _histTab.animateTo(0);
          },
        ),
        const SizedBox(width: 10),
        _stat(
          '$revCount',
          'Ulasan',
          icon: Icons.rate_review_rounded,
          onTap: () {
            _histTab.animateTo(1);
          },
        ),
        const SizedBox(width: 10),
        _stat(
          '$pts',
          'Poin Rasa',
          icon: Icons.stars_rounded,
          isPoints: true,
          onTap: _showLevelInfoSheet,
        ),
      ],
    );
  }

  Widget _gamificationBentoGrid() {
    final pts = _profile?.points ?? 100;
    return Row(
      children: [
        // Bento Card 1: Mini Games Kuliner
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const GamePage()));
                _load();
                _loadHistory();
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            size: 20,
                            color: AppColors.orange,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '3 Game',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mini Games',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Main & raih poin',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bento Card 2: Toko Border & Rewards
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RewardsShopPage()),
                );
                _load();
                _loadHistory();
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.greenDark.withValues(alpha: 0.16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.greenDark.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: AppColors.greenDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greenDark.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pts Poin',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Toko Rewards',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tukar border avatar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(
    String value,
    String label, {
    VoidCallback? onTap,
    IconData? icon,
    bool isPoints = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPoints
                    ? AppColors.orange.withValues(alpha: 0.28)
                    : AppColors.line.withValues(alpha: 0.4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isPoints ? AppColors.orange : AppColors.charcoal,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      value,
                      style: AppText.display(18).copyWith(
                        color: isPoints ? AppColors.orange : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isPoints ? AppColors.orange : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.line.withValues(alpha: 0.6),
              ),
          ],
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Icon(icon, size: 21, color: AppColors.greenDark);
  }

  Widget _tile(
    IconData icon,
    String title, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: _iconBox(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.greenDark,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: _iconBox(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.greenDark,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.orange,
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Keluar Akun',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
