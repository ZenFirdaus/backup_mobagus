import 'dart:async';

import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../models/seed_data.dart';
import '../utils/format.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../services/location_service.dart';
import '../widgets/auth_widgets.dart';
import 'detail_page.dart';
import 'notifications_page.dart';

enum _Sort { terdekat, nama, rating, termurah }

/// Format label kategori agar rapi (misal fast_food -> Fast Food)
String _formatCategoryLabel(String c) {
  final lower = c.trim().toLowerCase();
  if (lower == 'fast_food' || lower == 'fast food') return 'Fast Food';
  if (lower == 'food_court' || lower == 'food court') return 'Food Court';
  if (lower == 'cafe' || lower == 'kafe') return 'Cafe';
  if (lower == 'restoran' || lower == 'restaurant') return 'Restoran';
  if (lower == 'warung_tradisional' || lower == 'warung tradisional' || lower == 'warung') return 'Warung Tradisional';
  if (lower == 'angkringan') return 'Angkringan';
  return c.replaceAll('_', ' ').split(' ').map((w) {
    if (w.isEmpty) return '';
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

/// Tab "Explore": data dari Supabase (fallback seed jika kosong/offline).
class ExploreTab extends StatefulWidget {
  final String name;
  /// Kategori awal yang dipilih (dari Home).
  final String? initialCategory;
  /// Koordinat user untuk sort terdekat (dikirim dari HomePage).
  final double? userLat;
  final double? userLng;
  const ExploreTab({super.key, this.name = '', this.initialCategory, this.userLat, this.userLng});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _svc = SupabaseService.instance;
  final _search = TextEditingController();
  Timer? _debounce;

  List<Restaurant> _items = [];
  List<String> _categories = List.from(kDefaultCategories);
  Set<String> _favs = {};
  String? _category;
  String? _selectedCity; // Filter kota/wilayah: null = Semua
  bool _budgetOn = false;
  bool _loading = true;
  _Sort _sort = _Sort.terdekat; // default: terdekat dari lokasi user

  static const _sortLabels = {
    _Sort.terdekat: 'Terdekat',
    _Sort.nama: 'Nama A-Z',
    _Sort.rating: 'Rating',
    _Sort.termurah: 'Termurah',
  };

  StreamSubscription<Set<String>>? _favSub;

  @override
  void initState() {
    super.initState();
    LocationService.instance.currentLocation.addListener(_onLocationChanged);
    // Terapkan filter kategori awal dari Home jika ada
    if (widget.initialCategory != null) {
      _category = widget.initialCategory;
    }
    _load();
    _svc.getCategories().then((c) {
      if (mounted && c.isNotEmpty) setState(() => _categories = c);
    });
    _svc.getFavoriteIds().then((f) {
      if (mounted) setState(() => _favs = f.toSet());
    });
    _favSub = _svc.favoritesStream.listen((f) {
      if (mounted) setState(() => _favs = f.toSet());
    });
  }

  void _onLocationChanged() {
    if (!mounted) return;
    _load();
  }

  @override
  void didUpdateWidget(ExploreTab old) {
    super.didUpdateWidget(old);
    bool shouldReload = false;
    // Jika kategori berubah dari parent (Home), terapkan dan reload
    if (widget.initialCategory != old.initialCategory &&
        widget.initialCategory != null) {
      _category = widget.initialCategory;
      shouldReload = true;
    }
    // Jika koordinat GPS baru saja diterima dari HomeTab
    if ((widget.userLat != old.userLat || widget.userLng != old.userLng) &&
        widget.userLat != null &&
        widget.userLng != null) {
      shouldReload = true;
    }
    if (shouldReload) {
      _load();
    }
  }

  @override
  void dispose() {
    LocationService.instance.currentLocation.removeListener(_onLocationChanged);
    _favSub?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _svc.getRestaurants(
      search: _search.text.trim(),
      maxPrice: _budgetOn ? 25000 : null,
      category: _category,
      sortBy: _sort == _Sort.termurah ? 'termurah' : null,
    );
    var list = List<Restaurant>.of(res);

    // Filter berdasarkan wilayah kota jika dipilih
    if (_selectedCity != null && _selectedCity != 'Semua') {
      final cityKey = _selectedCity!.toLowerCase();
      list = list.where((r) {
        final addr = r.address.toLowerCase();
        final prov = r.province.toLowerCase();
        return addr.contains(cityKey) || prov.contains(cityKey);
      }).toList();
    }

    final loc = LocationService.instance.currentLocation.value;
    final lat = widget.userLat ?? loc?.lat;
    final lng = widget.userLng ?? loc?.lng;

    if (_sort == _Sort.rating) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sort == _Sort.nama) {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sort == _Sort.terdekat) {
      if (lat != null && lng != null) {
        list.sort((a, b) {
          final dA = LocationService.instance.distanceM(lat, lng, a.lat, a.lng);
          final dB = LocationService.instance.distanceM(lat, lng, b.lat, b.lng);
          return dA.compareTo(dB);
        });
      }
    }

    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  void _onSearchSubmitted(String q) {
    if (q.trim().isNotEmpty) _svc.saveSearch(q.trim());
    _load();
  }

  Future<void> _toggleFav(String id) async {
    setState(() => _favs.contains(id) ? _favs.remove(id) : _favs.add(id));
    await _svc.toggleFavorite(id);
    final real = await _svc.getFavoriteIds();
    if (mounted) setState(() => _favs = real.toSet());
  }

  void _reset() {
    _search.clear();
    _budgetOn = false;
    _category = null;
    _selectedCity = null;
    _sort = _Sort.terdekat;
    _load();
  }

  int get _activeFilters =>
      (_budgetOn ? 1 : 0) +
      (_category != null ? 1 : 0) +
      (_selectedCity != null ? 1 : 0) +
      (_sort != _Sort.terdekat ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _load,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _header(),
              const SizedBox(height: 14),
              _searchRow(),
              const SizedBox(height: 10),
              _coverageInfo(),
              const SizedBox(height: 10),
              _filterChips(),
              const SizedBox(height: 14),
              _resultBar(),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                )
              else if (_items.isEmpty)
                _emptyState()
              else
                ..._items.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlaceCard(
                      r: r,
                      favorite: _favs.contains(r.id),
                      distanceM: () {
                        final loc = LocationService.instance.currentLocation.value;
                        final lat = widget.userLat ?? loc?.lat;
                        final lng = widget.userLng ?? loc?.lng;
                        if (lat != null && lng != null && (r.lat != 0 || r.lng != 0)) {
                          return LocationService.instance.distanceM(lat, lng, r.lat, r.lng);
                        }
                        return null;
                      }(),
                      onFavorite: () => _toggleFav(r.id),
                      onDetail: () => _showDetail(r),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              _outsideBanner(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Restaurant r) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
    );
  }

  // ---------- Header ----------
  Widget _header() {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'F';
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.greenDark,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.yellow,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EKSPLORASI WILAYAH',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text('DIY & Jawa Tengah', style: AppText.display(17)),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: HiveService.instance.settingsListenable,
          builder: (_, _, _) {
            final bool hasBadge =
                HiveService.instance.getActiveRemindersCount() > 0;
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      size: 20,
                      color: AppColors.greenDark,
                    ),
                  ),
                  if (hasBadge)
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- Search ----------
  Widget _searchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.greenDark),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) {
                      setState(() {});
                      _onSearchChanged(v);
                    },
                    onSubmitted: (v) {
                      _onSearchSubmitted(v);
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Cari kuliner, warung, ...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_search.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _search.clear();
                      _onSearchChanged('');
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showCityFilterSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 21,
                  color: AppColors.yellow,
                ),
              ),
              if (_activeFilters > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilters',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Info & filter ----------
  void _showCityFilterSheet() {
    final locSvc = LocationService.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final currentLoc = locSvc.currentLocation.value;
          final isGpsLoading = locSvc.isLoading.value;

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
                        color: AppColors.tint(AppColors.greenDark, 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: AppColors.greenDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filter Wilayah & Lokasi', style: AppText.display(18)),
                          const SizedBox(height: 2),
                          const Text(
                            'Pilih wilayah kuliner atau gunakan GPS terdekat',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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
                const SizedBox(height: 18),

                // Opsi 1: Lokasi GPS Saya
                InkWell(
                  onTap: isGpsLoading
                      ? null
                      : () async {
                          setModal(() {});
                          final ok = await locSvc.fetchGpsLocation();
                          if (!ctx.mounted) return;
                          setModal(() {});
                          if (ok) {
                            setState(() {
                              _selectedCity = null;
                              _sort = _Sort.terdekat;
                            });
                            Navigator.pop(ctx);
                            _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rekomendasi diurutkan dari GPS terdekat Anda 📍'),
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
                                ),
                              );
                            }
                          }
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (currentLoc?.isGps ?? false) && _selectedCity == null
                          ? AppColors.tint(AppColors.greenDark, 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        isGpsLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.greenDark,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, color: AppColors.greenDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gunakan Posisi GPS Saya',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                currentLoc?.isGps == true
                                    ? currentLoc!.address
                                    : 'Urutkan dari posisi koordinat ponsel saat ini',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if ((currentLoc?.isGps ?? false) && _selectedCity == null)
                          const Icon(Icons.check_circle_rounded, color: AppColors.greenDark, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Opsi 2: Semua Wilayah
                InkWell(
                  onTap: () {
                    setState(() => _selectedCity = null);
                    Navigator.pop(ctx);
                    _load();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedCity == null && !(currentLoc?.isGps ?? false)
                          ? AppColors.tint(AppColors.orange, 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          color: _selectedCity == null && !(currentLoc?.isGps ?? false)
                              ? AppColors.orange
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Semua Wilayah (DIY & Jawa Tengah)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (_selectedCity == null && !(currentLoc?.isGps ?? false))
                          const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const Text(
                'WILAYAH KOTA KHUSUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Daftar Wilayah
              ...[
                {'name': 'Kota Yogyakarta', 'city': 'Yogyakarta'},
                {'name': 'Kabupaten Sleman', 'city': 'Sleman'},
                {'name': 'Kabupaten Bantul', 'city': 'Bantul'},
                {'name': 'Surakarta (Solo)', 'city': 'Surakarta'},
                {'name': 'Kota Semarang', 'city': 'Semarang'},
              ].map((item) {
                final city = item['city']!;
                final isSelected = _selectedCity == city;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Navigator.pop(ctx);
                      _load();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filter wilayah: ${item['name']} 🔍'),
                          backgroundColor: AppColors.greenDark,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.tint(AppColors.greenDark, 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.location_city_rounded,
                            size: 18,
                            color: isSelected ? AppColors.greenDark : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['name']!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.greenDark : AppColors.textDark,
                              ),
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

  Widget _coverageInfo() {
    final loc = LocationService.instance.currentLocation.value;
    final isGps = (loc?.isGps ?? false) && _selectedCity == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showCityFilterSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isGps
              ? AppColors.tint(AppColors.greenDark, 0.08)
              : AppColors.tint(AppColors.orange, 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isGps ? Icons.my_location_rounded : Icons.location_on_rounded,
              size: 16,
              color: isGps ? AppColors.greenDark : AppColors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Titik Lokasi: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isGps ? AppColors.greenDark : AppColors.orange,
                      ),
                    ),
                    TextSpan(
                      text: _selectedCity != null
                          ? 'Wilayah $_selectedCity'
                          : (isGps ? (loc?.address ?? 'GPS Anda') : 'Semua (DIY & Jateng)'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isGps ? AppColors.greenDark : AppColors.orange,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Ubah',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isGps ? AppColors.greenDark : AppColors.orange,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: 16,
              color: isGps ? AppColors.greenDark : AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: AppColors.greenDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _chip(
            _selectedCity != null ? 'Wilayah: $_selectedCity' : 'Pilih Wilayah',
            _selectedCity != null,
            _showCityFilterSheet,
          ),
          const SizedBox(width: 8),
          _chip('Budget < Rp25rb', _budgetOn, () {
            _budgetOn = !_budgetOn;
            _load();
          }),
          for (final c in _categories) ...[
            const SizedBox(width: 8),
            _chip(
              _formatCategoryLabel(c),
              _category != null &&
                  (_category == c ||
                      _category!.toLowerCase().replaceAll('_', ' ') ==
                          c.toLowerCase().replaceAll('_', ' ')),
              () {
                final isSelected = _category != null &&
                    (_category == c ||
                        _category!.toLowerCase().replaceAll('_', ' ') ==
                            c.toLowerCase().replaceAll('_', ' '));
                _category = isSelected ? null : c;
                _load();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.greenDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.yellow : AppColors.greenDark,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: AppColors.yellow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultBar() {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Menampilkan ',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                TextSpan(
                  text: '${_items.length} Tempat Kuliner',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
        PopupMenuButton<_Sort>(
          onSelected: (s) {
            _sort = s;
            _load();
          },
          itemBuilder: (_) => _Sort.values
              .map((s) => PopupMenuItem(value: s, child: Text(_sortLabels[s]!)))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'URUTAN: ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  _sortLabels[_sort]!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.greenDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text('Tidak ada hasil', style: AppText.display(16)),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah kata kunci atau reset filter.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _outsideBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 20,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mencari di luar DIY & Jateng?',
                  style: AppText.display(14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'FOODIE saat ini hanya mendedikasikan eksplorasi kuliner '
                  'terkurasi di wilayah Daerah Istimewa Yogyakarta dan Jawa '
                  'Tengah untuk menjaga keaslian rasa kurator kami.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================== Kartu tempat ===================
class _PlaceCard extends StatelessWidget {
  final Restaurant r;
  final bool favorite;
  final double? distanceM;
  final VoidCallback onFavorite;
  final VoidCallback onDetail;

  const _PlaceCard({
    required this.r,
    required this.favorite,
    this.distanceM,
    required this.onFavorite,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final rating = r.rating;
    final price = r.priceMax > r.priceMin
        ? r.priceRange
        : 'Mulai ${formatRp(r.priceMin)}';

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatCategoryLabel(r.category).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(r.name, style: AppText.display(16)),
                          ],
                        ),
                      ),
                      ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tint(AppColors.yellow, 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tint(AppColors.yellow, 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatCategoryLabel(r.category),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                      if (distanceM != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tint(AppColors.orange, 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 11,
                                color: AppColors.orange,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                distanceM! >= 1000
                                    ? '${(distanceM! / 1000).toStringAsFixed(1)} km'
                                    : '${distanceM!.round()} m',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.greenDark,
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

  Widget _image() {
    final url = (r.imageUrl?.isEmpty ?? true) ? null : r.imageUrl;
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          else
            _fallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: favorite ? AppColors.red : AppColors.greenDark,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Row(
              children: [
                const Icon(Icons.place, size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    r.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tint(AppColors.orange, 0.55), AppColors.greenDark],
        ),
      ),
      child: const Icon(Icons.ramen_dining, size: 48, color: AppColors.yellow),
    );
  }
}

