import 'dart:async';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/decide.dart';

/// Tab "Home": sapaan, Curated Shake, kategori, dan Pilihan Editor.
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
  List<Restaurant> _picks = [];
  List<String> _categories = [];
  bool _loading = true;
  int _page = 0;
  StreamSubscription<void>? _profileSub;

  @override
  void initState() {
    super.initState();
    _load();
    _profileSub = _svc.onProfileChanged.listen((_) => _load());
  }

  @override
  void dispose() {
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
    final restos = List<Restaurant>.of(results[1] as List<Restaurant>)
      ..sort((a, b) => b.rating.compareTo(a.rating));
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
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              _header(first),
              const SizedBox(height: 22),
              _shakeCard(),
              const SizedBox(height: 26),
              if (_categories.isNotEmpty) ...[
                Text('Kategori Kuliner', style: AppText.display(20)),
                const SizedBox(height: 12),
                _categoryRow(),
                const SizedBox(height: 26),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text('Pilihan Editor', style: AppText.display(20)),
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
              _editorCarousel(),
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

  // ---------- Search BAR DIHAPUS dari Home — hanya ada di Explore ----------

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

  // ---------- Pilihan Editor (carousel) ----------
  Widget _editorCarousel() {
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
            // Swipe horizontal tidak konflik dengan ListView vertikal
            physics: const BouncingScrollPhysics(),
            itemCount: _picks.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _editorCard(_picks[i]),
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

  Widget _editorCard(Restaurant r) {
    final img = (r.imageUrl?.isEmpty ?? true) ? null : r.imageUrl;
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PILIHAN EDITOR',
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
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
