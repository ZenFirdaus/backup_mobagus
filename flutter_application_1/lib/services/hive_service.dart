import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service khusus manajemen penyimpanan lokal NoSQL (Hive).
/// Berdiri sendiri dan terpisah sepenuhnya dari Supabase (Clean Architecture).
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  // Nama Box sesuai arsitektur laporan PAM
  static const String boxSettings = 'settings';
  static const String boxReminders = 'reminders_local';
  static const String boxFavorites = 'favorites_local';
  static const String boxSearchHistory = 'search_history_local';
  static const String boxFaceBiometrics = 'face_biometrics_db';

  /// Inisialisasi Hive dan buka seluruh box yang dibutuhkan aplikasi
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxSettings);
    await Hive.openBox(boxReminders);
    await Hive.openBox(boxFavorites);
    await Hive.openBox(boxSearchHistory);
    await Hive.openBox(boxFaceBiometrics);
  }

  // ==========================================
  // 1. SETTINGS & PENGINGAT JADWAL MAKAN (PROFIL)
  // ==========================================

  /// Mendapatkan status master toggle notifikasi
  bool isNotificationsEnabled() {
    final box = Hive.box(boxSettings);
    return box.get('notifications_enabled', defaultValue: true) as bool;
  }

  /// Mengubah status master toggle notifikasi
  Future<void> setNotificationsEnabled(bool enabled) async {
    final box = Hive.box(boxSettings);
    await box.put('notifications_enabled', enabled);
  }

  /// Mendapatkan preferensi pengingat jam makan harian
  /// Mengembalikan Map berisi `enabled`, `isSet`, `hour`, `minute`, `label`
  Map<String, dynamic> getMealReminderPreference() {
    final box = Hive.box(boxSettings);
    return {
      'enabled': box.get('meal_reminder_enabled', defaultValue: false) as bool,
      'isSet': box.get('meal_reminder_is_set', defaultValue: false) as bool,
      'hour': box.get('meal_reminder_hour', defaultValue: 12) as int,
      'minute': box.get('meal_reminder_minute', defaultValue: 0) as int,
      'label': box.get('meal_reminder_label', defaultValue: 'Makan Siang') as String,
    };
  }

  /// Menyimpan preferensi pengingat jam makan harian
  Future<void> saveMealReminderPreference({
    required bool enabled,
    required bool isSet,
    required int hour,
    required int minute,
    String label = 'Makan Siang',
  }) async {
    final box = Hive.box(boxSettings);
    await box.put('meal_reminder_enabled', enabled);
    await box.put('meal_reminder_is_set', isSet);
    await box.put('meal_reminder_hour', hour);
    await box.put('meal_reminder_minute', minute);
    await box.put('meal_reminder_label', label);
  }

  /// Menghapus/mereset jadwal pengingat makan
  Future<void> removeMealReminderPreference() async {
    final box = Hive.box(boxSettings);
    await box.put('meal_reminder_enabled', false);
    await box.put('meal_reminder_is_set', false);
  }

  // ==========================================
  // 2. JADWAL PENGINGAT KUNJUNGAN RESTO (DETAIL RESTO)
  // ==========================================

  /// Mengambil semua jadwal pengingat kunjungan yang tersimpan
  List<Map<String, dynamic>> getAllVisitReminders() {
    final box = Hive.box(boxReminders);
    final List<Map<String, dynamic>> list = [];

    for (var key in box.keys) {
      final raw = box.get(key);
      if (raw != null && raw is Map) {
        list.add(Map<String, dynamic>.from(raw));
      }
    }

    // Urutkan berdasarkan waktu scheduled terdekat
    list.sort((a, b) {
      final aTime = DateTime.tryParse(a['scheduledAt']?.toString() ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['scheduledAt']?.toString() ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    return list;
  }

  /// Menambahkan atau memperbarui jadwal kunjungan kuliner
  Future<void> saveVisitReminder({
    required String id,
    required String restoId,
    required String restoName,
    required String restoAddress,
    required DateTime scheduledAt,
    String note = '',
  }) async {
    final box = Hive.box(boxReminders);
    final data = {
      'id': id,
      'restoId': restoId,
      'restoName': restoName,
      'restoAddress': restoAddress,
      'scheduledAt': scheduledAt.toIso8601String(),
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
      'isCompleted': false,
    };
    await box.put(id, data);
  }

  /// Menghapus jadwal pengingat berdasarkan ID
  Future<void> deleteVisitReminder(String id) async {
    final box = Hive.box(boxReminders);
    await box.delete(id);
  }

  /// Menandai jadwal kunjungan selesai
  Future<void> markReminderCompleted(String id, bool completed) async {
    final box = Hive.box(boxReminders);
    final raw = box.get(id);
    if (raw != null && raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      data['isCompleted'] = completed;
      await box.put(id, data);
    }
  }

  /// ValueListenable agar UI (seperti badge di Home & Explore) otomatis rebuild saat pengaturan notifikasi diubah di Profil
  ValueListenable<Box> get settingsListenable => Hive.box(boxSettings).listenable();

  /// Menghitung jumlah pengingat yang belum lewat / aktif
  int getActiveRemindersCount() {
    if (!isNotificationsEnabled()) return 0;

    final reminders = getAllVisitReminders();
    final now = DateTime.now();
    int count = reminders.where((r) {
      final dt = DateTime.tryParse(r['scheduledAt']?.toString() ?? '');
      return dt != null && dt.isAfter(now) && (r['isCompleted'] != true);
    }).length;

    final mealPref = getMealReminderPreference();
    if (mealPref['enabled'] == true && mealPref['isSet'] == true) {
      count++;
    }

    return count;
  }

  // ==========================================
  // 3. PERSISTENSI BIOMETRIK WAJAH NO-SQL (HIVE)
  // Tersimpan permanen di database lokal meski user logout berkali-kali
  // ==========================================

  Box get _faceBox => Hive.box(boxFaceBiometrics);

  /// Menyimpan data biometrik wajah terikat ke email akun
  Future<void> saveBiometricProfile({
    required String email,
    required String name,
    String? password,
    required Map<String, dynamic> metrics,
    String? userId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await _faceBox.put(cleanEmail, {
      'email': cleanEmail,
      'name': name.trim(),
      'password': password ?? '',
      'metrics': metrics,
      'userId': userId ?? '',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Mengambil profil biometrik berdasarkan email
  Map<String, dynamic>? getBiometricProfile(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final raw = _faceBox.get(cleanEmail);
    if (raw != null && raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  /// Mengambil semua akun yang terdaftar Face ID di perangkat
  List<Map<String, dynamic>> getAllBiometricProfiles() {
    final List<Map<String, dynamic>> list = [];
    for (var key in _faceBox.keys) {
      final raw = _faceBox.get(key);
      if (raw != null && raw is Map) {
        list.add(Map<String, dynamic>.from(raw));
      }
    }
    return list;
  }

  /// Menghapus pendaftaran biometrik suatu akun
  Future<void> deleteBiometricProfile(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    await _faceBox.delete(cleanEmail);
  }
}

