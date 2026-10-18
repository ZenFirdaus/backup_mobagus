import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';

/// Model sederhana tempat kuliner (ganti dengan data API/Firestore nanti).
class CulinaryPlace {
  final String name;
  final String category;
  final double rating;
  final String reviews;
  final String distance;
  final String area;
  final int minPrice;
  final int maxPrice;
  final bool isOpen;
  final String statusText;
  final String? badge;
  final List<String> tags;
  final String? imageUrl; // opsional, fallback ke gradient jika null/gagal

  const CulinaryPlace({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.area,
    required this.minPrice,
    required this.maxPrice,
    required this.isOpen,
    required this.statusText,
    required this.tags,
    this.badge,
    this.imageUrl,
  });
}

const _places = <CulinaryPlace>[
  CulinaryPlace(
    name: 'Gudeg Yu Djum 167 Wijilan',
    category: 'GUDEG BASAH & KERING',
    rating: 4.8,
    reviews: '2.4k',
    distance: '1.2 km',
    area: 'Kraton, DIY',
    minPrice: 20000,
    maxPrice: 45000,
    isOpen: true,
    statusText: 'Buka • Tutup 21:00 WIB',
    badge: 'Legendaris Sejak 1950',
    tags: ['Resep Tradisional', 'Kayu Bakar'],
  ),
  CulinaryPlace(
    name: 'Mangut Lele Mbah Marto',
    category: 'KULINER TRADISIONAL BANTUL',
    rating: 4.9,
    reviews: '1.8k',
    distance: '4.3 km',
    area: 'Sewon, Bantul',
    minPrice: 25000,
    maxPrice: 35000,
    isOpen: true,
    statusText: 'Buka Sekarang',
    badge: 'Dapur Tradisional Pawon',
    tags: ['Asap Tradisional', 'Pedas Gurih'],
  ),
  CulinaryPlace(
    name: 'Soto Bathok Mbah Katro',
    category: 'SOTO & SARAPAN',
    rating: 4.7,
    reviews: '950',
    distance: '3.1 km',
    area: 'Kalasan, Sleman',
    minPrice: 8000,
    maxPrice: 15000,
    isOpen: true,
    statusText: 'Buka • Ramai',
    tags: ['Hemat & Nikmat', 'Pemandangan Sawah'],
  ),
];

enum _Sort { terdekat, rating, termurah }

class ExploreTab extends StatefulWidget {
  final String name;
  const ExploreTab({super.key, this.name = ''});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _search = TextEditingController();
  bool _budgetOn = true;
  bool _openNowOn = true;
  bool _mapView = false;
  _Sort _sort = _Sort.terdekat;
  final Set<String> _favorites = {'Gudeg Yu Djum 167 Wijilan'};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _activeFilters => (_budgetOn ? 1 : 0) + (_openNowOn ? 1 : 0);

  List<CulinaryPlace> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = _places.where((p) {
      if (_budgetOn && p.minPrice > 25000) return false;
      if (_openNowOn && !p.isOpen) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.category.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.terdekat:
        list.sort((a, b) => _km(a).compareTo(_km(b)));
      case _Sort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _Sort.termurah:
        list.sort((a, b) => a.minPrice.compareTo(b.minPrice));
    }
    return list;
  }

  double _km(CulinaryPlace p) =>
      double.tryParse(p.distance.replaceAll(' km', '')) ?? 0;

  void _reset() => setState(() {
    _budgetOn = false;
    _openNowOn = false;
    _search.clear();
    _sort = _Sort.terdekat;
  });

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return PageBackground(
      child: SafeArea(
        bottom: false,
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
            _resultBar(items.length),
            const SizedBox(height: 12),
            if (_mapView)
              _mapPlaceholder()
            else if (items.isEmpty)
              _emptyState()
            else
              ...items.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlaceCard(
                    place: p,
                    favorite: _favorites.contains(p.name),
                    onFavorite: () => setState(() {
                      if (!_favorites.add(p.name)) _favorites.remove(p.name);
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            _outsideBanner(),
          ],
        ),
      ),
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
                      color: AppColors.greenDark.withOpacity(0.8),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.greenDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        _roundIcon(Icons.notifications_none_rounded, dot: true),
      ],
    );
  }

  Widget _roundIcon(IconData icon, {bool dot = false}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.tint(AppColors.greenDark, 0.15)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.greenDark),
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
              border: Border.all(
                color: AppColors.tint(AppColors.greenDark, 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.greenDark),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
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
        // tombol filter dengan badge jumlah
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
        const SizedBox(width: 8),
        // toggle list / peta
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.tint(AppColors.greenDark, 0.15),
            ),
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
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 16,
            color: AppColors.greenDark,
          ),
          const SizedBox(width: 8),
          const Expanded(
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
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.greenDark.withOpacity(0.6),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.tint(AppColors.greenDark, 0.2),
                ),
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
          if (_budgetOn) ...[
            const SizedBox(width: 8),
            _activeChip(
              'Budget < Rp25rb',
              () => setState(() => _budgetOn = false),
            ),
          ],
          if (_openNowOn) ...[
            const SizedBox(width: 8),
            _activeChip(
              'Buka Sekarang',
              () => setState(() => _openNowOn = false),
            ),
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
            child: const Icon(Icons.close, size: 14, color: AppColors.yellow),
          ),
        ],
      ),
    );
  }

  Widget _resultBar(int count) {
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
                  text:
                      '${count == _places.length ? 38 : count} Tempat Kuliner',
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
          onSelected: (s) => setState(() => _sort = s),
          itemBuilder: (_) => _Sort.values
              .map((s) => PopupMenuItem(value: s, child: Text(labels[s]!)))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // ---------- Lain-lain ----------
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
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Pelajari Ekosistem Kami',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.red,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.red),
                  ],
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
  final CulinaryPlace place;
  final bool favorite;
  final VoidCallback onFavorite;

  const _PlaceCard({
    required this.place,
    required this.favorite,
    required this.onFavorite,
  });

  String _rp(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withOpacity(0.08),
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
                            place.category,
                            style: const TextStyle(
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(place.name, style: AppText.display(16)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ratingPill(),
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
                      '${_rp(place.minPrice)} - ${_rp(place.maxPrice)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: place.isOpen
                            ? AppColors.greenDark
                            : AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      place.statusText,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: place.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tint(AppColors.yellow, 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
                            color: AppColors.greenDark,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.greenDark,
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
    );
  }

  Widget _image() {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (place.imageUrl != null)
            Image.network(
              place.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),
          // gradient bawah agar teks lokasi terbaca
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
          if (place.badge != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.greenDark.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 12,
                      color: AppColors.yellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place.badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
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
            child: Row(
              children: [
                _glass(Icons.near_me, place.distance),
                const SizedBox(width: 6),
                Text(
                  place.area,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

  Widget _glass(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: AppColors.orange),
          const SizedBox(width: 3),
          Text(
            '${place.rating}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '(${place.reviews})',
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
