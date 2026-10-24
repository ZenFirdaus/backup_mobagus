import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/face_biometric_service.dart';
import 'package:flutter_application_1/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PENGUJIAN FITUR 1: Satu Akun Hanya Terikat 1 Face ID Pendaftar Asli', () {
    test('Face ID terikat khusus ke akun pengguna yang mendaftar', () async {
      final bioService = FaceBiometricService.instance;

      final metricsUserA = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.78,
        mouthToNoseRatio: 0.45,
        mouthWidthRatio: 0.85,
        noseAngle: 58.0,
        cheekWidthRatio: 2.1,
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
      expect(loadedMetricsA.noseAngle, closeTo(58.0, 0.001));
    });

    test('Triangulasi Face ID menolak wajah orang lain yang berbeda anatomi', () {
      final faceDimas = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.78,
        mouthToNoseRatio: 0.45,
        mouthWidthRatio: 0.85,
        noseAngle: 58.0,
        cheekWidthRatio: 2.1,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // Wajah orang lain (sudut segitiga hidung berbeda: 51 derajat vs 58 derajat, mulut lebih lebar)
      final faceOrangLain = EnrolledFaceMetrics(
        faceAspectRatio: 1.36,
        eyeDistanceRatio: 0.43,
        noseToEyeRatio: 0.88, // hidung lebih panjang
        mouthToNoseRatio: 0.52,
        mouthWidthRatio: 0.98, // mulut lebih lebar
        noseAngle: 51.0,      // sudut segitiga hidung berbeda signifikan
        cheekWidthRatio: 2.3,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      final diff = faceOrangLain.computeDifference(faceDimas);

      // Wajah orang lain harus ditolak total (diff = 1.0) atau > 0.065
      expect(diff > 0.065, isTrue,
          reason: 'Deviasi wajah orang lain ($diff) harus > 0.065 agar ditolak.');
    });

    test('Wajah tanpa landmark esensial valid otomatis ditolak (mencegah bypass aspect ratio)', () {
      final faceValid = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.78,
        mouthToNoseRatio: 0.45,
        mouthWidthRatio: 0.85,
        noseAngle: 58.0,
        cheekWidthRatio: 2.1,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // Wajah tanpa landmark (hanya bounding box, landmark 0.0)
      final faceTanpaLandmark = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.0,
        noseToEyeRatio: 0.0,
        mouthToNoseRatio: 0.0,
        mouthWidthRatio: 0.0,
        noseAngle: 0.0,
        cheekWidthRatio: 0.0,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      expect(faceTanpaLandmark.hasValidLandmarks, isFalse);
      final diff = faceTanpaLandmark.computeDifference(faceValid);
      expect(diff, equals(1.0),
          reason: 'Wajah tanpa landmark harus menghasilkan selisih 1.0 (ditolak total)');
    });

    test('Wajah pemilik akun yang sama dengan sedikit variasi alami tetap diterima', () {
      final faceDimasAsli = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.78,
        mouthToNoseRatio: 0.45,
        mouthWidthRatio: 0.85,
        noseAngle: 58.0,
        cheekWidthRatio: 2.1,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      // Wajah Dimas saat sedikit tersenyum / jarak kamera berbeda tipis
      final faceDimasKunjunganBerikutnya = EnrolledFaceMetrics(
        faceAspectRatio: 1.36,
        eyeDistanceRatio: 0.418,
        noseToEyeRatio: 0.785,
        mouthToNoseRatio: 0.455,
        mouthWidthRatio: 0.86,
        noseAngle: 58.4,
        cheekWidthRatio: 2.12,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );

      final diff = faceDimasKunjunganBerikutnya.computeDifference(faceDimasAsli);

      // Harus lolos (<= 0.065)
      expect(diff <= 0.065, isTrue,
          reason: 'Wajah pemilik sah ($diff) harus <= 0.065 agar berhasil masuk.');
    });
  });

  group('PENGUJIAN FITUR 2: Login Biometrik Tetap Aktif Setelah Logout Tanpa Merusak Akun Lain', () {
    test('Logout mempertahankan data Face ID pendaftar agar bisa login biometrik kembali', () async {
      final prefs = await SharedPreferences.getInstance();
      final bioService = FaceBiometricService.instance;

      // User A mendaftar Face ID
      final metricsUserA = EnrolledFaceMetrics(
        faceAspectRatio: 1.35,
        eyeDistanceRatio: 0.42,
        noseToEyeRatio: 0.78,
        mouthToNoseRatio: 0.45,
        mouthWidthRatio: 0.85,
        noseAngle: 58.0,
        cheekWidthRatio: 2.1,
        headAngleY: 0.0,
        enrolledAt: DateTime.now().toIso8601String(),
      );
      await bioService.saveEnrolledFace(
        metrics: metricsUserA,
        userName: 'Dimas Dananjaya',
        userEmail: 'dimas@foodie.id',
        password: 'passwordDimas123',
      );

      await prefs.setString('foodie_current_display_name', 'Dimas Dananjaya (Akun A)');
      SupabaseService.instance.curatorName = 'Dimas Dananjaya (Akun A)';

      // User A melakukan Logout
      await SupabaseService.instance.signOut();

      // 1. Cache display name sementara terhapus agar bersih
      expect(prefs.containsKey('foodie_current_display_name'), isFalse,
          reason: 'foodie_current_display_name harus dibersihkan saat logout');
      expect(SupabaseService.instance.curatorName, equals('Kurator Rasa'));

      // 2. Akun biometrik User A TETAP tersimpan agar User A BISA LOGIN BIOMETRIK KEMBALI
      final activeAccount = await bioService.getActiveBiometricAccount();
      expect(activeAccount, isNotNull,
          reason: 'Akun biometrik harus tetap terdaftar agar pengguna bisa login dengan Face ID setelah logout');
      expect(activeAccount!['email'], equals('dimas@foodie.id'));
      expect(activeAccount['name'], equals('Dimas Dananjaya'));

      // 3. User A tetap terdaftar Face ID
      final isEnrolled = await bioService.isFaceEnrolled(email: 'dimas@foodie.id');
      expect(isEnrolled, isTrue,
          reason: 'Face ID User A harus tetap aktif agar bisa login Face ID');
    });

    test('User B yang login setelah User A logout membaca profilnya sendiri dan tidak memakai Face ID User A', () async {
      final prefs = await SharedPreferences.getInstance();

      // Set profil khusus User A
      await prefs.setString('foodie_name_uid_user_a', 'Dimas Dananjaya');

      // User B login dengan email siti@foodie.id
      SupabaseService.instance.setDemoUser('siti@foodie.id');

      // getProfile membaca profil User B
      final profileB = await SupabaseService.instance.getProfile();
      expect(profileB, isNotNull);
      expect(profileB!.displayName, equals('siti'),
          reason: 'Profil User B harus menampilkan nama akun User B (siti), BUKAN nama User A');

      // Cek apakah User B memiliki Face ID
      final isEnrolledB = await FaceBiometricService.instance.isFaceEnrolled(email: 'siti@foodie.id');
      expect(isEnrolledB, isFalse,
          reason: 'User B belum mendaftar Face ID, sehingga tidak boleh otomatis bisa login Face ID');
    });
  });
}
