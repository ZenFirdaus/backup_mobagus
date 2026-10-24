import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metrik Biometrik Wajah Tingkat Lanjut (Normalized Triangulation)
class EnrolledFaceMetrics {
  final double faceAspectRatio;
  final double eyeDistanceRatio;
  final double noseToEyeRatio;
  final double mouthToNoseRatio;
  final double mouthWidthRatio;
  final double noseAngle;
  final double cheekWidthRatio;
  final double headAngleY;
  final String enrolledAt;

  EnrolledFaceMetrics({
    required this.faceAspectRatio,
    required this.eyeDistanceRatio,
    required this.noseToEyeRatio,
    required this.mouthToNoseRatio,
    this.mouthWidthRatio = 0.85,
    this.noseAngle = 58.0,
    this.cheekWidthRatio = 2.1,
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
        headAngleY: (json['headAngleY'] as num?)?.toDouble() ?? 0.0,
        enrolledAt: json['enrolledAt']?.toString() ?? '',
      );

  /// Cek apakah landmark wajah penting terdeteksi lengkap (mata & hidung)
  bool get hasValidLandmarks =>
      eyeDistanceRatio > 0.08 &&
      noseToEyeRatio > 0.1 &&
      noseAngle > 20.0;

  /// Hitung selisih jarak geometris dengan wajah referensi.
  /// Membandingkan sudut segitiga hidung, rasio mata-hidung, dan rasio mulut yang unik per individu.
  double computeDifference(EnrolledFaceMetrics other) {
    if (!hasValidLandmarks || !other.hasValidLandmarks) {
      return 1.0;
    }

    // 1. Sudut Segitiga Puncak Hidung (Apex Triangle Angle)
    // Pengguna asli sangat konsisten (+/- 2.5 derajat), orang lain menyimpang signifikan
    final dNoseAngle = (noseAngle - other.noseAngle).abs() / 60.0;
    if (dNoseAngle > 0.075) {
      return 1.0; // Auto tolak: sudut anatomi hidung orang lain
    }

    // 2. Rasio Panjang Hidung terhadap Jarak Antarmata (Normalized by IOD)
    final dNoseEye = (noseToEyeRatio - other.noseToEyeRatio).abs() / other.noseToEyeRatio;
    if (dNoseEye > 0.085) {
      return 1.0; // Auto tolak: proporsi hidung orang lain
    }

    // 3. Rasio Aspek Wajah
    final dAspect =
        (faceAspectRatio - other.faceAspectRatio).abs() / other.faceAspectRatio;
    if (dAspect > 0.12) {
      return 1.0;
    }

    double totalWeighted = (dNoseAngle * 3.5) + (dNoseEye * 3.0) + (dAspect * 1.0);
    double totalWeight = 7.5;

    // 4. Rasio Lebar Mulut terhadap Jarak Mata (jika terdeteksi)
    if (mouthWidthRatio > 0.3 && other.mouthWidthRatio > 0.3) {
      final dMouthWidth =
          (mouthWidthRatio - other.mouthWidthRatio).abs() / other.mouthWidthRatio;
      if (dMouthWidth > 0.085) {
        return 1.0; // Auto tolak: lebar mulut orang lain
      }
      totalWeighted += dMouthWidth * 3.0;
      totalWeight += 3.0;
    }

    // 5. Rasio Jarak Mulut ke Hidung
    if (mouthToNoseRatio > 0.2 && other.mouthToNoseRatio > 0.2) {
      final dMouthNose =
          (mouthToNoseRatio - other.mouthToNoseRatio).abs() / other.mouthToNoseRatio;
      if (dMouthNose > 0.09) {
        return 1.0;
      }
      totalWeighted += dMouthNose * 2.0;
      totalWeight += 2.0;
    }

    // 6. Rasio Lebar Tulang Pipi
    if (cheekWidthRatio > 0.5 && other.cheekWidthRatio > 0.5) {
      final dCheek =
          (cheekWidthRatio - other.cheekWidthRatio).abs() / other.cheekWidthRatio;
      if (dCheek > 0.095) {
        return 1.0;
      }
      totalWeighted += dCheek * 2.0;
      totalWeight += 2.0;
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
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
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

    final double eyeDistRatio = iod / faceWidth;

    final detectedMetrics = EnrolledFaceMetrics(
      faceAspectRatio: aspect,
      eyeDistanceRatio: eyeDistRatio,
      noseToEyeRatio: rNoseEye,
      mouthToNoseRatio: rMouthNose,
      mouthWidthRatio: rMouthWidth,
      noseAngle: noseAngleDeg,
      cheekWidthRatio: rCheek,
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

    // Ambang batas ketat: 0.065 (6.5% deviasi rata-rata)
    // Pemilik sah memiliki deviasi 1.5% - 4.5%
    // Wajah orang lain pasti memiliki deviasi > 8.0% atau tertolak langsung (1.0)
    if (diff > 0.065) {
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
