import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../props/app_colors.dart';
import '../services/face_biometric_service.dart';

/// Modal Sheet Autentikasi / Pendaftaran Biometrik Face ID
/// Real-time live frame stream (TANPA suara kamera shutter berulang),
/// deteksi kilat (fast mode), suara berbunyi HANYA saat wajah berhasil terdeteksi.
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
  scanning,
  success,
  error,
}

class _FaceIdScannerSheetState extends State<FaceIdScannerSheet>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  bool _isCameraReady = false;
  bool _isStreaming = false;
  bool _isProcessing = false;
  int _lastProcessTime = 0;
  int _mismatchCount = 0;
  Timer? _timeoutTimer;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  _ScanStatus _status = _ScanStatus.initializing;
  String _statusMessage = 'Menyiapkan sensor kamera...';
  String? _errorMessage;

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initFrontCamera();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _stopCameraStream();
    _pulseController.dispose();
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
          _status = _ScanStatus.error;
          _statusMessage = 'Kamera tidak ditemukan';
          _errorMessage =
              'Perangkat tidak memiliki modul kamera yang dapat diakses.';
        });
        return;
      }

      // Cari kamera depan untuk Face ID
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });

      _startCameraStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ScanStatus.error;
        _statusMessage = 'Izin kamera diperlukan';
        _errorMessage =
            'Harap izinkan akses kamera di Pengaturan untuk menggunakan fitur Face ID.';
      });
    }
  }

  /// Memulai Live Image Stream (Langsung di Memori, Tanpa Shutter Sound)
  Future<void> _startCameraStream() async {
    if (_isStreaming || _cameraController == null || !_isCameraReady) return;
    _isStreaming = true;
    _mismatchCount = 0;

    setState(() {
      _status = _ScanStatus.scanning;
      _statusMessage = 'Posisikan wajah Anda di dalam lingkaran...';
      _errorMessage = null;
    });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _status == _ScanStatus.scanning) {
        _stopCameraStream();
        setState(() {
          _status = _ScanStatus.error;
          _statusMessage = 'Wajah Belum Terdeteksi';
          _errorMessage =
              'Pastikan wajah Anda berada di tengah bingkai kamera dalam pencahayaan yang cukup.';
        });
      }
    });

    try {
      await _cameraController!.startImageStream((CameraImage image) {
        _processFrame(image);
      });
    } catch (_) {}
  }

  /// Menghentikan Image Stream
  Future<void> _stopCameraStream() async {
    _isStreaming = false;
    _timeoutTimer?.cancel();
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (_) {}
  }

  /// Proses Frame Kamera Real-time
  void _processFrame(CameraImage image) async {
    if (_isProcessing || !_isStreaming || !mounted) return;
    _isProcessing = true;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Evaluasi setiap 100ms untuk respon kilat tanpa membebani thread
      if (now - _lastProcessTime < 100) {
        _isProcessing = false;
        return;
      }
      _lastProcessTime = now;

      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final luminance = _calculateLuminanceFromImage(image);
      final result = await FaceBiometricService.instance.analyzeInputImage(
        inputImage: inputImage,
        isEnrollment: widget.isEnrollment,
        luminance: luminance,
      );

      if (!mounted || !_isStreaming) {
        _isProcessing = false;
        return;
      }

      // 1. Wajah belum terdeteksi di frame ini
      if (!result.isFaceDetected) {
        _mismatchCount = 0;
        if (_statusMessage != 'Arahkan wajah ke kamera') {
          setState(() => _statusMessage = 'Arahkan wajah ke kamera');
        }
        _isProcessing = false;
        return;
      }

      // 2. Terlalu banyak wajah
      if (!result.isSingleFace) {
        if (_statusMessage != 'Posisikan hanya satu wajah di sensor') {
          setState(() => _statusMessage = 'Posisikan hanya satu wajah di sensor');
        }
        _isProcessing = false;
        return;
      }

      // 3. Wajah Valid Ditemukan!
      if (widget.isEnrollment) {
        // PENDAFTARAN SUKSES
        await _stopCameraStream();

        if (result.detectedMetrics != null) {
          await FaceBiometricService.instance.saveEnrolledFace(
            metrics: result.detectedMetrics!,
            userName: widget.userName,
            userEmail: widget.userEmail,
            password: widget.savedPassword,
          );
        }

        // Suara klik & haptic HANYA saat wajah berhasil dideteksi!
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();

        setState(() {
          _status = _ScanStatus.success;
          _statusMessage = 'Face ID Berhasil Didaftarkan';
        });

        await Future.delayed(const Duration(milliseconds: 550));
        if (mounted) widget.onSuccess();
        return;
      } else {
        // AUTENTIKASI / LOGIN
        if (result.isFaceMatched) {
          await _stopCameraStream();

          // Suara klik & haptic HANYA saat wajah berhasil dideteksi!
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.mediumImpact();

          setState(() {
            _status = _ScanStatus.success;
            _statusMessage = 'Wajah Terverifikasi';
          });

          await Future.delayed(const Duration(milliseconds: 550));
          if (mounted) widget.onSuccess();
          return;
        } else {
          _mismatchCount++;
          // Toleransi hingga 8 frame (~800ms) sebelum memvonis tidak cocok
          if (_mismatchCount >= 8) {
            await _stopCameraStream();
            HapticFeedback.heavyImpact();
            setState(() {
              _status = _ScanStatus.error;
              _statusMessage = 'Wajah Tidak Cocok';
              _errorMessage =
                  'Wajah yang terdeteksi tidak cocok dengan profil biometrik yang didaftarkan pada akun ini.';
            });
            return;
          } else {
            if (_statusMessage != 'Memverifikasi identitas...') {
              setState(() => _statusMessage = 'Memverifikasi identitas...');
            }
          }
        }
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  /// Mengonversi CameraImage menjadi ML Kit InputImage tanpa I/O file
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null || _frontCamera == null) return null;

    final camera = _frontCamera!;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    rotation ??= InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Ambil byte buffer dari plane kamera
    Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane p in image.planes) {
        allBytes.putUint8List(p.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format ??
            (Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888),
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Estimasi Luminance Langsung dari Plane Y (Ringan & Cepat, 0ms)
  double _calculateLuminanceFromImage(CameraImage image) {
    if (image.planes.isEmpty) return 100.0;
    final bytes = image.planes[0].bytes;
    if (bytes.isEmpty) return 100.0;

    int sum = 0;
    final step = (bytes.length / 80).floor().clamp(1, 1000);
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    return count > 0 ? (sum / count).toDouble() : 100.0;
  }

  void _retryScan() {
    _startCameraStream();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar minimalis
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Judul & Tombol Tutup
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEnrollment
                            ? 'Daftarkan Face ID'
                            : 'Masuk dengan Face ID',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isEnrollment
                            ? 'Arahkan wajah Anda ke dalam lingkaran kamera'
                            : 'Tatap kamera depan untuk memverifikasi akun Anda',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line, width: 0.8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Viewport Kamera Pemindai (Minimalis, Bersih, Profesional)
            _buildCameraViewport(),

            const SizedBox(height: 18),

            // Status Pill Dinamis
            _buildStatusPill(),

            // Informasi Akun Pengguna (Clean & Reassuring)
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: AppColors.slateBlue,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${widget.userName} • ${widget.userEmail}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Detail Pesan Error & Tombol Tindakan
            if (_status == _ScanStatus.error) ...[
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _retryScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Gunakan Kata Sandi',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Batal / Gunakan Kata Sandi',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Viewport Kamera Bulat Bersih & Ring Sensor
  Widget _buildCameraViewport() {
    final isSuccess = _status == _ScanStatus.success;
    final isError = _status == _ScanStatus.error;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;

        Color borderColor;
        double borderWidth = 2.5;

        if (isSuccess) {
          borderColor = AppColors.green;
          borderWidth = 3.0;
        } else if (isError) {
          borderColor = AppColors.red;
          borderWidth = 2.5;
        } else {
          borderColor = Color.lerp(
            AppColors.orange.withValues(alpha: 0.45),
            AppColors.orange,
            t,
          )!;
        }

        return Container(
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              if (isSuccess)
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              else if (!isError)
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.12 * t),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Feed Kamera Depan
                  if (_isCameraReady && _cameraController != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width:
                            _cameraController!.value.previewSize?.height ?? 168,
                        height:
                            _cameraController!.value.previewSize?.width ?? 168,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.background,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ),

                  // Overlay Sukses Terverifikasi
                  if (isSuccess)
                    Container(
                      color: AppColors.green.withValues(alpha: 0.4),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Overlay Error
                  if (isError)
                    Container(
                      color: AppColors.red.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Pill Status Feedback
  Widget _buildStatusPill() {
    IconData icon;
    Color iconColor;
    Color textColor;
    bool showSpinner = false;

    switch (_status) {
      case _ScanStatus.initializing:
      case _ScanStatus.scanning:
        showSpinner = true;
        icon = Icons.camera_front_rounded;
        iconColor = AppColors.orange;
        textColor = AppColors.charcoal;
        break;
      case _ScanStatus.success:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.green;
        textColor = AppColors.green;
        break;
      case _ScanStatus.error:
        icon = Icons.info_outline_rounded;
        iconColor = AppColors.red;
        textColor = AppColors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _status == _ScanStatus.error
            ? AppColors.tint(AppColors.red, 0.08)
            : (_status == _ScanStatus.success
                ? AppColors.tint(AppColors.green, 0.1)
                : AppColors.background),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _status == _ScanStatus.error
              ? AppColors.tint(AppColors.red, 0.3)
              : (_status == _ScanStatus.success
                  ? AppColors.tint(AppColors.green, 0.3)
                  : AppColors.line),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              _statusMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
