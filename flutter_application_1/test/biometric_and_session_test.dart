import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/face_biometric_service.dart';
import 'package:flutter_application_1/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PENGUJIAN MASALAH 1: Pengikatan Biometrik ke Profil Pengguna Tertentu', () {
    test('Face ID terikat khusus ke akun pengguna yang mendaftar', () async {
      final bioService = FaceBiometricService.instance;

      final metricsUserA = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.36,
        mouthToNoseRatio: 0.31,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // 1. User A (dimas@foodie.id) mendaftarkan Face ID
      await bioService.saveEnrolledFace(
        metrics: metricsUserA,
        userName: 'Dimas Dananjaya',
        userEmail: 'dimas@foodie.id',
        password: 'passwordDimas123',
      );

      // Pastikan User A terdaftar
      final isEnrolledA = await bioService.isFaceEnrolled(email: 'dimas@foodie.id');
      expect(isEnrolledA, isTrue, reason: 'Akun User A harus memiliki Face ID aktif');

      // 2. User B (siti@foodie.id) BELUM mendaftarkan Face ID
      final isEnrolledB = await bioService.isFaceEnrolled(email: 'siti@foodie.id');
      expect(isEnrolledB, isFalse, reason: 'Akun User B TIDAK boleh otomatis memiliki Face ID');

      // 3. Pastikan metrik User B tidak ada
      final metricsB = await bioService.getEnrolledMetrics(email: 'siti@foodie.id');
      expect(metricsB, isNull, reason: 'Metrik wajah User B harus null');

      // 4. Pastikan metrik User A tersimpan dengan benar
      final loadedMetricsA = await bioService.getEnrolledMetrics(email: 'dimas@foodie.id');
      expect(loadedMetricsA, isNotNull);
      expect(loadedMetricsA!.faceAspectRatio, closeTo(1.35, 0.001));
    });

    test('Threshold ML Kit menolak wajah orang lain yang berbeda proporsi', () {
      final faceDimas = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.36,
        mouthToNoseRatio: 0.31,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // Wajah orang lain (proporsi berbeda: mata lebih rapat, rasio hidung berbeda)
      final faceOrangLain = EnrolledFaceMetrics(
        faceAspectRatio: 1.62,
        eyeDistanceRatio: 0.31,
        noseToEyeRatio: 0.45,
        mouthToNoseRatio: 0.24,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      final diff = faceOrangLain.computeDifference(faceDimas);

      // Threshold baru adalah 0.22 (22%)
      // Wajah orang lain harus memiliki deviasi > 0.22 sehingga otomatis DITOLAK
      expect(diff > 0.22, isTrue,
          reason: 'Deviasi wajah orang lain ($diff) harus > 0.22 agar ditolak.');
    });

    test('Wajah pemilik akun yang sama dengan sedikit toleransi ekspresi tetap diterima', () {
      final faceDimasAsli = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.36,
        mouthToNoseRatio: 0.31,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // Wajah Dimas saat sedikit tersenyum / jarak kamera berbeda tipis
      final faceDimasKunjunganBerikutnya = EnrolledFaceMetrics(
        faceAspectRatio: 1.38,
        eyeDistanceRatio: 0.41,
        noseToEyeRatio: 0.35,
        mouthToNoseRatio: 0.32,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      final diff = faceDimasKunjunganBerikutnya.computeDifference(faceDimasAsli);

      // Harus lolos (< 0.22)
      expect(diff <= 0.22, isTrue,
          reason: 'Wajah pemilik sah ($diff) harus <= 0.22 agar berhasil login.');
    });

    test('Penghapusan Face ID untuk User A tidak memengaruhi User B', () async {
      final bioService = FaceBiometricService.instance;

      final dummyMetrics = EnrolledFaceMetrics(
        faceAspectRatio: 1.3,
        eyeDistanceRatio: 0.4,
        noseToEyeRatio: 0.35,
        mouthToNoseRatio: 0.3,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      await bioService.saveEnrolledFace(
        metrics: dummyMetrics,
        userName: 'User A',
        userEmail: 'user_a@foodie.id',
      );
      await bioService.saveEnrolledFace(
        metrics: dummyMetrics,
        userName: 'User B',
        userEmail: 'user_b@foodie.id',
      );

      // Hapus hanya User A
      await bioService.removeEnrolledFace(email: 'user_a@foodie.id');

      expect(await bioService.isFaceEnrolled(email: 'user_a@foodie.id'), isFalse);
      expect(await bioService.isFaceEnrolled(email: 'user_b@foodie.id'), isTrue);
    });
  });

  group('PENGUJIAN MASALAH 2: Sinkronisasi Sesi & Profil Setelah Logout', () {
    test('Logout membersihkan residual cache display_name dan mereset profil', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulasi User A login dan mengedit display name
      await prefs.setString('foodie_current_display_name', 'Dimas Dananjaya (Akun A)');
      await prefs.setString('foodie_name_uid_user_a', 'Dimas Dananjaya (Akun A)');
      SupabaseService.instance.curatorName = 'Dimas Dananjaya (Akun A)';

      // User A melakukan Logout
      await SupabaseService.instance.signOut();

      // 1. Pastikan key residual global foodie_current_display_name terhapus
      expect(prefs.containsKey('foodie_current_display_name'), isFalse,
          reason: 'foodie_current_display_name harus dihapus saat signOut');

      // 2. Pastikan curatorName kembali ke default netral
      expect(SupabaseService.instance.curatorName, equals('Kurator Rasa'));

      // 3. User B login dengan UID baru (uid_user_b)
      SupabaseService.instance.setDemoUser('siti@foodie.id');

      // 4. getProfile() sekarang membaca profil User B, TIDAK mencemari nama User A
      final profileB = await SupabaseService.instance.getProfile();
      expect(profileB, isNotNull);
      expect(profileB!.displayName, equals('siti'),
          reason: 'Profil User B harus menampilkan nama akun User B (siti), BUKAN nama User A');
    });
  });
}
