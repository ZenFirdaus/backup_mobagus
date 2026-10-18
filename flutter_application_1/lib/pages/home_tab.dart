import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/decide.dart';
import 'detail_page.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
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
  }

  @override
  Widget build(BuildContext context) {
    final first =
        widget.name.trim().isEmpty ? 'Foodie' : widget.name.trim().split(' ').first;
    return PageBackground(
      child: SafeArea(
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
                    _greetingRow(first),
                    const SizedBox(height: 16),
                    _shakeBanner(),
                    const SizedBox(height: 20),
                    if (_categories.isNotEmpty) ...[
                      Text('Kategori', style: AppText.display(16)),
                      const SizedBox(height: 10),
                      _categoryRow(),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text('Pilihan Hari Ini', style: AppText.display(16)),
                        ),
                        Text(
                          'Lihat semua (${_restaurants.length})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_restaurants.isEmpty)
                      _emptyState()
                    else
                      ..._restaurants.take(5).map((r) => _pickCard(r)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _greetingRow(String first) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELAMAT DATANG',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text('Sugeng Rawuh, $first', style: AppText.display(22)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tint(AppColors.greenDark, 0.15),
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.greenDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shakeBanner() {
    return GestureDetector(
      onTap: () => showDecideSheet(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bingung mau makan apa?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Goyangkan HP-mu dan biarkan FOODIE yang memilih.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: AppColors.tint(AppColors.yellow, 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Shake to Decide',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.orange, 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.casino,
                size: 32,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _categoryRow() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.yellow, 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _catIcons[cat] ?? Icons.restaurant,
                  size: 24,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                cat,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pickCard(Restaurant r) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: r.imageUrl != null && r.imageUrl!.isNotEmpty
                  ? Image.network(
                      r.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: AppText.display(14)),
                  const SizedBox(height: 3),
                  Text(
                    '${r.address.split(',').first} - ${r.province}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              r.priceRange,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return const FoodImage(
      height: 56,
      width: 56,
      icon: Icons.ramen_dining,
      borderRadius: BorderRadius.all(Radius.circular(14)),
      colors: [AppColors.orange, AppColors.greenDark],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Belum ada data kuliner', style: AppText.display(16)),
          const SizedBox(height: 4),
          const Text(
            'Data restoran akan segera tersedia.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
