import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/decide.dart';
import 'detail_page.dart';
import 'explore_tab.dart';
import 'notifications_page.dart';

class HomeTab extends StatefulWidget {
  final String name;
  const HomeTab({super.key, required this.name});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Restaurant> _restaurants = [];
  List<String> _categories = [];
  bool _loading = true;

  // Koordinat pengguna (bisa null jika izin ditolak / belum dapat)
  double? _userLat;
  double? _userLng;
  String _locationName = 'Mencari lokasi...';
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Muat data restoran + kategori
      final results = await Future.wait([
        SupabaseService.instance.getRestaurants(),
        SupabaseService.instance.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _restaurants = results[0] as List<Restaurant>;
        _categories = results[1] as List<String>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }

    // Dapatkan lokasi secara terpisah (tidak bloking UI)
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationName = 'Jl. Malioboro, Danurejan, Yogyakarta (Default)';
          _fetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _locationName = 'Jl. Malioboro, Danurejan, Yogyakarta (Default)';
            _fetchingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationName = 'Yogyakarta (Izin GPS dinonaktifkan)';
          _fetchingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      String placeLabel = await _reverseGeocode(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationName = placeLabel;
        _fetchingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationName = 'Jl. Malioboro, Danurejan, Yogyakarta (Default)';
        _fetchingLocation = false;
      });
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    // Estimasi area & nama jalan lokal Yogyakarta/Jateng berdasarkan kedekatan
    if (_restaurants.isNotEmpty) {
      final closest = [..._restaurants]
        ..sort((a, b) => _haversine(lat, lng, a.lat, a.lng).compareTo(_haversine(lat, lng, b.lat, b.lng)));
      final top = closest.first;
      final dist = _haversine(lat, lng, top.lat, top.lng);
      if (dist < 1.5) {
        return 'Sekitar ${top.address.split(',').first} (${top.province})';
      }
    }

    // Klasifikasi wilayah DIY berdasarkan koordinat lintang/bujur
    if (lat > -7.77) {
      return 'Sleman, D.I. Yogyakarta (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
    } else if (lat < -7.83) {
      return 'Bantul, D.I. Yogyakarta (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
    } else if (lng > 110.42) {
      return 'Yogyakarta Bagian Timur (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
    } else {
      return 'Pusat Kota Yogyakarta (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
    }
  }

  /// Hitung jarak (km) antara user dan restoran menggunakan Haversine
  double _distanceTo(Restaurant r) {
    if (_userLat == null || _userLng == null) {
      // Jika belum ada lokasi, gunakan koordinat pusat Jogja sebagai fallback
      const jogjaCenterLat = -7.7956;
      const jogjaCenterLng = 110.3695;
      return _haversine(jogjaCenterLat, jogjaCenterLng, r.lat, r.lng);
    }
    return _haversine(_userLat!, _userLng!, r.lat, r.lng);
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  /// 4 restoran terdekat dari lokasi pengguna
  List<Restaurant> get _nearbyRestaurants {
    if (_restaurants.isEmpty) return [];
    final sorted = [..._restaurants]
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return sorted.take(4).toList();
  }

  /// 4 restoran termurah + terdekat
  List<Restaurant> get _budgetRestaurants {
    if (_restaurants.isEmpty) return [];
    final budget = _restaurants.where((r) => r.priceMin <= 25000).toList()
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return budget.take(4).toList();
  }

  /// Restoran rekomendasi = rating tertinggi (unused field, computed in widget)
  Restaurant? get _featuredRestaurant {
    if (_restaurants.isEmpty) return null;
    return _restaurants.reduce((a, b) => a.rating >= b.rating ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    // Ambil hanya first name
    final first = widget.name.trim().isEmpty
        ? 'Foodie'
        : widget.name.trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange))
            : RefreshIndicator(
                color: AppColors.orange,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // 1. Greeting: "Sugeng rawuh, [username]" saja
                    _greetingRow(first),
                    const SizedBox(height: 14),
                    _searchBar(),
                    const SizedBox(height: 18),
                    _shakeBanner(),
                    const SizedBox(height: 22),

                    // 1. Kategori Kuliner
                    if (_categories.isNotEmpty) ...[
                      _sectionHeader('Kategori Kuliner'),
                      const SizedBox(height: 12),
                      _categoryRow(),
                      const SizedBox(height: 22),
                    ],

                    // 2. Bar Lokasi Anda Saat Ini
                    _currentLocationWidget(),
                    const SizedBox(height: 16),

                    // 3. Rekomendasi Berdasarkan Lokasi Anda
                    _sectionHeader(
                      'Rekomendasi di Sekitarmu',
                      action: 'Lihat Semua',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExploreTab(name: widget.name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_userLat == null && _userLng == null)
                      _locationPermissionBanner(),
                    if (_nearbyRestaurants.isEmpty)
                      _emptySection()
                    else
                      ..._nearbyRestaurants.map((r) => _restaurantCard(r)),
                    const SizedBox(height: 22),

                    // 4. Rekomendasi Kuliner Terpopuler / Pilihan
                    if (_restaurants.isNotEmpty) ...[
                      _sectionHeader('Kuliner Terpopuler'),
                      const SizedBox(height: 12),
                      _featuredCardWidget(),
                      const SizedBox(height: 22),
                    ],

                    // 5. Hemat & Nikmat — sort by nearby
                    _sectionHeader(
                      'Hemat & Nikmat (< Rp25rb)',
                      action: 'Lihat Semua',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExploreTab(
                            name: widget.name,
                            initialBudget: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_budgetRestaurants.isEmpty)
                      _emptySection()
                    else
                      ..._budgetRestaurants.map((r) => _restaurantCard(r)),
                    const SizedBox(height: 12),
                    // 2. Card Warisan Kuliner Mataram DIHAPUS
                  ],
                ),
              ),
      ),
    );
  }

  // ─── 1. Greeting row — hanya "Sugeng rawuh, username" ───
  Widget _greetingRow(String first) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hapus tulisan "SELAMAT DATANG DI YOGYAKARTA"
              Text(
                'Sugeng rawuh, $first 👋',
                style: AppText.display(22),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ExploreTab(name: widget.name)),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, size: 21, color: AppColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari gudeg, bakpia, bakmi jawa...',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shakeBanner() {
    return GestureDetector(
      onTap: () => showDecideSheet(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CURATED SHAKE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.saffron,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bingung mau\nmakan apa?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Goyangkan HP-mu dan biarkan FOODIE merekomendasikan kuliner terbaik.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.paprika,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 7),
                        Text(
                          'Shake to Decide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.saffron.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 30,
                color: AppColors.saffron,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? action, VoidCallback? onAction}) {
    return SectionHeader(
      title: title,
      actionLabel: action,
      onAction: onAction,
    );
  }

  // ─── Icons per kategori ───
  static const _catIcons = <String, IconData>{
    'Gudeg': Icons.rice_bowl,
    'Soto': Icons.soup_kitchen,
    'Kuliner Pedas': Icons.local_fire_department,
    'Angkringan': Icons.local_cafe,
    'Bakmi Jawa': Icons.ramen_dining,
    'Sate': Icons.kebab_dining,
    'Nasi Goreng': Icons.dinner_dining,
    'Minuman Tradisional': Icons.local_drink,
    'Kuliner Tradisional': Icons.restaurant,
  };

  // ─── 3. Kategori Kuliner — fix: navigasi ke ExploreTab dengan initialCategory ───
  Widget _categoryRow() {
    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          return Padding(
            padding:
                EdgeInsets.only(right: i < _categories.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExploreTab(
                      name: widget.name,
                      initialCategory: cat,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.line.withValues(alpha: 0.8),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _catIcons[cat] ?? Icons.restaurant,
                      size: 24,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      cat,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
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

  // ─── Banner Posisi Lokasi Pengguna ───
  Widget _currentLocationWidget() {
    final hasLocation = _userLat != null && _userLng != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation ? AppColors.green.withValues(alpha: 0.4) : AppColors.line,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (hasLocation ? AppColors.green : AppColors.orange).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasLocation ? Icons.my_location_rounded : Icons.location_on_outlined,
              size: 19,
              color: hasLocation ? AppColors.green : AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'POSISI ANDA SAAT INI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fetchingLocation ? 'Sedang memperbarui koordinat GPS...' : _locationName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _fetchingLocation ? null : _fetchLocation,
            icon: _fetchingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                  )
                : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.orange),
            tooltip: 'Perbarui Lokasi',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── 5. Rekomendasi (bukan "Pilihan Editor") — rating tertinggi ───
  Widget _featuredCardWidget() {
    final sorted = [..._restaurants]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (sorted.isEmpty) return const SizedBox.shrink();
    final r = sorted.first;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              FoodImage(
                imageUrl: r.imageUrl,
                width: double.infinity,
                height: 200,
                icon: Icons.rice_bowl,
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.charcoal.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.saffron,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'REKOMENDASI',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.saffron),
                          const SizedBox(width: 3),
                          Text(
                            r.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            ' (${_fmtCount(r.reviewCount)} ulasan)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            r.priceRange,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.saffron,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.paprika,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Lihat Detail →',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Banner jika izin lokasi belum diberikan ───
  Widget _locationPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.orange, 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.tint(AppColors.orange, 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined,
              size: 20, color: AppColors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Aktifkan lokasi untuk melihat kuliner terdekat dari posisimu.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _fetchLocation,
            child: const Text(
              'Aktifkan',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantCard(Restaurant r) {
    final dist = _distanceTo(r);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.line.withValues(alpha: 0.7), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: FoodImage(
                imageUrl: r.imageUrl,
                width: 70,
                height: 70,
                icon: _catIcons[r.category] ?? Icons.restaurant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: AppText.display(14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.saffron),
                      const SizedBox(width: 3),
                      Text(
                        r.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        ' · ${_fmtCount(r.reviewCount)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          r.address.split(',').first,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.line.withValues(alpha: 0.8),
                        width: 0.8),
                  ),
                  child: Text(
                    r.priceRange,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Jarak dari lokasi pengguna
                Text(
                  '${dist.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                _openStatus(r),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _openStatus(Restaurant r) {
    final hours = r.openingHours ?? '';
    final now = TimeOfDay.now();
    bool isOpen = true;
    if (hours.contains(' - ')) {
      try {
        final parts = hours.split(' - ');
        final open = _parseTime(parts[0]);
        final close = _parseTime(
            parts[1].replaceAll(' WIB', '').trim());
        if (open != null && close != null) {
          final nowMins = now.hour * 60 + now.minute;
          final openMins = open.hour * 60 + open.minute;
          final closeMins = close.hour * 60 + close.minute;
          if (closeMins < openMins) {
            isOpen = nowMins >= openMins || nowMins <= closeMins;
          } else {
            isOpen = nowMins >= openMins && nowMins <= closeMins;
          }
        }
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.green.withValues(alpha: 0.12)
            : AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Buka' : 'Tutup',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isOpen ? AppColors.green : AppColors.red,
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String s) {
    try {
      final parts = s.trim().split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Widget _emptySection() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'Belum ada data',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
