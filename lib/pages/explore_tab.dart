import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import 'detail_page.dart';
import 'notifications_page.dart';

enum _Sort { terdekat, rating, termurah }

class ExploreTab extends StatefulWidget {
  final String name;
  final String? initialCategory;
  final String? initialSearch;
  final bool initialBudget;
  const ExploreTab({
    super.key,
    this.name = '',
    this.initialCategory,
    this.initialSearch,
    this.initialBudget = false,
  });

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _search = TextEditingController();
  bool _budgetOn = false;
  bool _openNowOn = false;
  String? _selectedCategory;
  _Sort _sort = _Sort.terdekat;
  final Set<String> _favoriteIds = {};

  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory;
    }
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _search.text = widget.initialSearch!;
    }
    if (widget.initialBudget) {
      _budgetOn = true;
    }
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sortBy = _sort == _Sort.termurah ? 'termurah' : null;
      final results = await Future.wait([
        SupabaseService.instance.getRestaurants(
          search: _search.text.trim().isEmpty ? null : _search.text.trim(),
          maxPrice: _budgetOn ? 25000 : null,
          category: _selectedCategory,
          sortBy: sortBy,
        ),
        SupabaseService.instance.getFavoriteIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _restaurants = results[0] as List<Restaurant>;
        _favoriteIds
          ..clear()
          ..addAll(results[1] as List<String>);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  int get _activeFilters =>
      (_budgetOn ? 1 : 0) +
      (_openNowOn ? 1 : 0) +
      (_selectedCategory != null ? 1 : 0);

  void _reset() {
    setState(() {
      _budgetOn = false;
      _openNowOn = false;
      _selectedCategory = null;
      _search.clear();
      _sort = _Sort.terdekat;
    });
    _load();
  }

  void _onSearchSubmit(String query) {
    if (query.trim().isNotEmpty) {
      SupabaseService.instance.saveSearch(query.trim());
    }
    _load();
  }

  Future<void> _toggleFav(Restaurant r) async {
    setState(() {
      if (!_favoriteIds.add(r.id)) {
        _favoriteIds.remove(r.id);
      }
    });
    try {
      await SupabaseService.instance.toggleFavorite(r.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.orange,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _header(canPop: canPop),
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
                      child:
                          CircularProgressIndicator(color: AppColors.orange),
                    ),
                  )
                else if (_error != null)
                  _errorState()
                else if (_restaurants.isEmpty)
                  _emptyState()
                else
                  ..._restaurants.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PlaceCard(
                        place: p,
                        favorite: _favoriteIds.contains(p.id),
                        onFavorite: () => _toggleFav(p),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailPage(restaurant: p),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                _outsideBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({bool canPop = false}) {
    final initial =
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'F';
    return Row(
      children: [
        if (canPop) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18),
            ),
          ),
        ],
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
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: _roundIcon(Icons.notifications_none_rounded, dot: true),
        ),
      ],
    );
  }

  Widget _roundIcon(IconData icon, {bool dot = false}) {
    return Container(
      width: 40,
      height: 40,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textDark),
          if (dot)
            Positioned(
              top: 9,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                    Icons.search_rounded, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: _onSearchSubmit,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Cari kuliner, warung, soto, gudeg...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: _search.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _search.clear();
                                _load();
                              },
                              child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => _onSearchSubmit(_search.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _budgetOn = !_budgetOn);
                _load();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 21,
                  color: Colors.white,
                ),
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
          ],
        ),
      ],
    );
  }

  Widget _coverageInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined, size: 16, color: AppColors.green),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 11.5),
            ),
          ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.tint(AppColors.greenDark, 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 14, color: AppColors.greenDark),
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
          if (_budgetOn) ...[
            const SizedBox(width: 8),
            _activeChip('Budget < Rp25rb', () {
              setState(() => _budgetOn = false);
              _load();
            }),
          ],
          if (_openNowOn) ...[
            const SizedBox(width: 8),
            _activeChip('Buka Sekarang', () {
              setState(() => _openNowOn = false);
              _load();
            }),
          ],
          if (_selectedCategory != null) ...[
            const SizedBox(width: 8),
            _activeChip('Kategori: $_selectedCategory', () {
              setState(() => _selectedCategory = null);
              _load();
            }),
          ],
        ],
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child:
                const Icon(Icons.close, size: 14, color: AppColors.yellow),
          ),
        ],
      ),
    );
  }

  Widget _resultBar() {
    const labels = {
      _Sort.terdekat: 'Terdekat',
      _Sort.rating: 'Rating',
      _Sort.termurah: 'Termurah',
    };
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
                  text: '${_restaurants.length} Tempat Kuliner',
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
            setState(() => _sort = s);
            _load();
          },
          itemBuilder: (_) => _Sort.values
              .map((s) =>
                  PopupMenuItem(value: s, child: Text(labels[s]!)))
              .toList(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.tint(AppColors.greenDark, 0.2),
              ),
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
                  labels[_sort]!,
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

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Terjadi Kesalahan', style: AppText.display(16)),
          const SizedBox(height: 4),
          Text(
            _error!,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
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

class _PlaceCard extends StatelessWidget {
  final Restaurant place;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line.withValues(alpha: 0.7), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 14,
              offset: Offset(0, 4),
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
                  Text(
                    place.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(place.name, style: AppText.display(16)),
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
                        place.priceRange,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                      const Spacer(),
                      if (place.openingHours != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          place.openingHours!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.address,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        children: [
                          Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.orange,
                          ),
                        ],
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
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
            Image.network(
              place.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
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
            bottom: 8,
            child: Text(
              '${place.address.split(',').first} - ${place.province}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return const FoodImage(
      height: 150,
      width: double.infinity,
      icon: Icons.ramen_dining,
      borderRadius: BorderRadius.zero,
      colors: [AppColors.orange, AppColors.greenDark],
    );
  }
}
