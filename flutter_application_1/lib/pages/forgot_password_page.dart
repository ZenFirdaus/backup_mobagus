import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/face_biometric_service.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/face_id_scanner_sheet.dart';
import '../widgets/foodie_logo.dart';
import '../widgets/text_field.dart';
import 'login.dart';

/// Halaman Pemulihan / Lupa Kata Sandi
/// Alur 4 langkah terstruktur:
/// 1. Masukkan Email -> Kirim Kode ke Email
/// 2. Masukkan Kode Verifikasi OTP -> Verifikasi Kode
/// 3. Masukkan & Konfirmasi Kata Sandi Baru -> Simpan Kata Sandi
/// 4. Konfirmasi Sukses -> Kembali ke Login
class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _codeLength = 8;
  static const int _resendSeconds = 60;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final _focusNodeOtp = FocusNode();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFaceIdVerified = false;
  bool _hasFaceIdEnrolled = false;
  String? _errorMessage;

  Timer? _resendTimer;
  int _secondsLeft = 0;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
    _checkFaceIdStatus();
    _listenToAuthRecovery();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _authSubscription?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _focusNodeOtp.dispose();
    super.dispose();
  }

  Future<void> _checkFaceIdStatus() async {
    try {
      final inputEmail = _emailController.text.trim();
      final enrolled = inputEmail.isNotEmpty
          ? await FaceBiometricService.instance.isFaceEnrolled(email: inputEmail)
          : await FaceBiometricService.instance.isFaceEnrolled();
      if (mounted) setState(() => _hasFaceIdEnrolled = enrolled);
    } catch (_) {}
  }

  void _listenToAuthRecovery() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() {
          _currentStep = 2;
          _errorMessage = null;
        });
      }
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSnackBar(String text, {Color bg = AppColors.greenDark}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: bg, behavior: SnackBarBehavior.floating),
    );
  }

  String _parseAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('error sending recovery email') || lower.contains('unexpected_failure')) {
      return 'Gagal mengirim email dari server Supabase. Pastikan pengaturan SMTP / email pada Dashboard Supabase sudah aktif dan kuota belum habis.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Terlalu banyak permintaan pengiriman email. Harap tunggu beberapa menit sebelum mencoba lagi.';
    }
    if (lower.contains('token has expired') || lower.contains('expired')) {
      return 'Kode verifikasi telah kedaluwarsa. Silakan kirim ulang kode baru.';
    }
    if (lower.contains('invalid') || lower.contains('not match') || lower.contains('token')) {
      return 'Kode verifikasi yang Anda masukkan tidak sesuai. Periksa kembali email Anda.';
    }
    if (lower.contains('user not found')) {
      return 'Email tidak terdaftar di sistem. Pastikan alamat email benar.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Koneksi jaringan terputus. Pastikan perangkat Anda terhubung ke internet.';
    }
    return msg;
  }

  Future<void> _verifyWithFaceId() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final inputEmail = _emailController.text.trim();
    String targetEmail;
    String targetName;

    if (inputEmail.isNotEmpty) {
      final isUserEnrolled = await FaceBiometricService.instance.isFaceEnrolled(email: inputEmail);
      if (!isUserEnrolled) {
        _showSnackBar('Face ID belum didaftarkan untuk akun $inputEmail.', bg: AppColors.charcoal);
        return;
      }
      targetEmail = inputEmail;
      final prefs = await SharedPreferences.getInstance();
      final key = inputEmail.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      targetName = prefs.getString('foodie_face_name_$key') ??
          prefs.getString('foodie_last_user_name') ??
          inputEmail.split('@').first;
    } else {
      final account = await FaceBiometricService.instance.getActiveBiometricAccount();
      if (account == null) {
        _showSnackBar('Belum ada akun terdaftar untuk Face ID di perangkat ini.', bg: AppColors.charcoal);
        return;
      }
      targetEmail = account['email']!;
      targetName = account['name']!;
      _emailController.text = targetEmail;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => FaceIdScannerSheet(
        userName: targetName,
        userEmail: targetEmail,
        isEnrollment: false,
        onSuccess: () {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          setState(() {
            _isFaceIdVerified = true;
            _currentStep = 2;
            _errorMessage = null;
          });
          _showSnackBar('Identitas Terverifikasi via Face ID untuk $targetName! Silakan buat kata sandi baru.');
        },
      ),
    );
  }

  Future<void> _sendRecoveryEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKeyEmail.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _startResendTimer();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 1;
        _errorMessage = null;
      });
      _showSnackBar('Kode verifikasi telah dikirimkan ke email $email');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error Server: "${e.message}" (Kode: ${e.statusCode})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0 || _isLoading) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _otpController.clear();
      _startResendTimer();
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Kode baru berhasil dikirim ulang ke email $email');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _parseAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _parseAuthError(e.toString());
      });
    }
  }

  Future<void> _verifyOtpCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final token = _otpController.text.trim().replaceAll(' ', '');
    if (token.length != _codeLength && token.length != 6) {
      setState(() => _errorMessage = 'Harap masukkan 8-digit kode verifikasi dari email.');
      return;
    }

    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool verified = false;
      String? lastError;

      // Coba berurutan: recovery, email, magiclink
      for (final type in [OtpType.recovery, OtpType.email, OtpType.magiclink]) {
        try {
          final res = await Supabase.instance.client.auth.verifyOTP(
            email: email,
            token: token,
            type: type,
          );
          if (res.user != null || res.session != null) {
            verified = true;
            break;
          }
        } catch (e) {
          lastError = e is AuthException ? e.message : e.toString();
        }
      }

      if (!verified) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = lastError != null
              ? 'Gagal Verifikasi: $lastError (Pastikan memakai kode dari email terbaru yang baru masuk).'
              : 'Kode verifikasi salah atau telah kedaluwarsa. Periksa kembali email Anda.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 2;
        _errorMessage = null;
      });
      _showSnackBar('Kode verifikasi berhasil dikonfirmasi! Silakan buat kata sandi baru.');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _parseAuthError(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memverifikasi kode. Pastikan koneksi internet stabil.';
      });
    }
  }

  Future<void> _saveNewPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKeyPassword.currentState?.validate() ?? false)) return;

    final newPassword = _newPasswordController.text;
    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));

      try {
        final prefs = await SharedPreferences.getInstance();
        final key = email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        await prefs.setString('foodie_face_pwd_$key', newPassword);
        await prefs.setString('foodie_last_user_email', email);
        await prefs.setString('foodie_saved_password', newPassword);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 3;
        _errorMessage = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _parseAuthError(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal menyimpan kata sandi baru. Silakan coba lagi.';
      });
    }
  }

  void _handleBack() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _errorMessage = null;
      });
    } else if (_currentStep == 2 && !_isFaceIdVerified) {
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
      });
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.charcoal),
                    ),
                  ),
                  const FoodieHeaderLogo(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppColors.tint(AppColors.red, 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.tint(AppColors.red, 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (_currentStep == 0)
                          _buildStep1Email()
                        else if (_currentStep == 1)
                          _buildStep2OtpVerification()
                        else if (_currentStep == 2)
                          _buildStep3NewPassword()
                        else
                          _buildStep4Success(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Email() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StepIconBadge(
            icon: Icons.lock_reset_rounded,
            color: AppColors.orange,
            bgColor: AppColors.tint(AppColors.orange, 0.12),
            borderColor: AppColors.tint(AppColors.orange, 0.25),
          ),
          const SizedBox(height: 20),
          Text('Lupa Kata Sandi', textAlign: TextAlign.center, style: AppText.display(24)),
          const SizedBox(height: 8),
          const Text(
            'Masukkan email yang terdaftar pada akun Anda. Kami akan mengirimkan kode verifikasi untuk mengatur ulang kata sandi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 26),
          AppTextField(
            label: 'Alamat Email',
            hint: 'nama@gmail.com',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendRecoveryEmail(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Kirim Kode Verifikasi',
            loading: _isLoading,
            onPressed: _sendRecoveryEmail,
          ),
          if (_hasFaceIdEnrolled) ...[
            const SizedBox(height: 14),
            SoftButton(
              label: 'Pulihkan dengan Face ID',
              icon: Icons.face_retouching_natural_rounded,
              onPressed: _verifyWithFaceId,
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleBack,
            child: const Text(
              'Kembali ke Halaman Masuk',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2OtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StepIconBadge(
          icon: Icons.mark_email_read_rounded,
          color: AppColors.orange,
          bgColor: AppColors.tint(AppColors.orange, 0.12),
        ),
        const SizedBox(height: 20),
        Text('Verifikasi Kode', textAlign: TextAlign.center, style: AppText.display(24)),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
              fontFamily: AppFonts.body,
            ),
            children: [
              const TextSpan(text: 'Kode verifikasi telah dikirimkan ke email '),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const TextSpan(text: '. Silakan periksa folder Kotak Masuk atau Spam email Anda.'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'KODE VERIFIKASI',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: _otpController,
                builder: (context, _) {
                  final text = _otpController.text;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (i) {
                      final char = i < text.length ? text[i] : '';
                      final isActive = i == text.length.clamp(0, _codeLength - 1);
                      return _OtpDigitBox(char: char, active: isActive);
                    }),
                  );
                },
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _focusNodeOtp,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: _codeLength,
                    enableSuggestions: false,
                    autocorrect: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {});
                      if (val.trim().length == _codeLength) _verifyOtpCode();
                    },
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak menerima email? ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            GestureDetector(
              onTap: _secondsLeft == 0 ? _resendCode : null,
              child: Text(
                _secondsLeft == 0 ? 'Kirim Ulang' : 'Kirim Ulang ($_timerLabel)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _secondsLeft == 0 ? AppColors.red : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Verifikasi Kode', loading: _isLoading, onPressed: _verifyOtpCode),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _handleBack,
          child: const Text('Ganti Alamat Email',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildStep3NewPassword() {
    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StepIconBadge(
            icon: Icons.lock_outline_rounded,
            color: AppColors.green,
            bgColor: AppColors.tint(AppColors.green, 0.12),
            borderColor: AppColors.tint(AppColors.green, 0.25),
          ),
          const SizedBox(height: 20),
          Text('Buat Kata Sandi Baru', textAlign: TextAlign.center, style: AppText.display(24)),
          const SizedBox(height: 8),
          const Text(
            'Kode verifikasi berhasil dikonfirmasi. Silakan buat kata sandi baru untuk mengamankan akun Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 26),
          AppTextField(
            label: 'Kata Sandi Baru',
            hint: 'Minimal 8 karakter',
            icon: Icons.lock_outline_rounded,
            controller: _newPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            helper: 'Gunakan minimal 8 karakter dengan kombinasi angka & huruf.',
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Konfirmasi Kata Sandi Baru',
            hint: 'Ulangi kata sandi baru',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.confirm(v, _newPasswordController.text),
            onFieldSubmitted: (_) => _saveNewPassword(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Simpan Kata Sandi', loading: _isLoading, onPressed: _saveNewPassword),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _handleBack,
            child: const Text('Batal & Kembali',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _StepIconBadge(
          icon: Icons.check_rounded,
          color: AppColors.green,
          bgColor: AppColors.tint(AppColors.green, 0.12),
          borderColor: AppColors.tint(AppColors.green, 0.3),
          size: 72,
          iconSize: 38,
        ),
        const SizedBox(height: 22),
        Text('Kata Sandi Berhasil Diperbarui', textAlign: TextAlign.center, style: AppText.display(22)),
        const SizedBox(height: 10),
        const Text(
          'Kata sandi akun Anda telah berhasil diubah. Silakan masuk kembali dengan menggunakan kata sandi yang baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Masuk Sekarang', onPressed: _navigateToLogin),
      ],
    );
  }
}

class _StepIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const _StepIconBadge({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.borderColor,
    this.size = 60,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.2) : null,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  final String char;
  final bool active;

  const _OtpDigitBox({required this.char, required this.active});

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;

    return Container(
      width: 36,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (active || filled) ? AppColors.orange : AppColors.line,
          width: active ? 1.8 : 1.0,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        char.isEmpty ? '•' : char,
        style: TextStyle(
          fontSize: char.isEmpty ? 16 : 20,
          fontWeight: FontWeight.w700,
          color: char.isEmpty ? AppColors.line : AppColors.textDark,
        ),
      ),
    );
  }
}
