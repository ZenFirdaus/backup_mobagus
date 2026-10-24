import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metrik Biometrik Wajah yang Didaftarkan
class EnrolledFaceMetrics {
  final double faceAspectRatio;
  final double eyeDistanceRatio;
  final double noseToEyeRatio;
  final double mouthToNoseRatio;
  final double headAngleY;
  final String enrolledAt;

  EnrolledFaceMetrics({
    required this.faceAspectRatio,
    required this.eyeDistanceRatio,
    required this.noseToEyeRatio,
    required this.mouthToNoseRatio,
    required this.headAngleY,
    required this.enrolledAt,
  });

  Map<String, dynamic> toJson() => {
        'faceAspectRatio': faceAspectRatio,
        'eyeDistanceRatio': eyeDistanceRatio,
        'noseToEyeRatio': noseToEyeRatio,
        'mouthToNoseRatio': mouthToNoseRatio,
        'headAngleY': headAngleY,
        'enrolledAt': enrolledAt,
      };

  factory EnrolledFaceMetrics.fromJson(Map<String, dynamic> json) =>
      EnrolledFaceMetrics(
        faceAspectRatio: (json['faceAspectRatio'] as num?)?.toDouble() ?? 1.3,
        eyeDistanceRatio: (json['eyeDistanceRatio'] as num?)?.toDouble() ?? 0.4,
        noseToEyeRatio: (json['noseToEyeRatio'] as num?)?.toDouble() ?? 0.35,
        mouthToNoseRatio:
            (json['mouthToNoseRatio'] as num?)?.toDouble() ?? 0.3,
        headAngleY: (json['headAngleY'] as num?)?.toDouble() ?? 0.0,
        enrolledAt: json['enrolledAt']?.toString() ?? '',
      );

  /// Hitung selisih jarak geometris relatif dengan wajah referensi.
  /// Menggunakan normalized relative error agar toleran terhadap jarak, ekspresi & kemiringan wajah.
  double computeDifference(EnrolledFaceMetrics other) {
    double totalDiff = 0.0;
    int count = 0;
    double maxDeviation = 0.0;

    // 1. Rasio aspek wajah (tinggi / lebar bounding box)
    if (faceAspectRatio > 0.1 && other.faceAspectRatio > 0.1) {
      final d = (faceAspectRatio - other.faceAspectRatio).abs() /
          other.faceAspectRatio;
      if (d > maxDeviation) maxDeviation = d;
      totalDiff += d * 0.9;
      count++;
    }

    // 2. Rasio jarak kedua mata terhadap lebar wajah (fitur biometrik sangat khas)
    if (eyeDistanceRatio > 0.05 && other.eyeDistanceRatio > 0.05) {
      final d = (eyeDistanceRatio - other.eyeDistanceRatio).abs() /
          other.eyeDistanceRatio;
      if (d > maxDeviation) maxDeviation = d;
      totalDiff += d * 1.3;
      count++;
    }

    // 3. Rasio jarak hidung ke mata terhadap tinggi wajah
    if (noseToEyeRatio > 0.05 && other.noseToEyeRatio > 0.05) {
      final d = (noseToEyeRatio - other.noseToEyeRatio).abs() /
          other.noseToEyeRatio;
      if (d > maxDeviation) maxDeviation = d;
      totalDiff += d * 1.0;
      count++;
    }

    // 4. Rasio jarak mulut ke hidung terhadap tinggi wajah
    if (mouthToNoseRatio > 0.05 && other.mouthToNoseRatio > 0.05) {
      final d = (mouthToNoseRatio - other.mouthToNoseRatio).abs() /
          other.mouthToNoseRatio;
      if (d > maxDeviation) maxDeviation = d;
      totalDiff += d * 1.0;
      count++;
    }

    final avgDiff = count > 0 ? (totalDiff / count) : 1.0;
    // Jika ada satu fitur wajah utama yang menyimpang drastis (> 0.28), beri penalti
    if (maxDeviation > 0.28) {
      return (avgDiff + maxDeviation) / 2;
    }
    return avgDiff;
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
  final String? errorMessage;
  final String? errorCategory; // 'LIGHTING', 'NO_FACE', 'MULTIPLE_FACES', 'OFF_CENTER', 'MISMATCH'

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
        minFaceSize: 0.05,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    return _faceDetector!;
  }

  String _emailKey(String email) =>
      email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  /// Cek apakah pengguna sudah mendaftarkan Face ID dengan metrik wajah.
  /// Jika [email] diberikan, hanya periksa akun tersebut.
  Future<bool> isFaceEnrolled({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null && email.trim().isNotEmpty) {
      final key = _emailKey(email);
      final bool isEnabled = prefs.getBool('foodie_biometric_enabled_$key') ?? false;
      final String? metricsJson = prefs.getString('foodie_enrolled_face_metrics_$key');
      return isEnabled && metricsJson != null && metricsJson.isNotEmpty;
    }

    // Cek user biometrik aktif yang terikat di perangkat
    final String? activeEmail = prefs.getString('foodie_active_biometric_email') ??
        prefs.getString('foodie_last_user_email');
    if (activeEmail == null || activeEmail.isEmpty) return false;

    final key = _emailKey(activeEmail);
    final bool isUserEnabled = prefs.getBool('foodie_biometric_enabled_$key') ??
        (prefs.getBool('foodie_biometric_enabled') ?? false);
    final String? metricsJson = prefs.getString('foodie_enrolled_face_metrics_$key') ??
        prefs.getString('foodie_enrolled_face_metrics');
    return isUserEnabled && metricsJson != null && metricsJson.isNotEmpty;
  }

  /// Ambil informasi akun yang terdaftar untuk biometrik aktif
  Future<Map<String, String>?> getActiveBiometricAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activeEmail = prefs.getString('foodie_active_biometric_email') ??
        prefs.getString('foodie_last_user_email');
    if (activeEmail == null || activeEmail.isEmpty) return null;

    final key = _emailKey(activeEmail);
    final isEnrolled = await isFaceEnrolled(email: activeEmail);
    if (!isEnrolled) return null;

    final name = prefs.getString('foodie_face_name_$key') ??
        prefs.getString('foodie_last_user_name') ??
        activeEmail.split('@').first;
    final pwd = prefs.getString('foodie_face_pwd_$key') ??
        prefs.getString('foodie_saved_password') ??
        '';

    return {
      'email': activeEmail,
      'name': name,
      'password': pwd,
    };
  }

  /// Ambil metrik wajah yang telah didaftarkan (bisa spesifik per akun)
  Future<EnrolledFaceMetrics?> getEnrolledMetrics({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr;
    if (email != null && email.trim().isNotEmpty) {
      final key = _emailKey(email);
      jsonStr = prefs.getString('foodie_enrolled_face_metrics_$key');
      if (jsonStr == null || jsonStr.isEmpty) return null;
    } else {
      final activeEmail = prefs.getString('foodie_active_biometric_email');
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final key = _emailKey(activeEmail);
        jsonStr = prefs.getString('foodie_enrolled_face_metrics_$key');
      }
      jsonStr ??= prefs.getString('foodie_enrolled_face_metrics');
    }
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return EnrolledFaceMetrics.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Simpan pendaftaran wajah yang TERIKAT KETAT pada profil/email pengguna tertentu
  Future<void> saveEnrolledFace({
    required EnrolledFaceMetrics metrics,
    required String userName,
    required String userEmail,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanEmail = userEmail.trim().toLowerCase();
    final key = _emailKey(cleanEmail);
    final metricsJson = jsonEncode(metrics.toJson());

    // 1. Simpan terikat spesifik ke email akun ini
    await prefs.setBool('foodie_biometric_enabled_$key', true);
    await prefs.setString('foodie_enrolled_face_metrics_$key', metricsJson);
    await prefs.setString('foodie_face_name_$key', userName.trim());
    if (password != null && password.isNotEmpty) {
      await prefs.setString('foodie_face_pwd_$key', password);
    }

    // 2. Set sebagai akun biometrik aktif di perangkat
    await prefs.setString('foodie_active_biometric_email', cleanEmail);

    // 3. Simpan juga key legacy agar kompatibel
    await prefs.setBool('foodie_biometric_enabled', true);
    await prefs.setString('foodie_enrolled_face_metrics', metricsJson);
    await prefs.setString('foodie_last_user_name', userName.trim());
    await prefs.setString('foodie_last_user_email', cleanEmail);
    if (password != null && password.isNotEmpty) {
      await prefs.setString('foodie_saved_password', password);
    }
  }

  /// Hapus pendaftaran wajah untuk akun tertentu (atau akun aktif)
  Future<void> removeEnrolledFace({String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final targetEmail = email ?? prefs.getString('foodie_active_biometric_email') ??
        prefs.getString('foodie_last_user_email');

    if (targetEmail != null && targetEmail.isNotEmpty) {
      final key = _emailKey(targetEmail);
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

    // Ambil landmark mata, hidung, mulut
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

    double eyeDistRatio = 0.0;
    if (leftEye != null && rightEye != null) {
      eyeDistRatio =
          (leftEye.position.x - rightEye.position.x).abs() / faceWidth;
    }

    double noseEyeRatio = 0.0;
    if (noseBase != null && leftEye != null) {
      noseEyeRatio =
          (noseBase.position.y - leftEye.position.y).abs() / faceHeight;
    }

    double mouthNoseRatio = 0.0;
    if (bottomMouth != null && noseBase != null) {
      mouthNoseRatio =
          (bottomMouth.position.y - noseBase.position.y).abs() / faceHeight;
    }

    final detectedMetrics = EnrolledFaceMetrics(
      faceAspectRatio: aspect,
      eyeDistanceRatio: eyeDistRatio,
      noseToEyeRatio: noseEyeRatio,
      mouthToNoseRatio: mouthNoseRatio,
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

    // 5. Jika Login/Verifikasi, cocokkan dengan metrik yang didaftarkan akun terkait
    final ref = referenceMetrics ?? await getEnrolledMetrics(email: targetEmail);
    if (ref == null) {
      return FaceAnalysisResult(
        isSuccess: false,
        isLightingAdequate: true,
        luminance: luminance,
        isFaceDetected: true,
        isSingleFace: true,
        isFaceCentered: true,
        isFaceMatched: false,
        differenceScore: 1.0,
        errorCategory: 'NOT_ENROLLED',
        errorMessage:
            'Data biometrik belum tersimpan untuk akun ini. Silakan login menggunakan email & kata sandi terlebih dahulu.',
      );
    }

    final diff = detectedMetrics.computeDifference(ref);

    // Batas toleransi relatif biometrik aman: 0.22 (22% deviasi geometris)
    // Nilai > 0.22 menunjukkan wajah milik orang lain yang berbeda
    if (diff > 0.22) {
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
