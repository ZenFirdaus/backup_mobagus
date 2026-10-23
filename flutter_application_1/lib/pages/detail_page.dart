import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../models/food.dart';
import '../models/review.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import '../widgets/modern_time_picker.dart';

class DetailPage extends StatefulWidget {
  final Restaurant restaurant;

  const DetailPage({super.key, required this.restaurant});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Restaurant _r;
  bool _isFavorite = false;
  bool _hasReminder = false;
  late double _currentRating;
  late int _currentReviewCount;

  List<Food> _foods = [];
  bool _foodsLoading = true;
  String? _foodsError;
  List<Review> _reviews = [];
  bool _reviewsLoading = true;
  String? _reviewsError;

  StreamSubscription<Set<String>>? _favSub;
  StreamSubscription<String>? _reviewSub;
  StreamSubscription<Review>? _reviewAddedSub;

  @override
  void initState() {
    super.initState();
    _r = widget.restaurant;
    _currentRating = _r.rating;
    _currentReviewCount = _r.reviewCount;
    _checkFavorite();
    _checkReminder();
    _loadFoods();
    _loadReviews();
    _subscribeRealtime();
  }

  void _checkReminder() {
    final reminders = HiveService.instance.getAllVisitReminders();
    final has = reminders.any(
      (r) => r['restoId'] == _r.id && r['isCompleted'] != true,
    );
    if (mounted) setState(() => _hasReminder = has);
  }

  void _subscribeRealtime() {
    _favSub = SupabaseService.instance.favoritesStream.listen((favs) {
      if (!mounted) return;
      setState(() => _isFavorite = favs.contains(_r.id));
    });

    _reviewSub = SupabaseService.instance.onReviewsChanged.listen((restoId) {
      if (!mounted) return;
      if (restoId == _r.id || restoId.isEmpty) {
        _loadReviews();
      }
    });

    _reviewAddedSub = SupabaseService.instance.onReviewAdded.listen((rev) {
      if (!mounted) return;
      if (rev.restaurantId == _r.id) {
        setState(() {
          if (!_reviews.any((r) => r.id == rev.id)) {
            _reviews.insert(0, rev);
          }
          _updateRatingStats();
        });
      }
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _reviewSub?.cancel();
    _reviewAddedSub?.cancel();
    super.dispose();
  }

  void _updateRatingStats() {
    if (_reviews.isNotEmpty) {
      _currentReviewCount = _reviews.length;
      final totalStars = _reviews.fold<int>(0, (sum, r) => sum + r.rating);
      _currentRating = totalStars / _reviews.length;
    }
  }

  Future<void> _checkFavorite() async {
    final fav = await SupabaseService.instance.isFavorite(_r.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    await SupabaseService.instance.toggleFavorite(_r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Tersimpan ke favorit' : 'Dihapus dari favorit',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadFoods() async {
    setState(() {
      _foodsLoading = true;
      _foodsError = null;
    });
    try {
      final list = await SupabaseService.instance.getFoods(_r.id);
      if (mounted) setState(() => _foods = list);
    } catch (e) {
      if (mounted) setState(() => _foodsError = e.toString());
    } finally {
      if (mounted) setState(() => _foodsLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final list = await SupabaseService.instance.getReviews(_r.id);
      if (mounted) {
        setState(() {
          _reviews = list;
          _updateRatingStats();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _reviewsError = e.toString());
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  /// Buka Google Maps dengan koordinat restoran
  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_r.lat},${_r.lng}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: buka browser
        await launchUrl(
          Uri.parse('https://maps.google.com/?q=${_r.lat},${_r.lng}'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa membuka Maps untuk ${_r.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddReviewDialog() {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  color: AppColors.orange, size: 22),
              const SizedBox(width: 8),
              Text('Tulis Ulasan', style: AppText.display(18)),
              const Spacer(),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = i + 1),
                    child: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: AppColors.orange,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Bagikan pengalaman rasa Anda...',
                  filled: true,
                  fillColor: AppColors.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.orange, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (commentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final rev = await SupabaseService.instance.addReview(
                  restaurantId: _r.id,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                );
                if (mounted) {
                  setState(() {
                    if (!_reviews.any((r) => r.id == rev.id)) {
                      _reviews.insert(0, rev);
                    }
                    _updateRatingStats();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Ulasan berhasil ditambahkan (+20 Poin)'),
                      backgroundColor: AppColors.greenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareRestaurant() async {
    final text = 'Rekomendasi Kuliner:\n\n'
        '*${_r.name}*\n'
        'Kategori: ${_r.category}\n'
        'Rating: ${_r.rating.toStringAsFixed(1)} / 5.0\n'
        'Kisaran Harga: ${_r.priceRange}\n'
        'Alamat: ${_r.address}\n'
        'Buka di Google Maps: https://www.google.com/maps/search/?api=1&query=${_r.lat},${_r.lng}\n\n'
        'Ditemukan melalui aplikasi FOODIE.';

    try {
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      // ignore: deprecated_member_use
      await Share.share(
        text,
        subject: 'Rekomendasi Kuliner: ${_r.name}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      // Fallback: salin ke clipboard jika platform tidak memunculkan dialog native
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Informasi ${_r.name} berhasil disalin ke papan klip!'),
            backgroundColor: AppColors.greenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showScheduleReminderDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
    final noteCtrl = TextEditingController();

    // Cek apakah sudah ada jadwal tersimpan untuk resto ini di Hive
    final existingReminders = HiveService.instance.getAllVisitReminders();
    final existingIndex = existingReminders.indexWhere(
      (r) => r['restoId'] == _r.id && r['isCompleted'] != true,
    );
    final Map<String, dynamic>? existing =
        existingIndex != -1 ? existingReminders[existingIndex] : null;

    if (existing != null) {
      final parsed = DateTime.tryParse(existing['scheduledAt']?.toString() ?? '');
      if (parsed != null) {
        selectedDate = parsed;
        selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
      noteCtrl.text = existing['note']?.toString() ?? '';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dateStr =
              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
          final timeStr =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB';

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.orange, 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alarm_add_rounded,
                        color: AppColors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jadwal Kunjungan Kuliner',
                              style: AppText.display(17)),
                          Text(
                            _r.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tentukan Tanggal & Jam Santap:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.greenDark),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showModernTimePicker(
                            ctx,
                            initialTime: selectedTime,
                            title: 'Pilih Jam Kunjungan',
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.greenDark),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Catatan (misal: Santap bersama keluarga)...',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
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
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (existing != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final idStr = existing['id'].toString();
                            final intId = int.tryParse(idStr) ??
                                (_r.id.hashCode.abs() % 100000);
                            await HiveService.instance
                                .deleteVisitReminder(idStr);
                            await NotificationService.instance
                                .cancelNotification(intId);
                            _checkReminder();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jadwal pengingat dibatalkan'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Batalkan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18),
                        label: Text(
                          existing != null
                              ? 'Perbarui Jadwal'
                              : 'Pasang Pengingat',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final scheduledAt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (scheduledAt.isBefore(DateTime.now())) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Pilih tanggal dan jam di masa depan'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final notifId = _r.id.hashCode.abs() % 100000;
                          final idStr = notifId.toString();

                          await HiveService.instance.saveVisitReminder(
                            id: idStr,
                            restoId: _r.id,
                            restoName: _r.name,
                            restoAddress: _r.address,
                            scheduledAt: scheduledAt,
                            note: noteCtrl.text.trim(),
                          );

                          await NotificationService.instance
                              .scheduleVisitReminder(
                            id: notifId,
                            restoName: _r.name,
                            scheduledDate: scheduledAt,
                            note: noteCtrl.text.trim(),
                          );

                          _checkReminder();
                          if (ctx.mounted) Navigator.pop(ctx);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Pengingat berhasil diatur: ${_r.name} pada $dateStr $timeStr! 🔔',
                                ),
                                backgroundColor: AppColors.greenDark,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _imageHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _restaurantInfo(),
                      const SizedBox(height: 16),
                      _quickActions(),
                      const SizedBox(height: 20),
                      _mapPreviewSection(),
                      const SizedBox(height: 20),
                      _menuSection(),
                      const SizedBox(height: 20),
                      _reviewsSection(),
                    ]),
                  ),
                ),
              ],
            ),
            _topBar(),
            _bottomStickyBar(),
          ],
        ),
      ),
    );
  }

  // ── Image Header ──
  Widget _imageHeader() {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_r.imageUrl != null && _r.imageUrl!.isNotEmpty)
            Image.network(
              _r.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackImage(),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : _fallbackImage(),
            )
          else
            _fallbackImage(),
          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // Info di bawah gambar
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _r.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_r.openingHours != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(
                              _r.openingHours!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _r.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.yellow),
                    const SizedBox(width: 3),
                    Text(
                      _currentRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _currentReviewCount > 0
                          ? '  ($_currentReviewCount ulasan)'
                          : '  (Baru)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.greenDark, AppColors.tint(AppColors.orange, 0.6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 60,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ── Top Bar ──
  Widget _topBar() {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const Spacer(),
            _circleButton(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.red : AppColors.textDark,
              onTap: _toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.textDark),
      ),
    );
  }

  // ── Restaurant Info ──
  Widget _restaurantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_rounded,
                size: 15, color: AppColors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${_r.address} · ${_r.province}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.payments_rounded,
                size: 16, color: AppColors.greenDark),
            const SizedBox(width: 6),
            Text(
              _r.priceRange,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
            if (_r.phone != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('tel:${_r.phone}'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _r.phone!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (_r.description != null && _r.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _r.description!,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textDark,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }

  // ── Quick Actions (tanpa Check-in) ──
  Widget _quickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(
          Icons.map_rounded,
          'Peta',
          _openMaps,
          color: AppColors.greenDark,
        ),
        _actionButton(
          _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_rounded,
          _isFavorite ? 'Tersimpan' : 'Simpan',
          _toggleFavorite,
          color: _isFavorite ? AppColors.orange : AppColors.greenDark,
        ),
        _actionButton(
          _hasReminder ? Icons.alarm_on_rounded : Icons.add_alarm_rounded,
          _hasReminder ? 'Terjadwal' : 'Ingatkan',
          _showScheduleReminderDialog,
          color: _hasReminder ? AppColors.orange : AppColors.greenDark,
        ),
        _actionButton(
          Icons.rate_review_rounded,
          'Ulas',
          _showAddReviewDialog,
          color: AppColors.greenDark,
        ),
        _actionButton(
          Icons.share_rounded,
          'Bagikan',
          _shareRestaurant,
          color: AppColors.greenDark,
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: color ?? AppColors.greenDark),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Peta Google Maps Static Preview ──
  Widget _mapPreviewSection() {

    return GestureDetector(
      onTap: _openMaps,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header peta
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: 6),
                  Text('Lokasi', style: AppText.display(14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.greenDark, 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 12, color: AppColors.greenDark),
                        SizedBox(width: 4),
                        Text(
                          'Buka Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Peta static (jika API key tersedia, tampilkan gambar dari Google)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  // Background peta dengan warna
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFFE8F0E9),
                    child: Stack(
                      children: [
                        // Pola grid mirip peta
                        CustomPaint(
                          size: const Size(double.infinity, 160),
                          painter: _MapPatternPainter(),
                        ),
                        // Pin lokasi di tengah
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.red.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x15000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _r.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.charcoal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Overlay "Tap to view" di sudut
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ketuk untuk buka Google Maps',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info koordinat
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _r.address,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_r.lat.toStringAsFixed(4)}, ${_r.lng.toStringAsFixed(4)} · ${_r.province}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openMaps,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Rute',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu Section ──
  Widget _menuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 18, color: AppColors.charcoal),
            const SizedBox(width: 8),
            Expanded(child: Text('Menu Unggulan', style: AppText.display(16))),
          ],
        ),
        const SizedBox(height: 10),
        if (_foodsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          )
        else if (_foodsError != null)
          _errorTile(_foodsError!, _loadFoods)
        else if (_foods.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada menu yang terdaftar.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ..._foods.map(_foodTile),
      ],
    );
  }

  Widget _foodTile(Food f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: f.imageUrl != null && f.imageUrl!.isNotEmpty
                ? Image.network(
                    f.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _foodFallback(),
                  )
                : _foodFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (f.description != null && f.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    f.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.greenDark, 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        f.priceLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                    if (f.category != null && f.category!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        f.category!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodFallback() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.lunch_dining_rounded,
          size: 28, color: AppColors.textMuted),
    );
  }

  // ── Reviews Section ──
  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_rounded,
                size: 18, color: AppColors.charcoal),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Catatan Rasa Kurator', style: AppText.display(16)),
            ),
            GestureDetector(
              onTap: _showAddReviewDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.red, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '+ Tulis Ulasan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_reviewsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          )
        else if (_reviewsError != null)
          _errorTile(_reviewsError!, _loadReviews)
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_rounded,
                    size: 32, color: AppColors.line),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada ulasan untuk tempat ini.',
                  style:
                      TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jadilah kurator pertama yang berbagi pengalaman!',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._reviews.map(_reviewTile),
      ],
    );
  }

  Widget _reviewTile(Review r) {
    final colors = [
      AppColors.greenDark,
      AppColors.orange,
      AppColors.red,
      const Color(0xFF6C3483),
      const Color(0xFF1A5276),
    ];
    final colorIdx =
        (r.userName?.isNotEmpty == true ? r.userName![0].codeUnitAt(0) : 0) %
            colors.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors[colorIdx],
                child: Text(
                  (r.userName != null && r.userName!.isNotEmpty)
                      ? r.userName![0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName ?? 'Kurator Rasa',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _formatDate(r.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating bintang
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < r.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.orange,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r.comment,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _errorTile(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gagal memuat data.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sticky Bar ──
  Widget _bottomStickyBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: PrimaryButton(
          label: 'Lihat Lokasi di Google Maps',
          icon: Icons.map_rounded,
          onPressed: _openMaps,
        ),
      ),
    );
  }
}

// ── Custom painter untuk background peta ──
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = const Color(0xFFD5E8D6)
      ..style = PaintingStyle.fill;

    // Blok bangunan
    final blocks = [
      Rect.fromLTWH(10, 10, 80, 50),
      Rect.fromLTWH(120, 10, 60, 40),
      Rect.fromLTWH(220, 20, 90, 55),
      Rect.fromLTWH(350, 10, 70, 45),
      Rect.fromLTWH(460, 15, 80, 50),
      Rect.fromLTWH(10, 90, 65, 55),
      Rect.fromLTWH(130, 80, 75, 60),
      Rect.fromLTWH(250, 85, 85, 55),
      Rect.fromLTWH(380, 75, 70, 65),
      Rect.fromLTWH(490, 90, 60, 50),
    ];

    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(4)),
        blockPaint,
      );
    }

    // Jalan utama horizontal
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    // Jalan utama vertikal
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      roadPaint,
    );
    // Jalan minor
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), minorRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75), minorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), minorRoadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0),
        Offset(size.width * 0.75, size.height), minorRoadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
