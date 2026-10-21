import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/profile.dart';
import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../widgets/decide.dart';
import 'notifications_page.dart';

/// Tab "Home": sapaan, Curated Shake, GPS widget, kategori, dan Rekomendasi Terdekat (LBS).
class HomeTab extends StatefulWidget {
  final String name;

  /// Pindah ke tab Explore (dipakai "Lihat semua").
  final VoidCallback? onSeeAll;

  /// Tap kategori → pindah ke Explore dengan filter kategori.
  final void Function(String category)? onCategorySelected;

  /// Buka detail restoran langsung dari Home.
  final void Function(Restaurant)? onOpenRestaurant;

  /// Dipanggil saat koordinat GPS berhasil didapat → dipakai Explore untuk sort terdekat.
  final void Function(double lat, double lng)? onLocationFetched;

  const HomeTab({
    super.key,
    required this.name,
    this.onSeeAll,
    this.onCategorySelected,
    this.onOpenRestaurant,
    this.onLocationFetched,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _svc = SupabaseService.instance;
  final _pageCtrl = PageController(viewportFraction: 0.9);

  Profile? _profile;
  List<Restaurant> _picks = [];       // Rekomendasi terdekat (LBS)
  List<String> _categories = [];
  bool _loading = true;
  int _page = 0;
  StreamSubscription<void>? _profileSub;

  @override
  void initState() {
    super.initState();
    LocationService.instance.currentLocation.addListener(_onLocationUpdated);
    LocationService.instance.isLoading.addListener(_onLocationLoadingChanged);
    _load();
    // Auto-detect lokasi GPS pengguna saat aplikasi dibuka
    LocationService.instance.fetchGpsLocation();
    _profileSub = _svc.onProfileChanged.listen((_) => _load());
  }

  void _onLocationUpdated() {
    if (!mounted) return;
    final loc = LocationService.instance.currentLocation.value;
    if (loc != null) {
      widget.onLocationFetched?.call(loc.lat, loc.lng);
    }
    _load();
  }

  void _onLocationLoadingChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LocationService.instance.currentLocation.removeListener(_onLocationUpdated);
    LocationService.instance.isLoading.removeListener(_onLocationLoadingChanged);
    _profileSub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _svc.getProfile(),
      _svc.getRestaurants(),
      _svc.getCategories(),
    ]);
    var restos = List<Restaurant>.of(results[1] as List<Restaurant>);

    final loc = LocationService.instance.currentLocation.value;
    // Jika sudah ada koordinat pengguna → sort by jarak terdekat (LBS)
    if (loc != null && (loc.lat != 0 || loc.lng != 0)) {
      final lat = loc.lat;
      final lng = loc.lng;
      restos.sort((a, b) {
        final dA = LocationService.instance.distanceM(lat, lng, a.lat, a.lng);
        final dB = LocationService.instance.distanceM(lat, lng, b.lat, b.lng);
        return dA.compareTo(dB);
      });
      widget.onLocationFetched?.call(lat, lng);
    } else {
      // Fallback: sort by rating jika lokasi belum tersedia
      restos.sort((a, b) => b.rating.compareTo(a.rating));
    }

    if (!mounted) return;
    setState(() {
      _profile = results[0] as Profile?;
      _picks = restos.take(5).toList();
      _categories = results[2] as List<String>;
      _loading = false;
    });
  }

  void _open(Restaurant r) {
    if (widget.onOpenRestaurant != null) {
      widget.onOpenRestaurant!(r);
    } else {
      widget.onSeeAll?.call();
    }
  }

  IconData _iconFor(String c) {
    // Normalisasi: lowercase + ganti underscore/tanda hubung → spasi
    final s = c.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    // fast_food / fast food / cepat saji
    if (s.contains('fast food') || s.contains('fastfood') || s.contains('fast') || s.contains('cepat')) {
      return Icons.fastfood_rounded;
    }
    // food_court / food court / sentra kuliner
    if (s.contains('food court') || s.contains('foodcourt') || s.contains('court') || s.contains('sentra')) {
      return Icons.storefront_rounded;
    }
    // cafe / kafe / coffee / kopi / minuman
    if (s.contains('cafe') || s.contains('kafe') || s.contains('coffee') ||
        s.contains('kopi') || s.contains('minuman')) {
      return Icons.local_cafe_rounded;
    }
    // restoran / restaurant / warung / rumah makan
    if (s.contains('resto') || s.contains('restaurant') || s.contains('warung') ||
        s.contains('rumah makan')) {
      return Icons.restaurant_rounded;
    }
    // bakery / roti / bakpia
    if (s.contains('bakery') || s.contains('roti') || s.contains('bakpia')) {
      return Icons.bakery_dining_rounded;
    }
    // dessert / jajan / es / jus
    if (s.contains('jajan') || s.contains('dessert') || s.contains('jus') || s.contains(' es ')) {
      return Icons.icecream_rounded;
    }
    return Icons.ramen_dining_rounded;
  }

  /// Format label kategori agar rapi (misal fast_food -> Fast Food)
  String _formatCategoryLabel(String c) {
    final lower = c.trim().toLowerCase();
    if (lower == 'fast_food') return 'Fast Food';
    if (lower == 'food_court') return 'Food Court';
    if (lower == 'cafe') return 'Cafe';
    if (lower == 'restoran') return 'Restoran';
    return c.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (_profile?.displayName ?? widget.name).trim();
    final first = fullName.isEmpty ? 'Foodie' : fullName.split(' ').first;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async {
            await LocationService.instance.fetchGpsLocation();
            await _load();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _header(first),
              const SizedBox(height: 22),
              _shakeCard(),
              const SizedBox(height: 22),
              // ── GPS / Lokasi Widget ──
              _gpsWidget(),
              const SizedBox(height: 22),
              if (_categories.isNotEmpty) ...[
                Text('Kategori Kuliner', style: AppText.display(20)),
                const SizedBox(height: 12),
                _categoryRow(),
                const SizedBox(height: 26),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terdekat dari Lokasimu', style: AppText.display(20)),
                        Text(
                          'Kuliner paling dekat dengan kamu saat ini',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onSeeAll,
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _nearbyCarousel(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _header(String first) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text('Sugeng Rawuh, $first', style: AppText.display(26)),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: HiveService.instance.settingsListenable,
              builder: (_, _, _) {
                final bool hasBadge =
                    HiveService.instance.getActiveRemindersCount() > 0;
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: AppColors.charcoal,
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.orange, 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 12,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${_profile?.points ?? 0}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Curated Shake ----------
  Widget _shakeCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bingung mau\nmakan apa?',
                      style: AppText.display(24)
                          .copyWith(color: Colors.white, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Goyangkan HP-mu dan biarkan FOODIE\nmerekomendasikan kuliner terbaik.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () =>
                          showDecideSheet(context).then((_) => _load()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.casino_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Shake to Decide',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
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
              const SizedBox(width: 10),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.yellow.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 30,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- GPS & Location Widget ----------
  void _showLocationPickerSheet() {
    final locSvc = LocationService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final isGpsLoading = locSvc.isLoading.value;
          final currentLoc = locSvc.currentLocation.value;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
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
                        color: AppColors.tint(AppColors.orange, 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pilih Titik Lokasi Kamu', style: AppText.display(18)),
                          const SizedBox(height: 2),
                          const Text(
                            'Rekomendasi terdekat dihitung dari titik ini',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Tombol GPS Otomatis ──
                InkWell(
                  onTap: isGpsLoading
                      ? null
                      : () async {
                          setModal(() {});
                          final ok = await locSvc.fetchGpsLocation();
                          if (!ctx.mounted) return;
                          setModal(() {});
                          if (ok) {
                            Navigator.pop(ctx);
                            _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lokasi GPS berhasil diperbarui: ${locSvc.currentLocation.value?.address ?? ''} 📍',
                                  ),
                                  backgroundColor: AppColors.greenDark,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            final msg = locSvc.statusMessage.value ?? 'Gagal mengakses GPS';
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: AppColors.charcoal,
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'Pengaturan',
                                    textColor: AppColors.yellow,
                                    onPressed: () => Geolocator.openAppSettings(),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (currentLoc?.isGps ?? false)
                          ? AppColors.tint(AppColors.greenDark, 0.08)
                          : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (currentLoc?.isGps ?? false)
                            ? AppColors.greenDark
                            : AppColors.line,
                        width: (currentLoc?.isGps ?? false) ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isGpsLoading
                                ? AppColors.tint(AppColors.orange, 0.15)
                                : ((currentLoc?.isGps ?? false)
                                    ? AppColors.greenDark
                                    : Colors.white),
                            shape: BoxShape.circle,
                          ),
                          child: isGpsLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.orange,
                                  ),
                                )
                              : Icon(
                                  Icons.my_location_rounded,
                                  size: 20,
                                  color: (currentLoc?.isGps ?? false)
                                      ? Colors.white
                                      : AppColors.charcoal,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Gunakan Lokasi GPS Saya',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (currentLoc?.isGps ?? false) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.greenDark,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'AKTIF',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGpsLoading
                                    ? (locSvc.statusMessage.value ?? 'Mencari koordinat GPS...')
                                    : ((currentLoc?.isGps ?? false)
                                        ? currentLoc!.address
                                        : 'Deteksi koordinat posisi ponsel saat ini'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'ATAU PILIH WILAYAH KULINER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Daftar Preset Wilayah ──
                ...LocationService.presetRegions.map((reg) {
                  final name = reg['name'] as String;
                  final desc = reg['desc'] as String;
                  final city = reg['city'] as String;
                  final lat = reg['lat'] as double;
                  final lng = reg['lng'] as double;

                  final isSelected = !(currentLoc?.isGps ?? true) &&
                      (currentLoc?.city == city ||
                          currentLoc?.address.contains(name) == true);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await locSvc.setManualLocation(
                          name: name,
                          address: '$name, $desc',
                          city: city,
                          lat: lat,
                          lng: lng,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lokasi aktif diatur ke $name ✨'),
                              backgroundColor: AppColors.greenDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.tint(AppColors.orange, 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.orange : AppColors.line,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.place_outlined,
                              size: 20,
                              color: isSelected
                                  ? AppColors.orange
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.orange
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _gpsWidget() {
    final loc = LocationService.instance.currentLocation.value;
    final isLoading = LocationService.instance.isLoading.value;

    final displayAddr = loc?.address ?? 'Pusat Kota Yogyakarta';
    final isGps = loc?.isGps ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showLocationPickerSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isGps
                ? AppColors.tint(AppColors.greenDark, 0.4)
                : AppColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.tint(AppColors.orange, 0.12)
                    : (isGps
                        ? AppColors.tint(AppColors.greenDark, 0.12)
                        : AppColors.tint(AppColors.orange, 0.1)),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange,
                      ),
                    )
                  : Icon(
                      isGps
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                      size: 20,
                      color: isGps ? AppColors.greenDark : AppColors.orange,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lokasi Kuliner Terdekat',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isGps
                              ? AppColors.tint(AppColors.greenDark, 0.15)
                              : AppColors.tint(AppColors.orange, 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isGps ? 'GPS AKTIF' : 'WILAYAH',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: isGps ? AppColors.greenDark : AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayAddr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Ketuk untuk ubah lokasi atau GPS',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.charcoal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kategori ----------
  Widget _categoryRow() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = _categories[i];
          return GestureDetector(
            // Tap kategori → filter di Explore
            onTap: () {
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!(c);
              } else {
                widget.onSeeAll?.call();
              }
            },
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Icon(
                      _iconFor(c),
                      size: 27,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _formatCategoryLabel(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Nearby Carousel (LBS) ----------
  Widget _nearbyCarousel() {
    if (_loading) {
      return const SizedBox(
        height: 230,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }
    if (_picks.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Belum ada rekomendasi.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _pageCtrl,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: _picks.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _nearbyCard(_picks[i]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _picks.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.orange : AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nearbyCard(Restaurant r) {
    final img = (r.imageUrl?.isEmpty ?? true) ? null : r.imageUrl;

    // Hitung jarak jika koordinat tersedia
    String? distLabel;
    final loc = LocationService.instance.currentLocation.value;
    if (loc != null && (r.lat != 0 || r.lng != 0)) {
      final dist = LocationService.instance.distanceM(loc.lat, loc.lng, r.lat, r.lng);
      distLabel = LocationService.instance.formatDistance(dist);
    }

    return GestureDetector(
      onTap: () => _open(r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (img != null)
              Image.network(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _cardFallback(),
              )
            else
              _cardFallback(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge "TERDEKAT"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 9, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              distLabel != null
                                  ? 'TERDEKAT • $distLabel'
                                  : 'TERDEKAT',
                              style: const TextStyle(
                                fontSize: 8.5,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8.5,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(22).copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.yellow,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        r.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        r.reviewCount > 0
                            ? '(${r.reviewCount} ulasan)'
                            : '(Baru)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          r.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.priceRange,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.yellow,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Lihat Detail →',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoal, AppColors.tint(AppColors.orange, 0.5)],
        ),
      ),
      alignment: Alignment.topRight,
      padding: const EdgeInsets.all(26),
      child: Icon(
        Icons.ramen_dining_rounded,
        size: 46,
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
  }
}
