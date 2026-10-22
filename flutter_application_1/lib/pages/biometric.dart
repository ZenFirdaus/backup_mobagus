import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/buttons.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/step_progress.dart';
import '../widgets/face_id_scanner_sheet.dart';
import 'home.dart';

enum _ScanState { idle, scanning, success }

/// Alur: VerifyEmailPage ─► BiometricPage (langkah 3) ─► HomePage
/// "Nanti Saja" dan PIN cadangan juga berakhir di HomePage.
class BiometricPage extends StatefulWidget {
  final String name;
  final String? email;
  final String? password;

  const BiometricPage({
    super.key,
    required this.name,
    this.email,
    this.password,
  });

  @override
  State<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  _ScanState _state = _ScanState.idle;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _goHome({required bool biometric}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: widget.name,
          fromRegister: true,
          biometricOn: biometric,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _activate() async {
    final effectiveEmail = widget.email ??
        '${widget.name.toLowerCase().replaceAll(' ', '.')}@foodie.id';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => FaceIdScannerSheet(
        userName: widget.name,
        userEmail: effectiveEmail,
        savedPassword: widget.password,
        isEnrollment: true,
        onSuccess: () async {
          Navigator.of(ctx).pop();
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('foodie_biometric_enabled', true);
            await prefs.setString('foodie_last_user_name', widget.name);
            await prefs.setString('foodie_last_user_email', effectiveEmail);
            if (widget.password != null && widget.password!.isNotEmpty) {
              await prefs.setString('foodie_saved_password', widget.password!);
            }
          } catch (_) {}
          if (!mounted) return;
          setState(() => _state = _ScanState.success);
          _goHome(biometric: true);
        },
      ),
    );
  }

  Future<void> _setPin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _PinDialog(),
    );
    if (ok == true && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('foodie_biometric_enabled', false);
      } catch (_) {}
      _goHome(biometric: false);
    }
  }

  String get _pillText {
    switch (_state) {
      case _ScanState.idle:
        return 'Posisikan wajah Anda pada lingkaran sensor';
      case _ScanState.scanning:
        return 'Memindai kontur wajah... harap tatap sensor';
      case _ScanState.success:
        return 'Autentikasi wajah berhasil didaftarkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _state != _ScanState.idle;

    return Scaffold(
      body: PageBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            children: [
              // --- Petunjuk alur ---
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Langkah 3 dari 3: Keamanan Apple Face ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: busy ? null : () => _goHome(biometric: false),
                    child: const Text(
                      'Nanti Saja',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const StepBar(current: 3),
              const SizedBox(height: 18),
              const InfoPill(
                icon: Icons.verified_user_rounded,
                text: 'AUTENTIKASI APPLE FACE ID',
              ),
              const SizedBox(height: 16),
              Text(
                'Masuk Cepat dengan\nApple Face ID',
                textAlign: TextAlign.center,
                style: AppText.display(
                  28,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aktifkan Apple Face ID untuk validasi check-in instan di warung legendaris, verifikasi voucher makan, dan akses akun tanpa kata sandi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              _scanner(),
              const SizedBox(height: 6),
              _statusPill(),
              const SizedBox(height: 8),
              const Text(
                'Sensor Apple Face ID Terdeteksi (Kamera Depan TrueDepth & Secure Enclave Aktif)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              const _BenefitCard(
                icon: Icons.bolt,
                title: 'Akses 1-Ketukan',
                text: 'Masuk aplikasi seketika tanpa perlu input password berulang saat mengeksplor rasa.',
              ),
              const SizedBox(height: 8),
              const _BenefitCard(
                icon: Icons.location_on_rounded,
                title: 'Validasi Check-in Cepat',
                text: 'Konfirmasi kehadiran GPS di warung mitra & klaim voucher santap dalam hitungan detik.',
              ),
              const SizedBox(height: 8),
              const _BenefitCard(
                icon: Icons.lock_rounded,
                title: 'Privasi Terisolasi',
                text: 'Kunci biometrik disimpan aman di hardware Secure Enclave perangkat Anda.',
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Pindai Wajah dengan Kamera Sekarang',
                icon: Icons.camera_front_rounded,
                onPressed: busy ? null : _activate,
              ),
              const SizedBox(height: 10),
              SoftButton(
                label: 'Gunakan PIN 6-Digit Sebagai Cadangan',
                icon: Icons.dialpad,
                onPressed: busy ? null : _setPin,
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Dapat diubah kapan saja melalui menu Pengaturan Profil & Keamanan.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _state == _ScanState.success
                  ? AppColors.green
                  : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _pillText,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _scanner() {
    final scanning = _state == _ScanState.scanning;
    final done = _state == _ScanState.success;

    return GestureDetector(
      onTap: _activate,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = scanning ? _pulse.value : 0.0;
          return SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 226 + 10 * t,
                  height: 226 + 10 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.tint(AppColors.orange, 0.25 + 0.25 * t),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tint(AppColors.yellow, 0.6),
                    border: Border.all(
                      color: AppColors.tint(AppColors.orange, 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.green : AppColors.greenDark,
                    border: Border.all(color: AppColors.orange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tint(
                          AppColors.orange,
                          0.35 + 0.25 * t,
                        ),
                        blurRadius: 24 + 16 * t,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        done ? Icons.check_circle_rounded : Icons.face_retouching_natural_rounded,
                        size: 54,
                        color: done ? Colors.white : AppColors.orange,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        done ? 'TERVERIFIKASI' : (scanning ? 'MEMINDAI WAJAH' : 'PINDAI WAJAH'),
                        style: const TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(AppColors.orange, 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.green, 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.greenDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
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
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Buat PIN 6 Digit', style: AppText.display(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIN dipakai sebagai cadangan jika sensor sidik jari tidak tersedia.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              errorText: _error,
              filled: true,
              fillColor: AppColors.tint(AppColors.yellow, 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.orange,
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pin.text.length != 6) {
              setState(() => _error = 'PIN harus 6 digit');
              return;
            }
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.textDark,
          ),
          child: const Text(
            'Simpan PIN',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
