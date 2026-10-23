import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../widgets/auth_widgets.dart';

enum _NotifType { visitReminder, meal }

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
  List<_NotifItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() {
    final List<_NotifItem> list = [];

    // 1. Ambil jadwal rencana kunjungan kuliner yang dibuat oleh user
    final visitReminders = HiveService.instance.getAllVisitReminders();
    for (final r in visitReminders) {
      final dt = DateTime.tryParse(r['scheduledAt']?.toString() ?? '') ??
          DateTime.now();
      final dateFormatted =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} pukul ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
      final idStr = r['id'].toString();
      final intId = int.tryParse(idStr) ?? 0;
      final note = r['note']?.toString() ?? '';

      list.add(
        _NotifItem(
          id: idStr,
          icon: Icons.alarm_rounded,
          title: 'Rencana Santap: ${r['restoName']}',
          body:
              'Dijadwalkan pada $dateFormatted.${note.isNotEmpty ? "\nCatatan: $note" : ""}',
          time: dateFormatted,
          type: _NotifType.visitReminder,
          actionLabel: 'Batalkan Jadwal',
          onAction: () async {
            await HiveService.instance.deleteVisitReminder(idStr);
            await NotificationService.instance.cancelNotification(intId);
            _initNotifications();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Jadwal kunjungan kuliner dibatalkan'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      );
    }

    // 2. Info jadwal pengingat jam makan harian (hanya jika notifikasi diaktifkan di profil)
    final bool isNotifEnabled = HiveService.instance.isNotificationsEnabled();
    final mealPref = HiveService.instance.getMealReminderPreference();
    if (isNotifEnabled &&
        mealPref['enabled'] == true &&
        mealPref['isSet'] == true) {
      final hour = (mealPref['hour'] as int? ?? 12).toString().padLeft(2, '0');
      final minute =
          (mealPref['minute'] as int? ?? 0).toString().padLeft(2, '0');
      final label = mealPref['label'] as String? ?? 'Makan Siang';

      list.add(
        _NotifItem(
          id: 'meal_pref_active',
          icon: Icons.schedule_rounded,
          title: 'Pengingat Harian $label',
          body:
              'Alarm lokal aktif setiap hari pukul $hour:$minute WIB untuk memberikan inspirasi kuliner Jogja.',
          time: 'Setiap Hari • $hour:$minute WIB',
          type: _NotifType.meal,
        ),
      );
    }

    setState(() {
      _items = list;
    });
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
        return _items.where((i) => i.type == _NotifType.visitReminder).toList();
      case 2:
        return _items.where((i) => i.type == _NotifType.meal).toList();
      default:
        return _items;
    }
  }

  int get _unreadCount => _items.where((i) => !i.isRead).length;

  Future<void> _testInstantNotification() async {
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.showInstantNotification(
      id: 7777,
      title: 'Halo dari FOODIE!',
      body:
          'Sistem notifikasi pengingat kuliner berhasil aktif dan siap memberi jadwal santap tepat waktu.',
      force: true,
    );
    if (mounted) {
      NotificationService.showInAppBanner(
        context,
        title: 'Halo dari FOODIE!',
        body: 'Notifikasi sistem berhasil dikirim ke bilah status HP Anda.',
        icon: Icons.notifications_active_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;

    return Scaffold(
      body: PageBackground(
        child: Column(
          children: [
            _header(),
            _demoTestCard(),
            _filterChips(),
            Expanded(
              child: list.isEmpty
                  ? _emptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
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

  /// Card Pengujian Sistem Notifikasi
  Widget _demoTestCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uji Coba Sistem Notifikasi',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Kirim tes notifikasi ke bilah status HP',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _testInstantNotification,
            child: const Text(
              'Tes Sekarang',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    const filters = ['Semua', 'Jadwal Kunjungan', 'Pengingat Makan'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? AppColors.greenDark : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? Colors.white : AppColors.charcoal,
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
    final Color iconColor = item.type == _NotifType.visitReminder
        ? AppColors.orange
        : AppColors.greenDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                    color: item.type == _NotifType.visitReminder
                        ? const Color(0xFFFDE8E7)
                        : const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.actionLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.type == _NotifType.visitReminder
                          ? AppColors.red
                          : AppColors.greenDark,
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
          Icon(Icons.notifications_off_rounded,
              size: 44, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'Belum ada jadwal atau notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pasang jadwal kunjungan di halaman detail kuliner\natau atur jam makan di profil.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
