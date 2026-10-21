import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/profile.dart';
import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/decide.dart';

/// Tab "Home": sapaan, Curated Shake, GPS widget, kategori, dan Rekomendasi Terdekat (LBS).
class HomeTab extends StatefulWidget {
  final String name;

  /// Pindah ke tab Explore (dipakai "Lihat semua").
  final VoidCallback? onSeeAll;

  /// Tap kategori → pindah ke Explore dengan filter kategori.
  final void Function(String category)? onCategorySelected;

  /// Buka detail restoran langsung dari Home.
  final void Function(Restaurant)? onOpenRestaurant;

  const HomeTab({
    super.key,
    required this.name,
    this.onSeeAll,
    this.onCategorySelected,
    this.onOpenRestaurant,
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

  // ── GPS State ──
  double? _lat;
  double? _lng;
  String _address = 'Mencari lokasi...';
  bool _locLoading = true;

  // Nominatim (OpenStreetMap) — gratis, tanpa API key
  // Wajib kirim User-Agent sesuai policy Nominatim
  static const _nominatimUserAgent = 'MoBagus-App/1.0 (flutter_application_1)';

  @override
  void initState() {
    super.initState();
    _load();
    _fetchLocation();
    _profileSub = _svc.onProfileChanged.listen((_) => _load());
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Haversine: hitung jarak dalam meter antara 2 koordinat ──
  double _distanceM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<void> _fetchLocation() async {
    setState(() => _locLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _address = 'Layanan lokasi nonaktif'; _locLoading = false; });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) setState(() { _address = 'Izin lokasi ditolak'; _locLoading = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locLoading = false;
      });

      // Panggil Google Geocoding API untuk dapat nama alamat
      await _reverseGeocode(pos.latitude, pos.longitude);

      // Setelah dapat lokasi, re-sort picks berdasarkan jarak
      _sortPicksByDistance();
    } catch (e) {
      if (mounted) setState(() { _address = 'Lokasi tidak tersedia'; _locLoading = false; });
    }
  }

  /// Reverse geocoding pakai Nominatim (OpenStreetMap) — gratis, no API key.
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json',
      );
      final res = await http.get(url, headers: {
        // Wajib sesuai policy Nominatim: https://operations.osmfoundation.org/policies/nominatim/
        'User-Agent': _nominatimUserAgent,
        'Accept-Language': 'id', // respons dalam Bahasa Indonesia
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>?;

        if (addr != null) {
          // Susun alamat pendek: jalan + kelurahan/desa + kota
          final parts = <String>[
            addr['road'] ?? addr['pedestrian'] ?? addr['neighbourhood'] ?? '',
            addr['suburb'] ?? addr['village'] ?? addr['hamlet'] ?? '',
            addr['city'] ?? addr['town'] ?? addr['county'] ?? '',
          ].where((s) => s.isNotEmpty).toList();

          final short = parts.take(2).join(', ');
          if (mounted && short.isNotEmpty) {
            setState(() => _address = short);
            return;
          }
        }

        // Fallback ke display_name jika address field kosong
        final displayName = json['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty && mounted) {
          final short = displayName.split(',').take(2).join(',').trim();
          setState(() => _address = short.isNotEmpty ? short : displayName);
          return;
        }
      }
    } catch (_) {}

    // Fallback terakhir: tampilkan koordinat
    if (mounted) {
      setState(() => _address = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}');
    }
  }

  void _sortPicksByDistance() {
    if (_lat == null || _lng == null || _picks.isEmpty) return;
    final lat = _lat!;
    final lng = _lng!;
    final sorted = List<Restaurant>.from(_picks)
      ..sort((a, b) {
        final dA = _distanceM(lat, lng, a.lat, a.lng);
        final dB = _distanceM(lat, lng, b.lat, b.lng);
        return dA.compareTo(dB);
      });
    if (mounted) setState(() => _picks = sorted);
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _svc.getProfile(),
      _svc.getRestaurants(),
      _svc.getCategories(),
    ]);
    var restos = List<Restaurant>.of(results[1] as List<Restaurant>);

    // Jika sudah ada koordinat pengguna → sort by jarak (LBS)
    if (_lat != null && _lng != null) {
      final lat = _lat!;
      final lng = _lng!;
      restos.sort((a, b) {
        final dA = _distanceM(lat, lng, a.lat, a.lng);
        final dB = _distanceM(lat, lng, b.lat, b.lng);
        return dA.compareTo(dB);
      });
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
    final s = c.toLowerCase();
    if (s.contains('fast')) return Icons.fastfood_rounded;
    if (s.contains('cafe') || s.contains('kafe') || s.contains('kopi')) {
      return Icons.local_cafe_rounded;
    }
    if (s.contains('court')) return Icons.storefront_rounded;
    if (s.contains('resto')) return Icons.restaurant_rounded;
    if (s.contains('bakery') || s.contains('roti')) {
      return Icons.bakery_dining_rounded;
    }
    if (s.contains('jajan') || s.contains('dessert')) {
      return Icons.icecream_rounded;
    }
    if (s.contains('lain')) return Icons.apps_rounded;
    return Icons.ramen_dining_rounded;
  }

  /// Format jarak ke string yang mudah dibaca
  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
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
            await _fetchLocation();
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

  // ---------- GPS Widget ----------
  Widget _gpsWidget() {
    return GestureDetector(
      onTap: () async {
        // Tap untuk refresh lokasi
        setState(() => _locLoading = true);
        await _fetchLocation();
        await _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _locLoading
                    ? AppColors.tint(AppColors.orange, 0.1)
                    : (_lat != null
                        ? AppColors.tint(AppColors.greenDark, 0.12)
                        : AppColors.tint(AppColors.red, 0.1)),
                shape: BoxShape.circle,
              ),
              child: _locLoading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange,
                      ),
                    )
                  : Icon(
                      _lat != null
                          ? Icons.my_location_rounded
                          : Icons.location_off_rounded,
                      size: 20,
                      color: _lat != null ? AppColors.greenDark : AppColors.red,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi Kamu Sekarang',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  if (_lat != null && _lng != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.textMuted,
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
                    c,
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
    if (_lat != null && _lng != null && (r.lat != 0 || r.lng != 0)) {
      final dist = _distanceM(_lat!, _lng!, r.lat, r.lng);
      distLabel = _formatDistance(dist);
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
