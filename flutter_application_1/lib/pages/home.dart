import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../widgets/decide.dart';
import 'ai_tab.dart';
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

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.explore_outlined, Icons.explore, 'Explore'),
    _NavItem(Icons.casino_outlined, Icons.casino, 'Decide'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'AI'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  void _select(int i) {
    if (i == 2) {
      // "Decide" langsung membuka Shake to Decide.
      showDecideSheet(context);
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(name: widget.name),
          ExploreTab(name: widget.name),
          const SizedBox.shrink(), // slot "Decide" (dibuka sebagai sheet)
          const AiTab(),
          ProfileTab(
            name: widget.name,
            fromRegister: widget.fromRegister,
            biometricOn: widget.biometricOn,
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        items: _items,
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
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.index,
    required this.items,
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
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
