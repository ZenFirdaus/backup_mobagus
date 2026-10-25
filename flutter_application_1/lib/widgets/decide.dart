import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/restaurant.dart';
import '../pages/detail_page.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import 'restaurant_image.dart';

/// Membuka bottom sheet "Shake to Decide" dengan dadu 3D interaktif real-time gyro.
Future<void> showDecideSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DecideSheet(),
  );
}

class _DecideSheet extends StatefulWidget {
  const _DecideSheet();

  @override
  State<_DecideSheet> createState() => _DecideSheetState();
}

class _DecideSheetState extends State<_DecideSheet>
    with SingleTickerProviderStateMixin {
  // Data
  List<Restaurant> _options = [];
  Restaurant? _result;
  final _rng = Random();

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  // Real-time Gyro / Accelerometer motion state
  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;
  double _currentTiltX = 0.0;
  double _currentTiltY = 0.0;
  double _currentTiltZ = 0.0;
  double _gyroImpulseX = 0.0;
  double _gyroImpulseY = 0.0;
  double _gyroImpulseZ = 0.0;

  // Touch drag offset
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;

  // 3D Dice Angles
  double _rotX = 0.35;
  double _rotY = -0.45;
  double _rotZ = 0.0;

  // Physics & Rolling state
  bool _rolling = false;
  bool _settling = false;
  double _velX = 0.0;
  double _velY = 0.0;
  double _velZ = 0.0;
  int _targetFace = 1;
  double _targetRotX = 0.0;
  double _targetRotY = 0.0;
  double _targetRotZ = 0.0;

  // Ticker for 60fps physics simulation
  late final AnimationController _tickerController;

  static const double _diceSize = 88.0;
  static const double _halfSize = _diceSize / 2.0;

  late final List<_FaceDef> _faces;

  @override
  void initState() {
    super.initState();
    _initFaces();
    _loadRestaurants();
    _initSensors();

    _tickerController = AnimationController.unbounded(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_physicsTick);
    _tickerController.repeat(
      min: 0,
      max: 1,
      period: const Duration(milliseconds: 16),
    );
  }

  void _initFaces() {
    _faces = [
      // 1: Depan (Front)
      _FaceDef(
        number: 1,
        center: const _Vec3(0, 0, _halfSize),
        normal: const _Vec3(0, 0, 1),
        localTransform: Matrix4.translationValues(0.0, 0.0, _halfSize),
      ),
      // 6: Belakang (Back)
      _FaceDef(
        number: 6,
        center: const _Vec3(0, 0, -_halfSize),
        normal: const _Vec3(0, 0, -1),
        localTransform: Matrix4.translationValues(0.0, 0.0, -_halfSize)
          ..rotateY(pi),
      ),
      // 2: Atas (Top)
      _FaceDef(
        number: 2,
        center: const _Vec3(0, -_halfSize, 0),
        normal: const _Vec3(0, -1, 0),
        localTransform: Matrix4.translationValues(0.0, -_halfSize, 0.0)
          ..rotateX(-pi / 2),
      ),
      // 5: Bawah (Bottom)
      _FaceDef(
        number: 5,
        center: const _Vec3(0, _halfSize, 0),
        normal: const _Vec3(0, 1, 0),
        localTransform: Matrix4.translationValues(0.0, _halfSize, 0.0)
          ..rotateX(pi / 2),
      ),
      // 3: Kiri (Left)
      _FaceDef(
        number: 3,
        center: const _Vec3(-_halfSize, 0, 0),
        normal: const _Vec3(-1, 0, 0),
        localTransform: Matrix4.translationValues(-_halfSize, 0.0, 0.0)
          ..rotateY(-pi / 2),
      ),
      // 4: Kanan (Right)
      _FaceDef(
        number: 4,
        center: const _Vec3(_halfSize, 0, 0),
        normal: const _Vec3(1, 0, 0),
        localTransform: Matrix4.translationValues(_halfSize, 0.0, 0.0)
          ..rotateY(pi / 2),
      ),
    ];
  }

  void _initSensors() {
    try {
      _accelSub = accelerometerEventStream().listen((e) {
        if (!mounted) return;

        // Shake detection (resultant acceleration g)
        final totalG = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (totalG > 16.5 && !_rolling) {
          final now = DateTime.now();
          if (now.difference(_lastShake).inMilliseconds > 1500) {
            _lastShake = now;
            _roll();
            return;
          }
        }

        // Real-time device tilt tracking:
        // Kemiringan lateral (roll) dan vertikal (pitch)
        final tiltY = (-e.x / 9.81).clamp(-0.8, 0.8);
        final tiltX = ((e.y - 6.0) / 9.81).clamp(-0.8, 0.8);
        _targetTiltX = tiltX * 0.7;
        _targetTiltY = tiltY * 0.7;
      }, onError: (_) {});
    } catch (_) {}

    try {
      _gyroSub = gyroscopeEventStream().listen((e) {
        if (!mounted) return;

        // Dynamic angular impulse dari pergerakan cepat
        _gyroImpulseX += e.x * 0.025;
        _gyroImpulseY += e.y * 0.025;
        _gyroImpulseZ += e.z * 0.015;

        // Goyangan cepat via gyroscope
        final gyroMag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (gyroMag > 5.5 && !_rolling) {
          final now = DateTime.now();
          if (now.difference(_lastShake).inMilliseconds > 1500) {
            _lastShake = now;
            _roll();
          }
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _loadRestaurants() async {
    try {
      final list = await SupabaseService.instance.getRestaurants();
      if (mounted) setState(() => _options = list);
    } catch (_) {}
  }

  void _physicsTick() {
    if (!mounted) return;

    if (_rolling) {
      // Dynamic tumbling with high speed
      _rotX += _velX;
      _rotY += _velY;
      _rotZ += _velZ;

      // Damping / friction
      _velX *= 0.935;
      _velY *= 0.935;
      _velZ *= 0.935;

      final currentSpeed = sqrt(_velX * _velX + _velY * _velY + _velZ * _velZ);
      if (currentSpeed < 0.05) {
        _rolling = false;
        _settling = true;
        _applyTargetFaceAngles();
        HapticFeedback.mediumImpact();
      }
      setState(() {});
    } else if (_settling) {
      // Interpolasi halus ke orientasi muka dadu yang terpilih
      _rotX = _lerp(_rotX, _targetRotX, 0.16);
      _rotY = _lerp(_rotY, _targetRotY, 0.16);
      _rotZ = _lerp(_rotZ, _targetRotZ, 0.16);

      if ((_rotX - _targetRotX).abs() < 0.02 &&
          (_rotY - _targetRotY).abs() < 0.02 &&
          (_rotZ - _targetRotZ).abs() < 0.02) {
        _settling = false;
        _rotX = _targetRotX;
        _rotY = _targetRotY;
        _rotZ = _targetRotZ;
      }
      setState(() {});
    } else {
      // Mengikuti gyro dan kemiringan HP secara real-time
      _currentTiltX = _lerp(_currentTiltX, _targetTiltX + _gyroImpulseX, 0.12);
      _currentTiltY = _lerp(_currentTiltY, _targetTiltY + _gyroImpulseY, 0.12);
      _currentTiltZ = _lerp(_currentTiltZ, _gyroImpulseZ, 0.12);

      // Spring drag offset kembali ke tengah bila dilepas
      _dragOffsetX = _lerp(_dragOffsetX, 0.0, 0.08);
      _dragOffsetY = _lerp(_dragOffsetY, 0.0, 0.08);

      // Redam impuls gyro
      _gyroImpulseX *= 0.85;
      _gyroImpulseY *= 0.85;
      _gyroImpulseZ *= 0.85;

      setState(() {});
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _snapToClosestAngle(double current, double target) {
    double diff = (target - current) % (2 * pi);
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    return current + diff;
  }

  void _applyTargetFaceAngles() {
    double goalX = 0;
    double goalY = 0;
    double goalZ = 0;

    switch (_targetFace) {
      case 1: // Depan (Front)
        goalX = 0.25;
        goalY = -0.3;
        goalZ = 0.0;
        break;
      case 2: // Atas (Top)
        goalX = pi / 2 + 0.15;
        goalY = -0.25;
        goalZ = 0.0;
        break;
      case 3: // Kiri (Left)
        goalX = 0.2;
        goalY = pi / 2 - 0.2;
        goalZ = 0.0;
        break;
      case 4: // Kanan (Right)
        goalX = 0.2;
        goalY = -pi / 2 - 0.2;
        goalZ = 0.0;
        break;
      case 5: // Bawah (Bottom)
        goalX = -pi / 2 + 0.15;
        goalY = -0.25;
        goalZ = 0.0;
        break;
      case 6: // Belakang (Back)
        goalX = 0.25;
        goalY = pi - 0.3;
        goalZ = 0.0;
        break;
    }

    _targetRotX = _snapToClosestAngle(_rotX, goalX);
    _targetRotY = _snapToClosestAngle(_rotY, goalY);
    _targetRotZ = _snapToClosestAngle(_rotZ, goalZ);
  }

  void _roll() {
    if (_options.isEmpty || _rolling) return;

    HapticFeedback.lightImpact();

    // Pilih sisi dadu acak (1 s/d 6)
    _targetFace = _rng.nextInt(6) + 1;

    // Pilih restoran acak
    final chosen = _options[_rng.nextInt(_options.length)];

    setState(() {
      _rolling = true;
      _settling = false;
      _result = chosen;

      // Berikan kecepatan angular tinggi untuk putaran 3D acak
      _velX = (_rng.nextDouble() * 0.45 + 0.45) * (_rng.nextBool() ? 1 : -1);
      _velY = (_rng.nextDouble() * 0.45 + 0.45) * (_rng.nextBool() ? 1 : -1);
      _velZ = (_rng.nextDouble() * 0.25 + 0.2) * (_rng.nextBool() ? 1 : -1);
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sudut rotasi total = orientasi internal + tilt fisik HP dari gyro/akselerometer + drag sentuh
    final totalRotX = _rotX + _currentTiltX + _dragOffsetX;
    final totalRotY = _rotY + _currentTiltY + _dragOffsetY;
    final totalRotZ = _rotZ + _currentTiltZ;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle & Nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text('Shake to Decide', style: AppText.display(22)),
              const SizedBox(height: 4),
              const Text(
                'Goyang HP atau ketuk dadu untuk memilih kuliner.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // ─── 3D DICE CONTAINER DENGAN GYRO FISIK ───
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _dragOffsetY += details.delta.dx * 0.018;
                    _dragOffsetX -= details.delta.dy * 0.018;
                  });
                },
                onPanEnd: (details) {
                  if (details.velocity.pixelsPerSecond.distance > 400) {
                    _roll();
                  }
                },
                onTap: _roll,
                child: Container(
                  width: 170,
                  height: 150,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bayangan dinamis di bawah dadu (mengikuti tilt fisik)
                      Transform.translate(
                        offset: Offset(
                          -_currentTiltY * 20,
                          48 - _currentTiltX * 12,
                        ),
                        child: Container(
                          width: 86,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(86, 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: _rolling ? 0.06 : 0.16,
                                ),
                                blurRadius: _rolling ? 18 : 12,
                                spreadRadius: _rolling ? 3 : 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dadu 3D
                      _build3DCube(totalRotX, totalRotY, totalRotZ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── KARTU REKOMENDASI SIMPLE DI BAWAH DADU ───
              _buildRecommendationSection(),

              const SizedBox(height: 20),

              // Tombol Utama Acak
              GestureDetector(
                onTap: _roll,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.casino_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result == null ? 'Kocok Dadu' : 'Kocok Ulang',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Render Kubus 3D dengan kalkulasi Z-Sort dan Lighting Shading
  Widget _build3DCube(double rx, double ry, double rz) {
    // Matriks rotasi kubus saat ini
    final rotMatrix = Matrix4.identity()
      ..rotateX(rx)
      ..rotateY(ry)
      ..rotateZ(rz);

    // Hitung posisi dan normal yang telah ditransformasikan
    final List<_VisibleFace> visibleFaces = [];
    final lightSource = const _Vec3(-0.35, -0.6, 0.75).normalized();

    for (final face in _faces) {
      final normalTransformed = face.normal.transformBy(rotMatrix);
      final centerTransformed = face.center.transformBy(rotMatrix);

      // Backface culling: hanya muka yang menghadap ke arah pengguna
      if (normalTransformed.z > -0.05) {
        // Kalkulasi pencahayaan diffuse
        final diffuse = normalTransformed.dot(lightSource).clamp(0.0, 1.0);

        // Matriks proyeksi 3D muka ini
        final faceMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018) // Perspective factor
          ..rotateX(rx)
          ..rotateY(ry)
          ..rotateZ(rz)
          ..multiply(face.localTransform);

        visibleFaces.add(
          _VisibleFace(
            number: face.number,
            depthZ: centerTransformed.z,
            diffuse: diffuse,
            transform: faceMatrix,
          ),
        );
      }
    }

    // Depth Sorting (Painter's algorithm): gambar dari paling jauh ke paling dekat
    visibleFaces.sort((a, b) => a.depthZ.compareTo(b.depthZ));

    return SizedBox(
      width: _diceSize,
      height: _diceSize,
      child: Stack(
        alignment: Alignment.center,
        children: visibleFaces.map((f) {
          return Transform(
            alignment: Alignment.center,
            transform: f.transform,
            child: _buildDiceFace(f.number, f.diffuse),
          );
        }).toList(),
      ),
    );
  }

  /// Desain satu sisi dadu dengan pips nyata dan shading pencahayaan
  Widget _buildDiceFace(int number, double diffuse) {
    // Shading overlay berdasarkan intensitas cahaya
    final shadeOpacity = ((1.0 - (0.5 + 0.5 * diffuse)) * 0.35).clamp(
      0.0,
      0.35,
    );

    return Container(
      width: _diceSize,
      height: _diceSize,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1F000000), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 4)],
      ),
      child: Stack(
        children: [
          // Pips dadu
          _buildPips(number),

          // Lapisan shading realistis
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: shadeOpacity),
              ),
            ),
          ),

          // Highlight bevel halus di sudut atas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.3 * diffuse),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pips dadu 1 s/d 6
  Widget _buildPips(int number) {
    final List<Widget> dots = [];

    Widget pip({bool isRed = false, double size = 13.0}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isRed ? AppColors.paprika : AppColors.charcoal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 1.2,
              offset: const Offset(0, 0.8),
            ),
          ],
        ),
      );
    }

    void addDot(double x, double y, {bool isRed = false, double size = 13.0}) {
      dots.add(
        Align(
          alignment: Alignment(x, y),
          child: pip(isRed: isRed, size: size),
        ),
      );
    }

    switch (number) {
      case 1:
        // Pip merah khas dadu Mataraman / Asia di tengah
        addDot(0, 0, isRed: true, size: 20.0);
        break;
      case 2:
        addDot(-0.5, -0.5);
        addDot(0.5, 0.5);
        break;
      case 3:
        addDot(-0.55, -0.55);
        addDot(0, 0);
        addDot(0.55, 0.55);
        break;
      case 4:
        addDot(-0.52, -0.52);
        addDot(0.52, -0.52);
        addDot(-0.52, 0.52);
        addDot(0.52, 0.52);
        break;
      case 5:
        addDot(-0.54, -0.54);
        addDot(0.54, -0.54);
        addDot(0, 0);
        addDot(-0.54, 0.54);
        addDot(0.54, 0.54);
        break;
      case 6:
        addDot(-0.54, -0.55);
        addDot(-0.54, 0);
        addDot(-0.54, 0.55);
        addDot(0.54, -0.55);
        addDot(0.54, 0);
        addDot(0.54, 0.55);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(children: dots),
    );
  }

  /// Bagian informasi rekomendasi makanan di bawah dadu
  Widget _buildRecommendationSection() {
    if (_rolling) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Mengacak kuliner lezat...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum Ada Pilihan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Goyangkan HP untuk mendapatkan tempat makan acak.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tampilan hasil rekomendasi: Simple, Modern, Elegan
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailPage(restaurant: _result!),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge baris atas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _result!.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.yellow,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _result!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Data Restoran
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: RestaurantImage(
                          imageUrl: _result!.imageUrl,
                          category: _result!.category,
                          dishType: _result!.dishType,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _result!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display(
                              15,
                              weight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_result!.address.split(',').first} • ${_result!.province}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _result!.priceRange,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Prompt aksi sederhana
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.orange, 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Buka Detail Menu & Lokasi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Representasi Vektor 3D ringan & cepat
class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);

  _Vec3 transformBy(Matrix4 m) {
    final s = m.storage;
    return _Vec3(
      s[0] * x + s[4] * y + s[8] * z,
      s[1] * x + s[5] * y + s[9] * z,
      s[2] * x + s[6] * y + s[10] * z,
    );
  }

  double dot(_Vec3 o) => x * o.x + y * o.y + z * o.z;

  _Vec3 normalized() {
    final len = sqrt(x * x + y * y + z * z);
    if (len == 0) return this;
    return _Vec3(x / len, y / len, z / len);
  }
}

class _FaceDef {
  final int number;
  final _Vec3 center;
  final _Vec3 normal;
  final Matrix4 localTransform;

  _FaceDef({
    required this.number,
    required this.center,
    required this.normal,
    required this.localTransform,
  });
}

class _VisibleFace {
  final int number;
  final double depthZ;
  final double diffuse;
  final Matrix4 transform;

  _VisibleFace({
    required this.number,
    required this.depthZ,
    required this.diffuse,
    required this.transform,
  });
}
