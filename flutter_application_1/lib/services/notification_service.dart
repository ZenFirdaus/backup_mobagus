import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../props/app_colors.dart';
import '../widgets/foodie_logo.dart';
import 'hive_service.dart';

/// Service Notifikasi Lokal Sistem (Offline & Online).
/// Bekerja langsung dengan AlarmManager sistem Android/iOS tanpa butuh server/kuota.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi dan database timezone
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _setupLocalTimezone();

      // Konfigurasi ikon Android (menggunakan icon launcher app)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Konfigurasi iOS dengan dukungan banner foreground lengkap
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notifikasi diklik dengan payload: ${details.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('NotificationService berhasil diinisialisasi');
    } catch (e) {
      debugPrint('Gagal inisialisasi NotificationService: $e');
    }
  }

  /// Menyelaraskan basis data timezone dengan offset jam perangkat secara presisi
  void _setupLocalTimezone() {
    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          return;
        }
      }
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.local);
      } catch (_) {}
    }
  }

  /// Meminta izin notifikasi ke pengguna (Android 13+ & iOS)
  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        try {
          await androidImpl.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requestPermissions: $e');
    }
    return true;
  }

  /// Detail saluran notifikasi standar aplikasi Foodie
  NotificationDetails _defaultNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFFFF751F),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // ==========================================
  // 1. NOTIFIKASI LANGSUNG (INSTANT TEST)
  // ==========================================

  /// Memunculkan notifikasi seketika di bilah status HP
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool force = false,
  }) async {
    if (!force && !HiveService.instance.isNotificationsEnabled()) return;

    await requestPermissions();

    await _notificationsPlugin.show(
      id,
      title,
      body,
      _defaultNotificationDetails(
        channelId: 'foodie_instant',
        channelName: 'Notifikasi Langsung Foodie',
        channelDescription: 'Pemberitahuan aktivitas instan aplikasi Foodie',
      ),
      payload: payload,
    );
  }

  // ==========================================
  // 2. PENGINGAT KUNJUNGAN RESTORAN (SPESIFIK TANGGAL & JAM)
  // ==========================================

  /// Menjadwalkan pengingat kunjungan kuliner di tanggal dan waktu masa depan
  /// Bekerja 100% offline via hardware alarm sistem
  Future<void> scheduleVisitReminder({
    required int id,
    required String restoName,
    required DateTime scheduledDate,
    String? note,
  }) async {
    await HiveService.instance.setNotificationsEnabled(true);
    await requestPermissions();

    // Konstruksi TZDateTime spesifik agar jam & menit akurat 100%
    tz.TZDateTime scheduledTZ = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      0,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Jika waktu yang dipilih adalah menit saat ini (untuk uji coba langsung):
    // Jadwalkan 5 detik lagi agar notifikasi sistem HP muncul seketika!
    if (now.year == scheduledDate.year &&
        now.month == scheduledDate.month &&
        now.day == scheduledDate.day &&
        now.hour == scheduledDate.hour &&
        now.minute == scheduledDate.minute) {
      scheduledTZ = now.add(const Duration(seconds: 5));
    } else if (scheduledTZ.isBefore(now)) {
      // Jika waktu sudah lewat di masa lalu, abaikan
      return;
    }

    final String title = 'Waktunya Kulineran di $restoName!';
    final String body = note != null && note.isNotEmpty
        ? '$note • Sesuai rencanamu, yuk berangkat santap sekarang!'
        : 'Sesuai jadwal rencanamu, resto ini sudah buka. Jangan lupa mampir & nikmati kulinernya!';

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      _defaultNotificationDetails(
        channelId: 'foodie_visit_reminders',
        channelName: 'Pengingat Kunjungan Resto',
        channelDescription: 'Pengingat rencana kunjungan ke restoran pilihan',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'resto_visit_$id',
    );
    debugPrint('Notifikasi kunjungan dijadwalkan pada: $scheduledTZ (ID: $id)');
  }

  // ==========================================
  // 3. PENGINGAT JADWAL MAKAN HARIAN (PROFIL)
  // ==========================================

  /// Menjadwalkan notifikasi jam makan harian (berulang setiap hari di jam & menit yang ditentukan)
  Future<void> scheduleDailyMealReminder({
    int id = 9999, // ID khusus alarm jam makan
    required int hour,
    required int minute,
    String label = 'Makan Siang',
  }) async {
    await HiveService.instance.setNotificationsEnabled(true);
    await requestPermissions();

    // Batalkan jadwal makan sebelumnya terlebih dahulu
    await cancelNotification(id);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    final String title = 'Waktunya $label!';
    final String body =
        'Sudah jam ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB. Buka Foodie sekarang untuk temukan inspirasi kuliner terbaik hari ini!';

    // Jika jam & menit sama persis dengan sekarang (sedang diuji coba user):
    // Munculkan notifikasi sistem dalam 5 detik agar user langsung melihat bukti berfungsinya!
    if (now.hour == hour && now.minute == minute) {
      final tz.TZDateTime instantTest = now.add(const Duration(seconds: 5));
      await _notificationsPlugin.zonedSchedule(
        id + 1, // ID sementara untuk uji coba instan
        title,
        body,
        instantTest,
        _defaultNotificationDetails(
          channelId: 'foodie_meal_reminders',
          channelName: 'Pengingat Waktu Makan',
          channelDescription: 'Pengingat jadwal waktu makan harian',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'meal_reminder_test',
      );
      // Jadwalkan pengingat berulang mulai besok
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    } else if (scheduledDate.isBefore(now)) {
      // Jika jam hari ini sudah lewat, jadwalkan mulai besok
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _defaultNotificationDetails(
        channelId: 'foodie_meal_reminders',
        channelName: 'Pengingat Waktu Makan',
        channelDescription: 'Pengingat jadwal waktu makan harian',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Berulang setiap hari di jam yang sama
      payload: 'meal_reminder',
    );
    debugPrint('Pengingat makan harian dijadwalkan pada: $scheduledDate (ID: $id)');
  }

  // ==========================================
  // 4. BATALKAN NOTIFIKASI
  // ==========================================

  /// Membatalkan notifikasi spesifik berdasarkan ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Membatalkan semua notifikasi
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // ==========================================
  // 5. BANNER NOTIFIKASI MODERN DI DALAM APP (IN-APP OVERLAY)
  // ==========================================

  /// Menampilkan banner notifikasi visual elegan di bagian atas layar aplikasi
  static void showInAppBanner(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = Icons.notifications_active_rounded,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _InAppNotificationWidget(
        title: title,
        body: body,
        icon: icon,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.body,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() =>
      _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<Offset> _offsetAnim;
  late final Animation<double> _fadeAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
    ));

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);

    _animCtrl.forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _animCtrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -5) {
                  _dismiss();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF751F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        FoodieLogo.markWhite,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'FOODIE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.orange,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• Sekarang',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.body,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
