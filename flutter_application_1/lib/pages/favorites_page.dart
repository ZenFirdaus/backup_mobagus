import 'dart:async';
import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import 'detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int _selectedTab = 0;

  List<Restaurant>? _favorites;
  bool _favLoading = true;
  String? _favError;

  List<Map<String, dynamic>>? _history;
  bool _histLoading = true;
  String? _histError;
  StreamSubscription<Set<String>>? _favSub;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadHistory();
    _favSub = SupabaseService.instance.favoritesStream.listen((_) {
      if (mounted) _loadFavorites();
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _favLoading = true;
      _favError = null;
    });
    try {
      final list = await SupabaseService.instance.getFavoriteRestaurants();
      if (mounted) setState(() => _favorites = list);
    } catch (e) {
      if (mounted) setState(() => _favError = e.toString());
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _histLoading = true;
      _histError = null;
    });
    try {
      final list = await SupabaseService.instance.getSearchHistory();
      if (mounted) setState(() => _history = list);
    } catch (e) {
      if (mounted) setState(() => _histError = e.toString());
    } finally {
      if (mounted) setState(() => _histLoading = false);
    }
  }

  Future<void> _removeFavorite(Restaurant r) async {
    await SupabaseService.instance.toggleFavorite(r.id);
    if (!mounted) return;
    setState(() {
      _favorites?.removeWhere((item) => item.id == r.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${r.name} dihapus dari favorit'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text(
          'Semua riwayat pencarian akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await SupabaseService.instance.clearSearchHistory();
      if (mounted) {
        setState(() => _history = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat pencarian telah dibersihkan'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openDetail(Restaurant r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPage(restaurant: r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Column(
          children: [
            _header(),
            _tabBar(),
            Expanded(
              child: _selectedTab == 0 ? _favoritesTab() : _historyTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Koleksi & Riwayat', style: AppText.display(18)),
                const Text(
                  'Tersimpan untuk akses cepat',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final count = _favorites?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: _tabButton(
                0,
                'Favorit ($count)',
                Icons.favorite_rounded,
              ),
            ),
            Expanded(
              child: _tabButton(
                1,
                'Riwayat',
                Icons.history_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final active = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: active ? AppColors.greenDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.yellow : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoritesTab() {
    if (_favLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_favError != null) {
      return _errorState(_favError!, _loadFavorites);
    }
    if (_favorites == null || _favorites!.isEmpty) {
      return _emptyState(
        Icons.favorite_border,
        'Belum ada restoran favorit',
        'Jelajahi kuliner dan ketuk ikon hati untuk menyimpannya di sini.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppColors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _favorites!.length,
        itemBuilder: (_, i) => _favoriteCard(_favorites![i]),
      ),
    );
  }

  Widget _favoriteCard(Restaurant r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        onTap: () => _openDetail(r),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
            FoodImage(
              imageUrl: r.imageUrl,
              width: 54,
              height: 54,
              borderRadius: BorderRadius.circular(14),
              icon: Icons.restaurant_rounded,
            ),
            const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.priceRange,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.red),
                onPressed: () => _removeFavorite(r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTab() {
    if (_histLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_histError != null) {
      return _errorState(_histError!, _loadHistory);
    }
    if (_history == null || _history!.isEmpty) {
      return _emptyState(
        Icons.history,
        'Belum ada riwayat',
        'Pencarian yang kamu lakukan akan tersimpan di sini.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.orange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RIWAYAT PENCARIAN',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: _clearAllHistory,
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._history!.map(_historyTile),
        ],
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> item) {
    final query = item['query'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              query,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.red),
          const SizedBox(height: 8),
          const Text('Gagal memuat data'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
