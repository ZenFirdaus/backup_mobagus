import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/face_biometric_service.dart';

/// Modal Sheet Autentikasi / Pendaftaran Biometrik Face ID Profesional
/// Mengakses kamera depan nyata perangkat, mendeteksi wajah dengan Google ML Kit,
/// memeriksa kecukupan cahaya (lux), dan mencocokkan biometrik wajah terdaftar.
class FaceIdScannerSheet extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? savedPassword;
  final bool isEnrollment;
  final VoidCallback onSuccess;

  const FaceIdScannerSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    this.savedPassword,
    this.isEnrollment = false,
    required this.onSuccess,
  });

  @override
  State<FaceIdScannerSheet> createState() => _FaceIdScannerSheetState();
}

enum _ScanStatus {
  initializing,
  aligning,
  analyzing,
  success,
  error,
}

class _FaceIdScannerSheetState extends State<FaceIdScannerSheet>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _cameraInitError;

  late final AnimationController _scanPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  _ScanStatus _status = _ScanStatus.initializing;
  String? _errorMessage;
  String? _errorCategory;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initFrontCamera();
  }

  @override
  void dispose() {
    _scanPulse.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  /// Inisialisasi Kamera Depan
  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraInitError = 'Kamera tidak terdeteksi pada perangkat';
          _status = _ScanStatus.error;
          _errorMessage = 'Tidak ditemukan modul kamera pada perangkat.';
        });
        return;
      }

      // Cari kamera depan untuk Face ID
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _status = _ScanStatus.aligning;
      });

      _startScanProcess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraInitError =
            'Izin kamera belum aktif. Buka Pengaturan perangkat untuk mengizinkan kamera.';
        _status = _ScanStatus.error;
        _errorMessage = _cameraInitError;
      });
    }
  }

  /// Memulai Proses Pemindaian Nyata
  Future<void> _startScanProcess() async {
    if (_isAnalyzing || !_isCameraReady || _cameraController == null) return;
    _isAnalyzing = true;

    setState(() {
      _status = _ScanStatus.aligning;
      _errorMessage = null;
      _errorCategory = null;
    });

    _scanPulse.repeat(reverse: true);
    HapticFeedback.lightImpact();

    // 1. Berikan jeda 800ms agar kamera stabil dan pengguna memposisikan wajah
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    setState(() => _status = _ScanStatus.analyzing);
    HapticFeedback.selectionClick();

    // 2. Ambil snapshot nyata dari kamera depan
    XFile? capturedFile;
    try {
      capturedFile = await _cameraController!.takePicture();
    } catch (e) {
      if (!mounted) return;
      _scanPulse.stop();
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Gagal menangkap frame kamera: $e';
        _isAnalyzing = false;
      });
      return;
    }

    // 3. Analisis Wajah Nyata via FaceBiometricService (ML Kit + Luminance + Geometric Match)
    final result = await FaceBiometricService.instance.analyzeFaceImage(
      imagePath: capturedFile.path,
      isEnrollment: widget.isEnrollment,
    );

    if (!mounted) return;
    _isAnalyzing = false;

    // JIKA GAGAL (Kamera tidak mengarah ke wajah / cahaya kurang / bukan wajah terdaftar)
    if (!result.isSuccess) {
      _scanPulse.stop();
      HapticFeedback.heavyImpact();
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = result.errorMessage ?? 'Autentikasi wajah gagal.';
        _errorCategory = result.errorCategory;
      });
      return;
    }

    // JIKA BERHASIL:
    _scanPulse.stop();
    HapticFeedback.mediumImpact();
    setState(() => _status = _ScanStatus.success);

    // Jika pendaftaran, simpan metrik ke SharedPreferences
    if (widget.isEnrollment && result.detectedMetrics != null) {
      await FaceBiometricService.instance.saveEnrolledFace(
        metrics: result.detectedMetrics!,
        userName: widget.userName,
        userEmail: widget.userEmail,
        password: widget.savedPassword,
      );
    }

    // Callback sukses setelah selebrasi
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    widget.onSuccess();
  }

  /// Tombol Ulangi Pemindaian
  void _retryScan() {
    _startScanProcess();
  }

  String get _statusLabel {
    switch (_status) {
      case _ScanStatus.initializing:
        return 'Menginisialisasi sensor kamera depan...';
      case _ScanStatus.aligning:
        return 'Posisikan wajah Anda tepat di dalam lingkaran...';
      case _ScanStatus.analyzing:
        return widget.isEnrollment
            ? 'Menganalisis pencahayaan & kontur wajah...'
            : 'Menganalisis & memverifikasi identitas wajah...';
      case _ScanStatus.success:
        return widget.isEnrollment
            ? 'Face ID Berhasil Didaftarkan! ✨'
            : 'Face ID Terverifikasi! Selamat Datang ✨';
      case _ScanStatus.error:
        if (_errorCategory == 'LIGHTING') {
          return 'Pencahayaan Tidak Memadai ⚠️';
        } else if (_errorCategory == 'NO_FACE') {
          return 'Wajah Tidak Terdeteksi ⚠️';
        } else if (_errorCategory == 'MISMATCH') {
          return 'Wajah Tidak Cocok! Akses Ditolak 🚫';
        } else if (_errorCategory == 'MULTIPLE_FACES') {
          return 'Terlalu Banyak Wajah ⚠️';
        }
        return 'Verifikasi Wajah Gagal ⚠️';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case _ScanStatus.initializing:
        return Icons.sensors_rounded;
      case _ScanStatus.aligning:
        return Icons.face_retouching_natural_rounded;
      case _ScanStatus.analyzing:
        return Icons.security_rounded;
      case _ScanStatus.success:
        return Icons.verified_user_rounded;
      case _ScanStatus.error:
        if (_errorCategory == 'LIGHTING') return Icons.nightlight_round;
        if (_errorCategory == 'MISMATCH') return Icons.no_accounts_rounded;
        return Icons.warning_amber_rounded;
    }
  }

  Color get _statusColor {
    switch (_status) {
      case _ScanStatus.success:
        return AppColors.green;
      case _ScanStatus.analyzing:
        return AppColors.saffron;
      case _ScanStatus.aligning:
        return AppColors.orange;
      case _ScanStatus.error:
        return AppColors.red;
      case _ScanStatus.initializing:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Badge Face ID & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.isEnrollment
                            ? 'PENDAFTARAN APPLE FACE ID'
                            : 'AUTENTIKASI APPLE FACE ID',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              widget.isEnrollment
                  ? 'Daftarkan Wajah Anda'
                  : 'Masuk Cepat dengan Face ID',
              textAlign: TextAlign.center,
              style: AppText.display(20),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEnrollment
                  ? 'Posisikan wajah Anda pada lingkaran sensor dalam pencahayaan yang cukup untuk mendaftarkan Face ID.'
                  : 'Tatap kamera depan untuk memvalidasi identitas biometrik Anda secara aman.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Reticle Kamera Pemindai Wajah Real-Time
            _buildLiveCameraReticle(),

            const SizedBox(height: 16),

            // Status Chip Dinamis
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _status == _ScanStatus.error
                      ? AppColors.red.withValues(alpha: 0.4)
                      : AppColors.line,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _status == _ScanStatus.error
                            ? AppColors.red
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Kotak Pesan Kesalahan Detail jika Gagal
            if (_status == _ScanStatus.error && _errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errorCategory == 'LIGHTING'
                      ? AppColors.tint(AppColors.orange, 0.12)
                      : AppColors.tint(AppColors.red, 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorCategory == 'LIGHTING'
                        ? AppColors.tint(AppColors.orange, 0.35)
                        : AppColors.tint(AppColors.red, 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _errorCategory == 'LIGHTING'
                          ? Icons.nightlight_round
                          : Icons.error_outline_rounded,
                      size: 20,
                      color: _errorCategory == 'LIGHTING'
                          ? AppColors.orange
                          : AppColors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: _errorCategory == 'LIGHTING'
                              ? AppColors.charcoal
                              : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Tombol Ulangi Pemindaian
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _retryScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Ulangi Pemindaian',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Identitas Akun Pengguna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.orange, 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'F',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.userEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _status == _ScanStatus.error
                        ? Icons.gpp_bad_rounded
                        : Icons.face_unlock_rounded,
                    size: 20,
                    color: _status == _ScanStatus.error
                        ? AppColors.red
                        : AppColors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal / Gunakan Kata Sandi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reticle Pemindai Kamera Depan Real-Time
  Widget _buildLiveCameraReticle() {
    final isSuccess = _status == _ScanStatus.success;
    final isError = _status == _ScanStatus.error;

    return AnimatedBuilder(
      animation: _scanPulse,
      builder: (context, _) {
        final t = _scanPulse.value;

        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gelombang radar luar berdenyut
              if (!isSuccess && !isError)
                Container(
                  width: 204 + (16 * t),
                  height: 204 + (16 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.tint(AppColors.orange, 0.28 * (1.0 - t)),
                      width: 1.5,
                    ),
                  ),
                ),

              // Cincin tengah
              Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? AppColors.tint(AppColors.green, 0.15)
                      : (isError
                          ? AppColors.tint(AppColors.red, 0.12)
                          : AppColors.tint(AppColors.yellow, 0.2)),
                  border: Border.all(
                    color: isSuccess
                        ? AppColors.green
                        : (isError
                            ? AppColors.red
                            : AppColors.tint(AppColors.orange, 0.45)),
                    width: 1.5,
                  ),
                ),
              ),

              // Wadah Kamera / Sensor Utama (Diameter 150 px)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(
                    color: isSuccess
                        ? AppColors.green
                        : (isError ? AppColors.red : AppColors.orange),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSuccess
                          ? AppColors.tint(AppColors.green, 0.35 + 0.2 * t)
                          : (isError
                              ? AppColors.tint(AppColors.red, 0.35)
                              : AppColors.tint(AppColors.orange, 0.35 + 0.2 * t)),
                      blurRadius: isError ? 12 : 20 + 8 * t,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Feed Kamera Depan Nyata
                      if (_isCameraReady && _cameraController != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _cameraController!.value.previewSize?.height ??
                                    150,
                            height:
                                _cameraController!.value.previewSize?.width ??
                                    150,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      else
                        // Fallback jika kamera belum siap
                        Container(
                          color: AppColors.charcoal,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.orange,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),

                      // Filter warna HUD di atas kamera
                      Container(
                        color: isSuccess
                            ? AppColors.green.withValues(alpha: 0.3)
                            : (isError
                                ? AppColors.red.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.12)),
                      ),

                      // Sudut Reticle Face ID (Targeting Corners)
                      CustomPaint(
                        painter: _FaceReticlePainter(
                          color: isSuccess
                              ? AppColors.green
                              : (isError ? AppColors.red : AppColors.saffron),
                        ),
                      ),

                      // Laser Pemindai Bergerak Vertikal
                      if (!isSuccess && !isError)
                        Positioned(
                          top: 15 + (120 * t),
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.saffron,
                                  Colors.white,
                                  AppColors.orange,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withValues(alpha: 0.85),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Ikon Sukses Terverifikasi
                      if (isSuccess)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Ikon Error jika Wajah Gagal / Tidak Cocok
                      if (isError)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _errorCategory == 'LIGHTING'
                                  ? Icons.nightlight_round
                                  : Icons.close_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Painter untuk menggambar sudut-sudut framing Apple Face ID
class _FaceReticlePainter extends CustomPainter {
  final Color color;

  _FaceReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 16.0;
    const padding = 18.0;

    // Top-Left
    canvas.drawLine(
      const Offset(padding, padding + cornerLength),
      const Offset(padding, padding),
      paint,
    );
    canvas.drawLine(
      const Offset(padding, padding),
      const Offset(padding + cornerLength, padding),
      paint,
    );

    // Top-Right
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, padding),
      Offset(size.width - padding, padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + cornerLength),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(padding, size.height - padding - cornerLength),
      Offset(padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + cornerLength, size.height - padding),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(size.width - padding, size.height - padding - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
