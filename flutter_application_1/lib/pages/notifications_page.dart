import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';
import 'converter_page.dart';
import 'game_page.dart';
import 'achievements_page.dart';

enum _NotifType { meal, geofence, game, achievement, currency }

class _NotifItem {
  final String id;
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final _NotifType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  bool isRead;

  _NotifItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.actionLabel,
    this.onAction,
  }) : isRead = false;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedFilter = 0;
  late List<_NotifItem> _items;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    _items = [
      _NotifItem(
        id: 'n1',
        icon: Icons.restaurant_menu_rounded,
        title: 'Waktunya Santap Malam Gudeg',
        body: 'Sentra Lesehan Wijilan & Malioboro sedang ramai. Nikmati gudeg basah hangat malam ini.',
        time: '19:04 WIB',
        type: _NotifType.meal,
        actionLabel: 'Cek Jadwal Makan',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConverterPage()),
        ),
      ),
      _NotifItem(
        id: 'n2',
        icon: Icons.my_location_rounded,
        title: 'Kamu Dekat Gudeg Yu Djum!',
        body: 'Radar GPS mendeteksi kamu berada dalam radius 50m. Lakukan check-in fisik untuk klaim poin.',
        time: '18:30 WIB',
        type: _NotifType.geofence,
        actionLabel: 'Buka Peta',
        onAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membuka radar geofence lokasi...'),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      _NotifItem(
        id: 'n3',
        icon: Icons.sports_esports_rounded,
        title: 'Tantangan Harian Tersedia',
        body: 'Uji pengetahuan kuliner Mataraman di Tebak Kuliner Jogja dan dapatkan hingga +100 poin.',
        time: '12:00 WIB',
        type: _NotifType.game,
        actionLabel: 'Main Sekarang',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GamePage()),
        ),
      ),
      _NotifItem(
        id: 'n4',
        icon: Icons.emoji_events_rounded,
        title: 'Poin Bonus Selamat Datang',
        body: 'Akun Anda telah menerima bonus sambutan +100 Foodie Points sebagai kurator baru.',
        time: '10:15 WIB',
        type: _NotifType.achievement,
        actionLabel: 'Lihat Trofi',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AchievementsPage()),
        ),
      ),
      _NotifItem(
        id: 'n5',
        icon: Icons.currency_exchange_rounded,
        title: 'Pembaruan Kurs Valas Wisatawan',
        body: 'Simulasi acuan kurs kuliner diperbarui: 1 USD ~ Rp15.923, 1 MYR ~ Rp3.614.',
        time: '08:00 WIB',
        type: _NotifType.currency,
        actionLabel: 'Konverter Kurs',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConverterPage()),
        ),
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _items) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai telah dibaca'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  List<_NotifItem> get _filteredItems {
    switch (_selectedFilter) {
      case 1:
        return _items.where((i) => i.type == _NotifType.meal).toList();
      case 2:
        return _items.where((i) => i.type == _NotifType.geofence).toList();
      default:
        return _items;
    }
  }

  int get _unreadCount => _items.where((i) => !i.isRead).length;

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;

    return Scaffold(
      body: PageBackground(
        child: Column(
          children: [
            _header(),
            _filterChips(),
            Expanded(
              child: list.isEmpty
                  ? _emptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _card(list[i]),
                    ),
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
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Notifikasi', style: AppText.display(18)),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadCount Baru',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Text(
                  'Kabar kuliner & pengingat rasa',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: _markAllAsRead,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    const filters = ['Semua', 'Waktu Makan', 'Geofence GPS'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.greenDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? AppColors.greenDark : AppColors.line,
                  ),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _card(_NotifItem item) {
    Color iconColor;
    switch (item.type) {
      case _NotifType.meal:
        iconColor = AppColors.orange;
      case _NotifType.geofence:
        iconColor = AppColors.greenDark;
      case _NotifType.game:
        iconColor = AppColors.red;
      case _NotifType.achievement:
        iconColor = AppColors.orange;
      case _NotifType.currency:
        iconColor = AppColors.greenDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead
              ? AppColors.line
              : AppColors.tint(AppColors.orange, 0.4),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tint(iconColor, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textDark,
            ),
          ),
          if (item.actionLabel != null && item.onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() => item.isRead = true);
                  item.onAction!();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.yellow, 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.tint(AppColors.orange, 0.3)),
                  ),
                  child: Text(
                    item.actionLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 44, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'Tidak ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Semua pemberitahuan rasa Anda sudah terbaca.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
