import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/review.dart';
import '../models/user_ai_profile.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/ai_recommendation_service.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/face_id_scanner_sheet.dart';
import 'achievements_page.dart';
import 'ai_profile_page.dart';
import 'converter_page.dart';
import 'detail_page.dart';
import 'favorites_page.dart';
import 'game_page.dart';
import 'intro.dart';
import 'saran_kesan_page.dart';
import '../widgets/modern_time_picker.dart';

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

  // Tab controller untuk RIWAYAT
  late final TabController _histTab = TabController(length: 2, vsync: this);

  // Data history pencarian & ulasan
  List<Map<String, dynamic>> _searchHistory = [];
  List<Review> _myReviews = [];
  bool _histLoading = true;

  StreamSubscription<void>? _profileSub;
  StreamSubscription<Review>? _reviewAddedSub;
  StreamSubscription<Set<String>>? _favSub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
    _loadHistory();
    _subscribeRealtime();
    AiRecommendationService.instance.profileNotifier.addListener(_onAiProfileChanged);
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
    });
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      if (_profile != null) {
        setState(() {
          _profile = Profile(
            id: _profile!.id,
            displayName: widget.name,
            avatarUrl: _profile!.avatarUrl,
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
    AiRecommendationService.instance.profileNotifier.removeListener(_onAiProfileChanged);
    _profileSub?.cancel();
    _reviewAddedSub?.cancel();
    _favSub?.cancel();
    _histTab.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _biometric =
          prefs.getBool('foodie_biometric_enabled') ?? widget.biometricOn;
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
    if (val) {
      final currentEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'kurator@foodie.id';
      final currentName = _profile?.displayName ?? 'Foodie Kurator';

      // Buka FaceIdScannerSheet dengan preview kamera depan
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (ctx) => FaceIdScannerSheet(
          userName: currentName,
          userEmail: currentEmail,
          isEnrollment: true,
          onSuccess: () async {
            Navigator.of(ctx).pop();
            setState(() => _biometric = true);
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('foodie_biometric_enabled', true);
              await prefs.setString('foodie_last_user_name', currentName);
              await prefs.setString('foodie_last_user_email', currentEmail);
            } catch (_) {}
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.face_unlock_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Apple Face ID berhasil diaktifkan.'),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.greenDark,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_biometric_enabled', false);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Pengingat Makan Harian', style: AppText.display(16)),
          content: Text(
            'Saat ini diatur untuk $_mealLabel pukul ${_mealHour.toString().padLeft(2, '0')}:${_mealMinute.toString().padLeft(2, '0')} WIB.',
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Hapus Pengingat',
                  style: TextStyle(color: AppColors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
        body: '$newLabel • Pukul ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} WIB',
        icon: Icons.schedule_rounded,
      );
    }
  }

  Future<void> _loadHistory() async {
    final svc = SupabaseService.instance;
    final results = await Future.wait([
      svc.getSearchHistory(),
      svc.getUserReviews(),
    ]);
    if (!mounted) return;
    setState(() {
      _searchHistory = results[0] as List<Map<String, dynamic>>;
      _myReviews = results[1] as List<Review>;
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
                  fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
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
                        color: AppColors.textDark),
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
                        color: AppColors.textDark),
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text('Edit Profil', style: AppText.display(20)),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded,
                          size: 22, color: AppColors.textMuted),
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
                          if (tempAvatarUrl != null && tempAvatarUrl!.trim().isNotEmpty) {
                            final act = await showModalBottomSheet<String>(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (sheetCtx) => Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 40, height: 4,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: AppColors.line,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    Text('Foto Profil', style: AppText.display(18)),
                                    const SizedBox(height: 20),
                                    _actionTile(
                                      sheetCtx,
                                      Icons.photo_library_rounded,
                                      'Pilih Foto Baru dari Galeri',
                                      AppColors.orange,
                                      'gallery',
                                    ),
                                    const SizedBox(height: 10),
                                    _actionTile(
                                      sheetCtx,
                                      Icons.delete_outline_rounded,
                                      'Hapus Foto Profil',
                                      AppColors.red,
                                      'delete',
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (act == 'gallery') {
                              await _pickAvatarFromGallery((url) {
                                tempAvatarUrl = url;
                                setSheet(() {});
                              });
                            } else if (act == 'delete') {
                              tempAvatarUrl = null;
                              setSheet(() {});
                            }
                          } else {
                            await _pickAvatarFromGallery((url) {
                              tempAvatarUrl = url;
                              setSheet(() {});
                            });
                          }
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
                                child: const Icon(Icons.photo_library_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.orange,
                              side: const BorderSide(color: AppColors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 16),
                            label: Text(
                              (tempAvatarUrl != null && tempAvatarUrl!.trim().isNotEmpty)
                                  ? 'Ganti (Galeri)'
                                  : 'Pilih dari Galeri',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () async {
                              await _pickAvatarFromGallery((url) {
                                tempAvatarUrl = url;
                                setSheet(() {});
                              });
                            },
                          ),
                          if (tempAvatarUrl != null && tempAvatarUrl!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(color: AppColors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: const Text(
                                'Hapus Foto',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                      fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Nama kurator Anda',
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                          color: AppColors.orange, width: 1.5),
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

                      final cleanAvatar = (tempAvatarUrl != null && tempAvatarUrl!.trim().isNotEmpty)
                          ? tempAvatarUrl!.trim()
                          : null;

                      // 1. Update UI langsung tanpa delay
                      setState(() {
                        _profile = Profile(
                          id: _profile?.id ?? SupabaseService.instance.userId ?? 'curator_user',
                          displayName: newName,
                          avatarUrl: cleanAvatar,
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
                      );
                      await _load();

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
                          fontSize: 14, fontWeight: FontWeight.w700),
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

  Future<void> _pickAvatarFromGallery(void Function(String?) onPicked) async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengakses galeri: ${e.toString().split(':').first}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (picked == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Memproses foto dari galeri...'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
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
        await supabase.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
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
              content: Text('Gagal memproses foto: ${e.toString().split(':').first}'),
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

  Widget _actionTile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    String value,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color == AppColors.red ? AppColors.red : AppColors.textDark,
              ),
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
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile?;
        _stats = results[1] as Map<String, int>;
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
        content:
            const Text('Kamu perlu login lagi untuk masuk ke FOODIE.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Keluar', style: TextStyle(color: AppColors.red)),
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
    final email = currentUser?.email ??
        (widget.name.isNotEmpty
            ? '${widget.name.toLowerCase().replaceAll(' ', '.')}@culinary.id'
            : 'kurator@foodie.id');
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.orange))
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
                    const SizedBox(height: 14),
                    _quizBanner(),
                    const SizedBox(height: 20),

                    // ── Riwayat Aktivitas ──
                    _sectionLabel('RIWAYAT AKTIVITAS'),
                    const SizedBox(height: 8),
                    _historySection(),
                    const SizedBox(height: 20),

                    _sectionLabel('AKTIVITAS KULINER'),
                    const SizedBox(height: 8),
                    _group([
                      _tile(
                        Icons.favorite_border,
                        'Favorit & Koleksi',
                        trailing: '${_stats['favorites']}',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FavoritesPage()),
                        ),
                      ),
                      _tile(
                        Icons.emoji_events_rounded,
                        'Pencapaian & Poin',
                        trailing: '${_profile?.points ?? 0} Poin',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AchievementsPage()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('UTILITAS WISATAWAN'),
                    const SizedBox(height: 8),
                    _group([
                      _tile(
                        Icons.currency_exchange,
                        'Konverter Kurs & Zona Waktu',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ConverterPage()),
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
                      _tile(Icons.map_rounded, 'Cakupan Wilayah',
                          trailing: 'DIY & Jateng',
                          onTap: _showCoverageDialog),
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

  Widget _historySection() {
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
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1)),
            ),
            child: TabBar(
              controller: _histTab,
              labelColor: AppColors.charcoal,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.orange,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Pencarian'),
                Tab(text: 'Ulasan Saya'),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: _histLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.orange))
                : TabBarView(
                    controller: _histTab,
                    children: [
                      _searchHistoryTab(),
                      _reviewsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchHistoryTab() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: AppColors.line),
            SizedBox(height: 8),
            Text(
              'Belum ada riwayat pencarian',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        // header hapus semua
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchHistory.length} pencarian',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              GestureDetector(
                onTap: () async {
                  await SupabaseService.instance.clearSearchHistory();
                  setState(() => _searchHistory = []);
                },
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _searchHistory.length,
            itemBuilder: (_, i) {
              final item = _searchHistory[i];
              final q = item['query'] as String? ?? '';
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.history_rounded,
                      size: 18, color: AppColors.textMuted),
                  title: Text(
                    q,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textDark),
                  ),
                  trailing: GestureDetector(
                    onTap: () async {
                      await SupabaseService.instance.removeSearchItem(q);
                      setState(() =>
                          _searchHistory.removeWhere((e) => e['query'] == q));
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reviewsTab() {
    if (_myReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_rounded,
                size: 32, color: AppColors.line),
            SizedBox(height: 8),
            Text(
              'Belum ada ulasan',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            SizedBox(height: 4),
            Text(
              'Kunjungi restoran dan tulis ulasan pertamamu!',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _myReviews.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 52,
        color: AppColors.line.withValues(alpha: 0.5),
      ),
      itemBuilder: (_, i) {
        final rev = _myReviews[i];
        return Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_rounded,
                size: 18, color: AppColors.orange),
          ),
          title: Text(
            rev.restaurantName ?? rev.restaurantId,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (j) => Icon(
                    j < rev.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 12,
                    color: AppColors.orange,
                  ),
                ),
              ),
              Text(
                rev.comment,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () async {
            final resto = await SupabaseService.instance
                .getRestaurant(rev.restaurantId);
            if (resto != null && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DetailPage(restaurant: resto)),
              );
            }
          },
        ),
      );
      },
    );
  }

  Widget _aiPersonaCard() {
    final p = _aiProfile;
    final bool isComplete = p != null && p.isCompleted;
    final int progress = p?.completionPercentage ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiProfilePage()),
        );
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AvatarImage(
                    url: _profile?.avatarUrl,
                    size: 56,
                    fallbackText: name.isNotEmpty ? name : 'F',
                  ),
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
                    child: const Icon(Icons.edit_rounded,
                        size: 10, color: Colors.white),
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profile != null
                        ? 'Level ${_profile!.curatorLevel}: ${_profile!.levelTitle}'
                        : 'Kurator Yogyakarta',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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
          Icon(Icons.celebration_rounded,
              size: 20, color: AppColors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akun berhasil dibuat! Lengkapi profilmu agar rekomendasi makin pas.',
              style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _stat('${_stats['favorites']}', 'Favorit'),
        const SizedBox(width: 12),
        _stat('${_stats['reviews']}', 'Ulasan'),
      ],
    );
  }

  Widget _quizBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GamePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Tebak Kuliner',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mainkan tantangan kuis kuliner harian',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: AppText.display(20)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted),
            ),
          ],
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
              color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
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

  Widget _tile(IconData icon, String title,
      {String? trailing, VoidCallback? onTap}) {
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
              color: AppColors.greenDark),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
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
              color: AppColors.greenDark),
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
