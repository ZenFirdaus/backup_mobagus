import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food.dart';
import '../models/restaurant.dart';
import '../utils/format.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';

enum _Sort { nama, rating, termurah }

/// Tab "Explore": data dari Supabase (fallback seed jika kosong/offline).
class ExploreTab extends StatefulWidget {
  final String name;
  const ExploreTab({super.key, this.name = ''});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _svc = SupabaseService.instance;
  final _search = TextEditingController();
  Timer? _debounce;

  List<Restaurant> _items = [];
  List<String> _categories = [];
  Set<String> _favs = {};
  String? _category;
  bool _budgetOn = false;
  bool _mapView = false;
  bool _loading = true;
  _Sort _sort = _Sort.nama;

  static const _sortLabels = {
    _Sort.nama: 'Nama A-Z',
    _Sort.rating: 'Rating',
    _Sort.termurah: 'Termurah',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _svc.getCategories().then((c) {
      if (mounted) setState(() => _categories = c);
    });
    _svc.getFavoriteIds().then((f) {
      if (mounted) setState(() => _favs = f.toSet());
    });
  }

  @override
  void dispose() {
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
    final list = List<Restaurant>.of(res);
    if (_sort == _Sort.rating) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
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
    _sort = _Sort.nama;
    _load();
  }

  int get _activeFilters => (_budgetOn ? 1 : 0) + (_category != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _load,
          child: ListView(
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
              else if (_mapView)
                _mapPlaceholder()
              else if (_items.isEmpty)
                _emptyState()
              else
                ..._items.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlaceCard(
                      r: r,
                      favorite: _favs.contains(r.id),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(r: r),
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
                  Text('Yogyakarta', style: AppText.display(17)),
                  const SizedBox(width: 6),
                  Text(
                    '(DIY & Jateng)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.greenDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: AppColors.greenDark,
          ),
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
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.greenDark),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
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
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
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
        const SizedBox(width: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _toggleBtn(
                Icons.view_agenda_outlined,
                !_mapView,
                () => setState(() => _mapView = false),
              ),
              _toggleBtn(
                Icons.map_outlined,
                _mapView,
                () => setState(() => _mapView = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        decoration: BoxDecoration(
          color: active
              ? AppColors.tint(AppColors.orange, 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 19,
          color: active ? AppColors.red : AppColors.greenDark,
        ),
      ),
    );
  }

  // ---------- Info & filter ----------
  Widget _coverageInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined, size: 16, color: AppColors.greenDark),
          SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Cakupan Aktif: ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  TextSpan(
                    text: 'DIY & Jawa Tengah',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 11.5),
            ),
          ),
          Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
        ],
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
                border: Border.all(color: AppColors.line),
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
          _chip('Budget < Rp25rb', _budgetOn, () {
            _budgetOn = !_budgetOn;
            _load();
          }),
          for (final c in _categories) ...[
            const SizedBox(width: 8),
            _chip(c, _category == c, () {
              _category = _category == c ? null : c;
              _load();
            }),
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
          border: Border.all(
            color: active ? AppColors.greenDark : AppColors.line,
          ),
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
              border: Border.all(color: AppColors.line),
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

  Widget _mapPlaceholder() {
    return Container(
      height: 320,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.greenDark, 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppColors.greenDark),
          const SizedBox(height: 8),
          Text('Tampilan peta segera hadir', style: AppText.display(15)),
        ],
      ),
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
        border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
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
  final VoidCallback onFavorite;
  final VoidCallback onDetail;

  const _PlaceCard({
    required this.r,
    required this.favorite,
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
                              r.category.toUpperCase(),
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
                        Icons.payments_outlined,
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
                          r.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
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

// =================== Detail (menu dari tabel foods) ===================
class _DetailSheet extends StatelessWidget {
  final Restaurant r;
  const _DetailSheet({required this.r});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(r.name, style: AppText.display(22)),
            const SizedBox(height: 4),
            Text(
              r.address,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text('Menu', style: AppText.display(16)),
            const SizedBox(height: 8),
            FutureBuilder<List<Food>>(
              future: SupabaseService.instance.getFoods(r.id),
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                  );
                }
                final foods = snap.data ?? [];
                if (foods.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Menu belum tersedia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: foods.map((f) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                              ),
                            ),
                          ),
                          Text(
                            f.priceLabel,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
