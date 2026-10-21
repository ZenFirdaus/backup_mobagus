import 'dart:async';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../props/app_colors.dart';
import '../services/supabase_service.dart';
import '../widgets/decide.dart';
import 'ai_tab.dart';
import 'detail_page.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

/// Kerangka aplikasi setelah login: 5 tab + bottom navigation.
/// Tab: Home, Explore, Decide, AI, Profile.
class HomePage extends StatefulWidget {
  final String name;
  final bool fromRegister;
  final bool biometricOn;

  const HomePage({
    super.key,
    required this.name,
    this.fromRegister = false,
    this.biometricOn = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  String? _exploreCategory; // kategori yang di-filter dari home
  double? _userLat;
  double? _userLng;
  Profile? _profile;
  String? _customAvatarUrl;
  StreamSubscription<void>? _profileSub;

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.explore_outlined, Icons.explore, 'Explore'),
    _NavItem(Icons.casino_outlined, Icons.casino, 'Decide'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _profileSub = SupabaseService.instance.onProfileChanged.listen((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final p = await SupabaseService.instance.getProfile();
    if (mounted) {
      setState(() {
        _profile = p;
        if (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty) {
          _customAvatarUrl = p.avatarUrl;
        }
      });
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _select(int i) {
    if (i == 2) {
      // "Decide" langsung membuka Shake to Decide.
      showDecideSheet(context);
      return;
    }
    setState(() => _index = i);
  }

  void _selectCategoryExplore(String category) {
    setState(() {
      _exploreCategory = category;
      _index = 1; // pindah ke tab Explore
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(
            name: widget.name,
            onSeeAll: () => _select(1),
            onCategorySelected: _selectCategoryExplore,
            onOpenRestaurant: (r) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
            ),
            onLocationFetched: (lat, lng) {
              setState(() {
                _userLat = lat;
                _userLng = lng;
              });
            },
          ),
          ExploreTab(
            name: widget.name,
            initialCategory: _exploreCategory,
            userLat: _userLat,
            userLng: _userLng,
          ),
          const SizedBox.shrink(),   // slot "Decide" (dibuka sebagai sheet)
          const AiTab(),
          ProfileTab(
            name: widget.name,
            fromRegister: widget.fromRegister,
            biometricOn: widget.biometricOn,
            onAvatarChanged: (url) {
              setState(() {
                _customAvatarUrl = url;
                if (_profile != null) {
                  _profile = Profile(
                    id: _profile!.id,
                    displayName: _profile!.displayName,
                    avatarUrl: url,
                    points: _profile!.points,
                    createdAt: _profile!.createdAt,
                  );
                }
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        items: _items,
        avatarUrl: _customAvatarUrl ?? _profile?.avatarUrl,
        onSelect: _select,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _BottomNav extends StatelessWidget {
  final int index;
  final List<_NavItem> items;
  final String? avatarUrl;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.index,
    required this.items,
    this.avatarUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == index;
              final isProfile = item.label == 'Profile';
              final hasAvatar = isProfile && avatarUrl != null && avatarUrl!.trim().isNotEmpty;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasAvatar)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active
                                  ? AppColors.orange
                                  : AppColors.tint(AppColors.yellow, 0.7),
                              width: active ? 2 : 1.2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            avatarUrl!.trim(),
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Icon(
                              active ? item.activeIcon : item.icon,
                              size: 20,
                              color: active
                                  ? AppColors.orange
                                  : AppColors.tint(AppColors.yellow, 0.7),
                            ),
                          ),
                        )
                      else
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active
                              ? AppColors.orange
                              : AppColors.tint(AppColors.yellow, 0.7),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: active
                              ? AppColors.orange
                              : AppColors.tint(AppColors.yellow, 0.7),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: active ? 5 : 0,
                        height: active ? 5 : 0,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
