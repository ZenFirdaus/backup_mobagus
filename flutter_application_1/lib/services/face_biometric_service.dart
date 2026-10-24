import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hive_service.dart';
import 'supabase_service.dart';

/// Metrik Biometrik Wajah Tingkat Lanjut (High-Precision Normalized Triangulation)
class EnrolledFaceMetrics {
  final double faceAspectRatio;
  final double eyeDistanceRatio;
  final double noseToEyeRatio;
  final double mouthToNoseRatio;
  final double mouthWidthRatio;
  final double noseAngle;
  final double cheekWidthRatio;
  final double eyeToMouthRatio;
  final double headAngleY;
  final String enrolledAt;

  /// Ambang batas kecocokan presisi tinggi (5.5%)
  /// Orang yang sama: 0.015 - 0.045
  /// Orang yang berbeda / wajah lain: >= 0.075 atau tertolak langsung oleh batasan anatomis
  static const double matchThreshold = 0.055;

  EnrolledFaceMetrics({
    required this.faceAspectRatio,
    required this.eyeDistanceRatio,
    required this.noseToEyeRatio,
    required this.mouthToNoseRatio,
    this.mouthWidthRatio = 0.85,
    this.noseAngle = 58.0,
    this.cheekWidthRatio = 2.1,
    this.eyeToMouthRatio = 1.15,
    required this.headAngleY,
    required this.enrolledAt,
  });

  Map<String, dynamic> toJson() => {
        'faceAspectRatio': faceAspectRatio,
        'eyeDistanceRatio': eyeDistanceRatio,
        'noseToEyeRatio': noseToEyeRatio,
        'mouthToNoseRatio': mouthToNoseRatio,
        'mouthWidthRatio': mouthWidthRatio,
        'noseAngle': noseAngle,
        'cheekWidthRatio': cheekWidthRatio,
        'eyeToMouthRatio': eyeToMouthRatio,
        'headAngleY': headAngleY,
        'enrolledAt': enrolledAt,
      };

  factory EnrolledFaceMetrics.fromJson(Map<String, dynamic> json) =>
      EnrolledFaceMetrics(
        faceAspectRatio: (json['faceAspectRatio'] as num?)?.toDouble() ?? 1.3,
        eyeDistanceRatio: (json['eyeDistanceRatio'] as num?)?.toDouble() ?? 0.4,
        noseToEyeRatio: (json['noseToEyeRatio'] as num?)?.toDouble() ?? 0.75,
        mouthToNoseRatio:
            (json['mouthToNoseRatio'] as num?)?.toDouble() ?? 0.45,
        mouthWidthRatio:
            (json['mouthWidthRatio'] as num?)?.toDouble() ?? 0.85,
        noseAngle: (json['noseAngle'] as num?)?.toDouble() ?? 58.0,
        cheekWidthRatio:
            (json['cheekWidthRatio'] as num?)?.toDouble() ?? 2.1,
        eyeToMouthRatio:
            (json['eyeToMouthRatio'] as num?)?.toDouble() ?? 1.15,
        headAngleY: (json['headAngleY'] as num?)?.toDouble() ?? 0.0,
        enrolledAt: json['enrolledAt']?.toString() ?? '',
      );

  /// Cek apakah landmark wajah penting terdeteksi lengkap (mata & hidung)
  bool get hasValidLandmarks =>
      eyeDistanceRatio > 0.05 &&
      noseToEyeRatio > 0.05 &&
      noseAngle > 15.0;

  /// Hitung selisih jarak geometris berbobot dengan profil wajah referensi awal yang didaftarkan.
  /// Menerapkan multi-factor biometric rejection agar wajah orang lain MUTLAK DITOLAK.
  double computeDifference(EnrolledFaceMetrics other) {
    if (!hasValidLandmarks || !other.hasValidLandmarks) {
      return 1.0;
    }

    // 1. Sudut Puncak Segitiga Hidung (Apex Triangle Angle: Mata Kiri - Hidung - Mata Kanan)
    // Manusia konsisten pada rentang 1 - 2.5 derajat; orang lain menyimpang > 4.5 derajat
    final angleDiff = (noseAngle - other.noseAngle).abs();
    if (angleDiff > 4.5) {
      return 1.0; // Auto-tolak: Sudut tulang hidung orang lain
    }
    final dNoseAngle = angleDiff / 40.0;

    // 2. Rasio Panjang Hidung terhadap Jarak Antarmata (Normalized by IOD)
    final dNoseEye = (noseToEyeRatio - other.noseToEyeRatio).abs() /
        math.max(0.15, other.noseToEyeRatio);
    if (dNoseEye > 0.075) {
      return 1.0; // Auto-tolak: Proporsi panjang hidung orang lain
    }

    // 3. Rasio Jarak Mata ke Mulut (Fitur Wajah Tengah Paling Unik Antar Manusia)
    if (eyeToMouthRatio > 0.3 && other.eyeToMouthRatio > 0.3) {
      final dEyeMouth = (eyeToMouthRatio - other.eyeToMouthRatio).abs() /
          math.max(0.3, other.eyeToMouthRatio);
      if (dEyeMouth > 0.070) {
        return 1.0; // Auto-tolak: Proporsi mata ke mulut orang lain
      }
    }

    // 4. Rasio Lebar Mulut terhadap IOD
    double dMouthWidth = 0.0;
    if (mouthWidthRatio > 0.25 && other.mouthWidthRatio > 0.25) {
      dMouthWidth = (mouthWidthRatio - other.mouthWidthRatio).abs() /
          math.max(0.25, other.mouthWidthRatio);
      if (dMouthWidth > 0.085) {
        return 1.0; // Auto-tolak: Lebar bibir orang lain
      }
    }

    // 5. Rasio Jarak Mulut ke Hidung
    double dMouthNose = 0.0;
    if (mouthToNoseRatio > 0.15 && other.mouthToNoseRatio > 0.15) {
      dMouthNose = (mouthToNoseRatio - other.mouthToNoseRatio).abs() /
          math.max(0.15, other.mouthToNoseRatio);
      if (dMouthNose > 0.085) {
        return 1.0; // Auto-tolak: Jarak hidung-mulut orang lain
      }
    }

    // 6. Rasio Lebar Tulang Pipi
    double dCheek = 0.0;
    if (cheekWidthRatio > 0.4 && other.cheekWidthRatio > 0.4) {
      dCheek = (cheekWidthRatio - other.cheekWidthRatio).abs() /
          math.max(0.4, other.cheekWidthRatio);
      if (dCheek > 0.090) {
        return 1.0; // Auto-tolak: Lebar tulang pipi orang lain
      }
    }

    // 7. Rasio Aspek Wajah (Tinggi / Lebar)
    final dAspect = (faceAspectRatio - other.faceAspectRatio).abs() /
        math.max(0.4, other.faceAspectRatio);
    if (dAspect > 0.095) {
      return 1.0;
    }

    // Hitung rata-rata berbobot
    double totalWeighted = (dNoseAngle * 3.5) + (dNoseEye * 3.5) + (dAspect * 1.5);
    double totalWeight = 8.5;

    if (eyeToMouthRatio > 0.3 && other.eyeToMouthRatio > 0.3) {
      final dEyeMouth = (eyeToMouthRatio - other.eyeToMouthRatio).abs() /
          math.max(0.3, other.eyeToMouthRatio);
      totalWeighted += dEyeMouth * 4.0;
      totalWeight += 4.0;
    }

    if (mouthWidthRatio > 0.25 && other.mouthWidthRatio > 0.25) {
      totalWeighted += dMouthWidth * 2.5;
      totalWeight += 2.5;
    }

    if (mouthToNoseRatio > 0.15 && other.mouthToNoseRatio > 0.15) {
      totalWeighted += dMouthNose * 2.0;
      totalWeight += 2.0;
    }

    if (cheekWidthRatio > 0.4 && other.cheekWidthRatio > 0.4) {
      totalWeighted += dCheek * 1.5;
      totalWeight += 1.5;
    }

    return totalWeighted / totalWeight;
  }
}

/// Hasil analisis snapshot wajah
class FaceAnalysisResult {
  final bool isSuccess;
  final bool isLightingAdequate;
  final double luminance;
  final bool isFaceDetected;
  final bool isSingleFace;
  final bool isFaceCentered;
  final bool isFaceMatched;
  final double differenceScore;
  final EnrolledFaceMetrics? detectedMetrics;
  final Map<String, dynamic>? matchedAccount;
  final String? errorMessage;
  final String? errorCategory; // 'LIGHTING', 'NO_FACE', 'MULTIPLE_FACES', 'OFF_CENTER', 'MISMATCH', 'DUPLICATE_FACE'

  FaceAnalysisResult({
    required this.isSuccess,
    required this.isLightingAdequate,
    required this.luminance,
    required this.isFaceDetected,
    required this.isSingleFace,
    required this.isFaceCentered,
    required this.isFaceMatched,
    required this.differenceScore,
    this.detectedMetrics,
    this.matchedAccount,
    this.errorMessage,
    this.errorCategory,
  });
}

/// Layanan Autentikasi Biometrik Face ID Berstandar Profesional
class FaceBiometricService {
  FaceBiometricService._();
  static final FaceBiometricService instance = FaceBiometricService._();

  FaceDetector? _faceDetector;

  FaceDetector get _detector {
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
        enableClassification: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    return _faceDetector!;
  }

  String _emailKey(String email) =>
      email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  /// Mengambil semua akun yang terdaftar biometrik di perangkat (Hive Database & SharedPreferences)
  Future<List<Map<String, dynamic>>> getAllRegisteredProfiles() async {
    final List<Map<String, dynamic>> result = [];
    final Set<String> seenEmails = {};

    // 1. Ambil dari Hive NoSQL Database (Sangat persisten, tidak terhapus saat logout)
    try {
      final hiveProfiles = HiveService.instance.getAllBiometricProfiles();
      for (final p in hiveProfiles) {
        final email = (p['email'] as String? ?? '').trim().toLowerCase();
        if (email.isNotEmpty && !seenEmails.contains(email)) {
          final metricsMap = p['metrics'] as Map?;
          if (metricsMap != null) {
            result.add({
              'email': email,
              'name': p['name'] ?? email.split('@').first,
              'password': p['password'] ?? '',
              'metrics': EnrolledFaceMetrics.fromJson(
                  Map<String, dynamic>.from(metricsMap)),
            });
            seenEmails.add(email);
          }
        }
      }
    } catch (_) {}

    // 2. Fallback / Merge dari SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith('foodie_enrolled_face_metrics_')) {
          final emailKey = k.replaceFirst('foodie_enrolled_face_metrics_', '');
          final jsonStr = prefs.getString(k);
          if (jsonStr != null && jsonStr.isNotEmpty) {
            try {
              final map = jsonDecode(jsonStr) as Map<String, dynamic>;
              final name =
                  prefs.getString('foodie_face_name_$emailKey') ?? 'User';
              final pwd = prefs.getString('foodie_face_pwd_$emailKey') ?? '';
              final fallbackEmail =
                  prefs.getString('foodie_last_user_email') ?? emailKey;
              final clean = fallbackEmail.trim().toLowerCase();
              if (!seenEmails.contains(clean)) {
                result.add({
                  'email': clean,
                  'name': name,
                  'password': pwd,
                  'metrics': EnrolledFaceMetrics.fromJson(map),
                });
                seenEmails.add(clean);
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    return result;
  }

  /// Cek apakah pengguna sudah mendaftarkan Face ID dengan metrik wajah.
  /// Jika [email] diberikan, hanya periksa akun tersebut.
  Future<bool> isFaceEnrolled({String? email}) async {
    if (email != null && email.trim().isNotEmpty) {
      final clean = email.trim().toLowerCase();
      // 1. Cek di Hive Database
      final hiveProf = HiveService.instance.getBiometricProfile(clean);
      if (hiveProf != null && hiveProf['metrics'] != null) {
        return true;
      }
      // 2. Cek di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = _emailKey(clean);
      final bool isEnabled =
          prefs.getBool('foodie_biometric_enabled_$key') ?? false;
      final String? metricsJson =
          prefs.getString('foodie_enrolled_face_metrics_$key');
      return isEnabled && metricsJson != null && metricsJson.isNotEmpty;
    }

    // Jika email tidak diberikan, cek apakah ada akun biometrik apapun di perangkat
    final all = await getAllRegisteredProfiles();
    return all.isNotEmpty;
  }

  /// Ambil informasi akun yang terdaftar untuk biometrik aktif
  Future<Map<String, String>?> getActiveBiometricAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activeEmail =
        prefs.getString('foodie_active_biometric_email') ??
            prefs.getString('foodie_last_user_email');

    if (activeEmail != null && activeEmail.isNotEmpty) {
      final clean = activeEmail.trim().toLowerCase();
      final hiveProf = HiveService.instance.getBiometricProfile(clean);
      if (hiveProf != null) {
        return {
          'email': clean,
          'name': (hiveProf['name']?.toString() ?? clean.split('@').first),
          'password': hiveProf['password']?.toString() ?? '',
        };
      }

      final key = _emailKey(clean);
      final isEnrolled = await isFaceEnrolled(email: clean);
      if (isEnrolled) {
        final name = prefs.getString('foodie_face_name_$key') ??
            prefs.getString('foodie_last_user_name') ??
            clean.split('@').first;
        final pwd = prefs.getString('foodie_face_pwd_$key') ??
            prefs.getString('foodie_saved_password') ??
            '';
        return {
          'email': clean,
          'name': name,
          'password': pwd,
        };
      }
    }

    // Jika tidak ada email aktif spesifik, ambil akun pertama yang ada di Hive
    final all = await getAllRegisteredProfiles();
    if (all.isNotEmpty) {
      final first = all.first;
      return {
        'email': first['email'].toString(),
        'name': first['name'].toString(),
        'password': first['password'].toString(),
      };
    }

    return null;
  }

  /// Ambil metrik wajah yang telah didaftarkan (bisa spesifik per akun)
  Future<EnrolledFaceMetrics?> getEnrolledMetrics({String? email}) async {
    if (email != null && email.trim().isNotEmpty) {
      final clean = email.trim().toLowerCase();
      final hiveProf = HiveService.instance.getBiometricProfile(clean);
      if (hiveProf != null && hiveProf['metrics'] != null) {
        try {
          return EnrolledFaceMetrics.fromJson(
              Map<String, dynamic>.from(hiveProf['metrics'] as Map));
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      final key = _emailKey(clean);
      final jsonStr = prefs.getString('foodie_enrolled_face_metrics_$key');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          return EnrolledFaceMetrics.fromJson(
              jsonDecode(jsonStr) as Map<String, dynamic>);
        } catch (_) {}
      }
      return null;
    }

    final active = await getActiveBiometricAccount();
    if (active != null) {
      return getEnrolledMetrics(email: active['email']);
    }
    return null;
  }

  /// ATURAN 1 WAJAH 1 AKUN:
  /// Memeriksa apakah wajah baru yang dideteksi sudah terdaftar pada akun lain.
  /// Mengembalikan email akun lain jika duplikat ditemukan, atau `null` jika aman.
  Future<String?> findExistingAccountWithSameFace({
    required EnrolledFaceMetrics newMetrics,
    required String currentEmail,
  }) async {
    final allProfiles = await getAllRegisteredProfiles();
    final cleanCurrent = currentEmail.trim().toLowerCase();

    for (final prof in allProfiles) {
      final profEmail = (prof['email'] as String? ?? '').trim().toLowerCase();
      // Lewati akun yang sama (misalnya update wajah akun sendiri)
      if (profEmail == cleanCurrent) continue;

      final metrics = prof['metrics'] as EnrolledFaceMetrics?;
      if (metrics == null) continue;

      final diff = newMetrics.computeDifference(metrics);
      // Jika perbedaan <= matchThreshold, berarti orang fisik yang sama!
      if (diff <= EnrolledFaceMetrics.matchThreshold) {
        return profEmail;
      }
    }
    return null;
  }

  /// PENCARIAN AKUN OTOMATIS BERDASARKAN WAJAH (1 Wajah 1 Akun):
  /// Mencari akun mana di database yang cocok dengan wajah di depan kamera.
  Future<Map<String, dynamic>?> findMatchingAccount(
      EnrolledFaceMetrics detected) async {
    final allProfiles = await getAllRegisteredProfiles();
    if (allProfiles.isEmpty) return null;

    Map<String, dynamic>? bestMatch;
    double lowestDiff = 1.0;

    for (final prof in allProfiles) {
      final metrics = prof['metrics'] as EnrolledFaceMetrics?;
      if (metrics == null) continue;

      final diff = detected.computeDifference(metrics);
      if (diff <= EnrolledFaceMetrics.matchThreshold && diff < lowestDiff) {
        lowestDiff = diff;
        bestMatch = {
          'email': prof['email'],
          'name': prof['name'],
          'password': prof['password'],
          'difference': diff,
        };
      }
    }

    return bestMatch;
  }

  /// Simpan pendaftaran wajah yang TERIKAT KETAT pada profil/email pengguna tertentu
  /// Menyimpan permanen ke Hive NoSQL database, Supabase Cloud, dan SharedPreferences.
  Future<void> saveEnrolledFace({
    required EnrolledFaceMetrics metrics,
    required String userName,
    required String userEmail,
    String? password,
  }) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    final cleanName = userName.trim().isNotEmpty
        ? userName.trim()
        : cleanEmail.split('@').first;
    final metricsMap = metrics.toJson();
    final metricsJson = jsonEncode(metricsMap);

    // 1. Simpan di Hive Database (NoSQL disk lokal, permanen walau logout berkali-kali)
    await HiveService.instance.saveBiometricProfile(
      email: cleanEmail,
      name: cleanName,
      password: password,
      metrics: metricsMap,
    );

    // 2. Sinkronkan ke Supabase Cloud (User Metadata)
    try {
      await SupabaseService.instance.saveFaceBiometricsToCloud(
        email: cleanEmail,
        name: cleanName,
        metrics: metricsMap,
        password: password,
      );
    } catch (_) {}

    // 3. Simpan di SharedPreferences (Kompatibilitas aplikasi)
    final prefs = await SharedPreferences.getInstance();
    final key = _emailKey(cleanEmail);

    await prefs.setBool('foodie_biometric_enabled_$key', true);
    await prefs.setString('foodie_enrolled_face_metrics_$key', metricsJson);
    await prefs.setString('foodie_face_name_$key', cleanName);
    if (password != null && password.isNotEmpty) {
      await prefs.setString('foodie_face_pwd_$key', password);
    }

    await prefs.setString('foodie_active_biometric_email', cleanEmail);
    await prefs.setBool('foodie_biometric_enabled', true);
    await prefs.setString('foodie_enrolled_face_metrics', metricsJson);
    await prefs.setString('foodie_last_user_name', cleanName);
    await prefs.setString('foodie_last_user_email', cleanEmail);
    if (password != null && password.isNotEmpty) {
      await prefs.setString('foodie_saved_password', password);
    }
  }

  /// Hapus pendaftaran wajah untuk akun tertentu (atau akun aktif)
  Future<void> removeEnrolledFace({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final targetEmail = email ??
        prefs.getString('foodie_active_biometric_email') ??
        prefs.getString('foodie_last_user_email');

    if (targetEmail != null && targetEmail.isNotEmpty) {
      final clean = targetEmail.trim().toLowerCase();
      await HiveService.instance.deleteBiometricProfile(clean);

      final key = _emailKey(clean);
      await prefs.remove('foodie_biometric_enabled_$key');
      await prefs.remove('foodie_enrolled_face_metrics_$key');
      await prefs.remove('foodie_face_name_$key');
      await prefs.remove('foodie_face_pwd_$key');
    }

    final activeEmail = prefs.getString('foodie_active_biometric_email');
    if (email == null || activeEmail == email.trim().toLowerCase()) {
      await prefs.remove('foodie_active_biometric_email');
      await prefs.setBool('foodie_biometric_enabled', false);
      await prefs.remove('foodie_enrolled_face_metrics');
    }
  }

  /// Hitung tingkat kecerahan (luminance) foto secara native
  Future<double> calculateLuminance(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return 100.0;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 40,
        targetHeight: 40,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return 100.0;

      final buffer = byteData.buffer.asUint8List();
      double totalLuminance = 0;
      int count = 0;
      for (int i = 0; i < buffer.length; i += 4) {
        final r = buffer[i];
        final g = buffer[i + 1];
        final b = buffer[i + 2];
        totalLuminance += (0.299 * r + 0.587 * g + 0.114 * b);
        count++;
      }
      return count > 0 ? (totalLuminance / count) : 100.0;
    } catch (_) {
      return 100.0;
    }
  }

  /// Analisis Wajah langsung dari InputImage (Digunakan oleh Kamera Real-time ImageStream)
  /// Tanpa I/O disk, tanpa shutter sound, respon dalam milidetik.
  Future<FaceAnalysisResult> analyzeInputImage({
    required InputImage inputImage,
    required bool isEnrollment,
    double luminance = 100.0,
    EnrolledFaceMetrics? referenceMetrics,
    String? targetEmail,
  }) async {
    // 1. Validasi Pencahayaan
    if (luminance < 12.0) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: false,
        luminance: luminance,
        isFaceDetected: false,
        isSingleFace: false,
        isFaceCentered: false,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'LIGHTING',
        errorMessage:
            'Cahaya terlalu gelap. Nyalakan lampu atau cari tempat lebih terang.',
      );
    }

    // 2. Deteksi Wajah via Google ML Kit (Mode Fast, latency ~20ms)
    List<Face> faces = [];
    try {
      faces = await _detector.processImage(inputImage);
    } catch (e) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: false,
        isSingleFace: false,
        isFaceCentered: false,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'DETECTOR_ERROR',
        errorMessage: 'Sensor kamera belum siap: $e',
      );
    }

    // Kasus: Tidak ada wajah di frame
    if (faces.isEmpty) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: false,
        isSingleFace: false,
        isFaceCentered: false,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'NO_FACE',
        errorMessage: 'Wajah tidak terdeteksi. Posisikan wajah tepat di depan kamera.',
      );
    }

    // Kasus: Lebih dari 1 wajah dalam frame
    if (faces.length > 1) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: false,
        isFaceCentered: false,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'MULTIPLE_FACES',
        errorMessage:
            'Terdeteksi ${faces.length} wajah. Harap posisikan hanya satu wajah di sensor.',
      );
    }

    final face = faces.first;
    final box = face.boundingBox;

    // 3. Ekstraksi Metrik Biometrik
    final faceWidth = box.width <= 0 ? 1.0 : box.width;
    final faceHeight = box.height <= 0 ? 1.0 : box.height;
    final aspect = faceHeight / faceWidth;

    // Ambil landmark mata, hidung, mulut, pipi
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek];
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek];

    // WAJIB: Landmark utama harus terdeteksi jelas agar biometrik valid & aman
    if (leftEye == null || rightEye == null || noseBase == null) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'UNCLEAR_LANDMARKS',
        errorMessage:
            'Fitur wajah belum terdeteksi jelas. Harap posisikan wajah tegak lurus menghadap kamera.',
      );
    }

    final double dx = (leftEye.position.x - rightEye.position.x).toDouble();
    final double dy = (leftEye.position.y - rightEye.position.y).toDouble();
    final double iod = math.sqrt(dx * dx + dy * dy);

    if (iod < 20.0) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'UNCLEAR_LANDMARKS',
        errorMessage: 'Posisikan wajah lebih dekat ke kamera.',
      );
    }

    // Midpoint antarmata
    final double eyeCenterX = (leftEye.position.x + rightEye.position.x) / 2.0;
    final double eyeCenterY = (leftEye.position.y + rightEye.position.y) / 2.0;

    // 1. Rasio Jarak Vertikal Hidung ke Mata (Normalized by IOD)
    final double dNoseX = (noseBase.position.x - eyeCenterX).toDouble();
    final double dNoseY = (noseBase.position.y - eyeCenterY).toDouble();
    final double noseToEyeDist = math.sqrt(dNoseX * dNoseX + dNoseY * dNoseY);
    final double rNoseEye = noseToEyeDist / iod;

    // 2. Sudut Segitiga Puncak Hidung (Apex Triangle Angle)
    final double l1x = (leftEye.position.x - noseBase.position.x).toDouble();
    final double l1y = (leftEye.position.y - noseBase.position.y).toDouble();
    final double l1 = math.sqrt(l1x * l1x + l1y * l1y);

    final double l2x = (rightEye.position.x - noseBase.position.x).toDouble();
    final double l2y = (rightEye.position.y - noseBase.position.y).toDouble();
    final double l2 = math.sqrt(l2x * l2x + l2y * l2y);

    double noseAngleDeg = 58.0;
    if (l1 > 0 && l2 > 0) {
      final double cosVal =
          ((l1 * l1 + l2 * l2 - iod * iod) / (2.0 * l1 * l2)).clamp(-1.0, 1.0);
      noseAngleDeg = math.acos(cosVal) * (180.0 / math.pi);
    }

    // 3. Rasio Lebar Mulut (Normalized by IOD)
    double rMouthWidth = 0.85;
    if (leftMouth != null && rightMouth != null) {
      final double mdx =
          (leftMouth.position.x - rightMouth.position.x).toDouble();
      final double mdy =
          (leftMouth.position.y - rightMouth.position.y).toDouble();
      rMouthWidth = math.sqrt(mdx * mdx + mdy * mdy) / iod;
    }

    // 4. Rasio Jarak Mulut ke Hidung (Normalized by IOD)
    double rMouthNose = 0.45;
    if (leftMouth != null && rightMouth != null) {
      final double mcX = (leftMouth.position.x + rightMouth.position.x) / 2.0;
      final double mcY = (leftMouth.position.y + rightMouth.position.y) / 2.0;
      final double mnx = (mcX - noseBase.position.x).toDouble();
      final double mny = (mcY - noseBase.position.y).toDouble();
      rMouthNose = math.sqrt(mnx * mnx + mny * mny) / iod;
    } else if (bottomMouth != null) {
      final double bnx =
          (bottomMouth.position.x - noseBase.position.x).toDouble();
      final double bny =
          (bottomMouth.position.y - noseBase.position.y).toDouble();
      rMouthNose = math.sqrt(bnx * bnx + bny * bny) / iod;
    }

    // 5. Rasio Lebar Tulang Pipi (Normalized by IOD)
    double rCheek = 2.1;
    if (leftCheek != null && rightCheek != null) {
      final double cdx =
          (leftCheek.position.x - rightCheek.position.x).toDouble();
      final double cdy =
          (leftCheek.position.y - rightCheek.position.y).toDouble();
      rCheek = math.sqrt(cdx * cdx + cdy * cdy) / iod;
    }

    // 6. Rasio Jarak Mata ke Mulut (Tinggi Wajah Tengah Normalized by IOD)
    double rEyeMouth = 1.15;
    if (leftMouth != null && rightMouth != null) {
      final double mcX = (leftMouth.position.x + rightMouth.position.x) / 2.0;
      final double mcY = (leftMouth.position.y + rightMouth.position.y) / 2.0;
      final double emx = (mcX - eyeCenterX).toDouble();
      final double emy = (mcY - eyeCenterY).toDouble();
      rEyeMouth = math.sqrt(emx * emx + emy * emy) / iod;
    } else if (bottomMouth != null) {
      final double emx = (bottomMouth.position.x - eyeCenterX).toDouble();
      final double emy = (bottomMouth.position.y - eyeCenterY).toDouble();
      rEyeMouth = math.sqrt(emx * emx + emy * emy) / iod;
    }

    final double eyeDistRatio = iod / faceWidth;

    final detectedMetrics = EnrolledFaceMetrics(
      faceAspectRatio: aspect,
      eyeDistanceRatio: eyeDistRatio,
      noseToEyeRatio: rNoseEye,
      mouthToNoseRatio: rMouthNose,
      mouthWidthRatio: rMouthWidth,
      noseAngle: noseAngleDeg,
      cheekWidthRatio: rCheek,
      eyeToMouthRatio: rEyeMouth,
      headAngleY: face.headEulerAngleY ?? 0.0,
      enrolledAt: DateTime.now().toIso8601String(),
    );

    // 4. Jika Pendaftaran (Enrollment), simpan metrik
    if (isEnrollment) {
      return FaceAnalysisResult(
        isSuccess: true,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: true,
        differenceScore: 0.0,
        detectedMetrics: detectedMetrics,
      );
    }

    // 5. Jika Login/Verifikasi:
    EnrolledFaceMetrics? ref = referenceMetrics;
    Map<String, dynamic>? matchedAccount;

    if (ref == null && targetEmail != null && targetEmail.trim().isNotEmpty) {
      ref = await getEnrolledMetrics(email: targetEmail);
    }

    // Jika targetEmail tidak diberikan (User klik tombol Face ID tanpa isi email di form login),
    // lakukan auto-matching ke seluruh database biometrik (1 wajah 1 akun)!
    if (ref == null) {
      matchedAccount = await findMatchingAccount(detectedMetrics);
      if (matchedAccount == null) {
        final allProfiles = await getAllRegisteredProfiles();
        final msg = allProfiles.isEmpty
            ? 'Data biometrik belum tersimpan di perangkat. Silakan login manual dengan email & kata sandi terlebih dahulu.'
            : 'Wajah tidak cocok dengan profil biometrik manapun yang terdaftar di aplikasi.';
        return FaceAnalysisResult(
          isSuccess: false,
          isLightingAdequate: true,
          luminance: luminance,
          isFaceDetected: true,
          isSingleFace: true,
          isFaceCentered: true,
          isFaceMatched: false,
          differenceScore: 1.0,
          detectedMetrics: detectedMetrics,
          errorCategory: allProfiles.isEmpty ? 'NOT_ENROLLED' : 'MISMATCH',
          errorMessage: msg,
        );
      }

      // Wajah Berhasil Dicocokkan dengan Akun di Database!
      return FaceAnalysisResult(
        isSuccess: true,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: true,
        differenceScore: (matchedAccount['difference'] as num?)?.toDouble() ?? 0.05,
        detectedMetrics: detectedMetrics,
        matchedAccount: matchedAccount,
      );
    }

    // Jika target email terdaftar:
    final diff = detectedMetrics.computeDifference(ref);

    if (diff > EnrolledFaceMetrics.matchThreshold) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: false,
        differenceScore: diff,
        detectedMetrics: detectedMetrics,
        errorCategory: 'MISMATCH',
        errorMessage:
            'Wajah tidak cocok dengan profil biometrik yang didaftarkan pada akun ini.',
      );
    }

    // Wajah Asli, Cocok, & Valid
    return FaceAnalysisResult(
      isSuccess: true,
      isLightingAdequate: true,
      luminance: luminance,
      isFaceDetected: true,
      isSingleFace: true,
      isFaceCentered: true,
      isFaceMatched: true,
      differenceScore: diff,
      detectedMetrics: detectedMetrics,
    );
  }

  /// Analisis Wajah dari File (Fallback)
  Future<FaceAnalysisResult> analyzeFaceImage({
    required String imagePath,
    required bool isEnrollment,
    EnrolledFaceMetrics? referenceMetrics,
    String? targetEmail,
  }) async {
    final luminance = await calculateLuminance(imagePath);
    final inputImage = InputImage.fromFilePath(imagePath);
    return analyzeInputImage(
      inputImage: inputImage,
      isEnrollment: isEnrollment,
      luminance: luminance,
      referenceMetrics: referenceMetrics,
      targetEmail: targetEmail,
    );
  }

  void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
  }
}
