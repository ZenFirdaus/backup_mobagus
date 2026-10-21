import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
      // Inisialisasi basis data zona waktu untuk penjadwalan presisi
      tz.initializeTimeZones();
      // Set zona waktu default ke WIB (Asia/Jakarta)
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // Fallback jika tidak ditemukan
      }

      // Konfigurasi ikon Android (menggunakan icon launcher app)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Konfigurasi iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

  /// Meminta izin notifikasi ke pengguna (terutama Android 13+)
  Future<bool> requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
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
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // ==========================================
  // 1. NOTIFIKASI LANGSUNG (INSTANT TEST)
  // ==========================================

  /// Memunculkan notifikasi seketika (berguna untuk konfirmasi jadwal dibuat)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!HiveService.instance.isNotificationsEnabled()) return;

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
    if (!HiveService.instance.isNotificationsEnabled()) return;

    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    // Jangan jadwalkan jika waktu sudah terlewat
    if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) return;

    final String title = 'Waktunya Kulineran di $restoName!';
    final String body = note != null && note.isNotEmpty
        ? '$note • Sesuai rencanamu, yuk berangkat santap hari ini!'
        : 'Sesuai jadwal rencanamu, resto ini sudah buka. Jangan lupa mampir & check-in poin!';

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
    if (!HiveService.instance.isNotificationsEnabled()) return;

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
    );

    // Jika jam hari ini sudah lewat, jadwalkan mulai besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final String title = 'Waktunya $label!';
    final String body =
        'Sudah jam ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}. Buka Foodie sekarang untuk temukan inspirasi kuliner Jogja terbaik hari ini!';

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
}
