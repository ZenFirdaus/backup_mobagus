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
/// Alur terpisah dan terstruktur rapi:
/// 1. Masukkan Email -> Kirim Kode ke Email
/// 2. Masukkan 6-Digit Kode Verifikasi OTP -> Verifikasi Kode
/// 3. Masukkan & Konfirmasi Kata Sandi Baru -> Simpan Kata Sandi
/// 4. Konfirmasi Sukses -> Kembali ke Login
class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 60;

  // Form Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final _focusNodeOtp = FocusNode();

  // State Management
  // 0: Input Email, 1: Verifikasi Kode OTP, 2: Buat Kata Sandi Baru, 3: Sukses
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFaceIdVerified = false;
  bool _hasFaceIdEnrolled = false;
  String? _errorMessage;

  // Timer Kirim Ulang
  Timer? _resendTimer;
  int _secondsLeft = 0;

  // Auth Listener untuk mendeteksi link pemulihan email
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

  Future<void> _checkFaceIdStatus() async {
    try {
      final enrolled = await FaceBiometricService.instance.isFaceEnrolled();
      if (mounted) {
        setState(() => _hasFaceIdEnrolled = enrolled);
      }
    } catch (_) {}
  }

  void _listenToAuthRecovery() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (!mounted) return;
        // Jika user klik tautan dari email, langsung arahkan ke Step 2 (Buat Sandi Baru)
        setState(() {
          _currentStep = 2;
          _errorMessage = null;
        });
      }
    });
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

  String _parseAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('error sending recovery email') ||
        lower.contains('unexpected_failure')) {
      return 'Gagal mengirim email dari server Supabase. Pastikan pengaturan SMTP / email pada Dashboard Supabase sudah aktif dan kuota belum habis.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Terlalu banyak permintaan pengiriman email. Harap tunggu beberapa menit sebelum mencoba lagi.';
    }
    if (lower.contains('token has expired') || lower.contains('expired')) {
      return 'Kode verifikasi telah kedaluwarsa. Silakan kirim ulang kode baru.';
    }
    if (lower.contains('invalid') ||
        lower.contains('not match') ||
        lower.contains('token')) {
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

  /// Opsi Tambahan: Pulihkan Langsung via Face ID (jika terdaftar)
  Future<void> _verifyWithFaceId() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('foodie_last_user_name') ?? 'Pengguna';
    final savedEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (prefs.getString('foodie_last_user_email') ?? 'Akun Anda');

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => FaceIdScannerSheet(
        userName: savedName,
        userEmail: savedEmail,
        isEnrollment: false,
        onSuccess: () {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          setState(() {
            _isFaceIdVerified = true;
            _currentStep = 2; // Langsung ke halaman buat kata sandi baru
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Identitas Terverifikasi via Face ID! Silakan buat kata sandi baru.',
              ),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  /// LANGKAH 1: Kirim Kode Pemulihan ke Email
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
        _currentStep = 1; // Pindah ke Halaman Masukkan Kode OTP
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode verifikasi telah dikirimkan ke email $email'),
          backgroundColor: AppColors.greenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  /// Kirim Ulang Kode ke Email
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
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode baru berhasil dikirim ulang ke email $email'),
          backgroundColor: AppColors.greenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  /// LANGKAH 2: Verifikasi Kode OTP (Halaman Terpisah)
  Future<void> _verifyOtpCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final token = _otpController.text.trim();
    if (token.length != _codeLength) {
      setState(() {
        _errorMessage = 'Harap masukkan 6-digit kode verifikasi dari email.';
      });
      return;
    }

    final email = _emailController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool verified = false;

      // 1. Coba verifikasi dengan OtpType.recovery
      try {
        final res = await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.recovery,
        );
        if (res.user != null || res.session != null) {
          verified = true;
        }
      } catch (_) {}

      // 2. Coba verifikasi dengan OtpType.email jika template project menggunakan email OTP
      if (!verified) {
        try {
          final res = await Supabase.instance.client.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.email,
          );
          if (res.user != null || res.session != null) {
            verified = true;
          }
        } catch (_) {}
      }

      if (!verified) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Kode verifikasi salah atau telah kedaluwarsa. Periksa kembali email Anda.';
        });
        return;
      }

      // Verifikasi Berhasil -> Pindah ke Halaman Buat Kata Sandi Baru!
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 2; // Pindah ke Langkah Buat Kata Sandi Baru
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode verifikasi berhasil dikonfirmasi! Silakan buat kata sandi baru.',
          ),
          backgroundColor: AppColors.greenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        _errorMessage =
            'Gagal memverifikasi kode. Pastikan koneksi internet stabil.';
      });
    }
  }

  /// LANGKAH 3: Simpan Kata Sandi Baru (Halaman Terpisah)
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
      // 1. Simpan kata sandi baru ke Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Simpan dan perbarui kredensial lokal agar Face ID & login langsung sinkron
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('foodie_last_user_email', email);
        await prefs.setString('foodie_saved_password', newPassword);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 3; // Pindah ke Halaman Sukses
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
      // Dari Halaman Kode OTP kembali ke Halaman Input Email
      setState(() {
        _currentStep = 0;
        _errorMessage = null;
      });
    } else if (_currentStep == 2 && !_isFaceIdVerified) {
      // Dari Halaman Buat Sandi Baru kembali ke Halaman Kode OTP
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
      });
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
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
            // Top Navigation Bar
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
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  const FoodieHeaderLogo(),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),

                        // Error Banner Reusable
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tint(AppColors.red, 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.tint(AppColors.red, 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppColors.red,
                                ),
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

                        // Render Step Terkait Sesuai Alur Terpisah
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

  /// ──────────────────────────────────────────────────────────
  /// HALAMAN 1: Masukkan Alamat Email Akun
  /// ──────────────────────────────────────────────────────────
  Widget _buildStep1Email() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Avatar Minimalis
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tint(AppColors.orange, 0.25),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 28,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Lupa Kata Sandi',
            textAlign: TextAlign.center,
            style: AppText.display(24),
          ),
          const SizedBox(height: 8),

          const Text(
            'Masukkan email yang terdaftar pada akun Anda. Kami akan mengirimkan 6 digit kode verifikasi untuk mengatur ulang kata sandi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
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

          // Opsi Face ID jika perangkat sudah terdaftar
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
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ──────────────────────────────────────────────────────────
  /// HALAMAN 2: Masukkan Kode Verifikasi OTP (Terpisah Sendiri)
  /// ──────────────────────────────────────────────────────────
  Widget _buildStep2OtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon Avatar Minimalis
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 28,
              color: AppColors.orange,
            ),
        ),
        const SizedBox(height: 20),

        Text(
          'Verifikasi Kode',
          textAlign: TextAlign.center,
          style: AppText.display(24),
        ),
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
              const TextSpan(
                text: 'Kode verifikasi 6 digit telah dikirimkan ke email ',
              ),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(
                text:
                    '. Silakan periksa folder Kotak Masuk atau Spam email Anda.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'KODE VERIFIKASI (6 DIGIT)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // OTP Input Box
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
                      final isActive =
                          i == text.length.clamp(0, _codeLength - 1);
                      return _OtpDigitBox(
                        char: char,
                        active: isActive,
                      );
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (val) {
                      setState(() {});
                      if (val.trim().length == _codeLength) {
                        _verifyOtpCode();
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Kirim Ulang Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tidak menerima email? ',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            GestureDetector(
              onTap: _secondsLeft == 0 ? _resendCode : null,
              child: Text(
                _secondsLeft == 0
                    ? 'Kirim Ulang'
                    : 'Kirim Ulang ($_timerLabel)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color:
                      _secondsLeft == 0 ? AppColors.red : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Tombol Verifikasi Kode
        PrimaryButton(
          label: 'Verifikasi Kode',
          loading: _isLoading,
          onPressed: _verifyOtpCode,
        ),
        const SizedBox(height: 14),

        TextButton(
          onPressed: _handleBack,
          child: const Text(
            'Ganti Alamat Email',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  /// ──────────────────────────────────────────────────────────
  /// HALAMAN 3: Buat Kata Sandi Baru (Hanya Terbuka Setelah Kode Diverifikasi)
  /// ──────────────────────────────────────────────────────────
  Widget _buildStep3NewPassword() {
    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Avatar Minimalis
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.green, 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.tint(AppColors.green, 0.25),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 28,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Buat Kata Sandi Baru',
            textAlign: TextAlign.center,
            style: AppText.display(24),
          ),
          const SizedBox(height: 8),

          const Text(
            'Kode verifikasi berhasil dikonfirmasi. Silakan buat kata sandi baru untuk mengamankan akun Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),

          // Input Kata Sandi Baru
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

          // Konfirmasi Kata Sandi Baru
          AppTextField(
            label: 'Konfirmasi Kata Sandi Baru',
            hint: 'Ulangi kata sandi baru',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                Validators.confirm(v, _newPasswordController.text),
            onFieldSubmitted: (_) => _saveNewPassword(),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: 'Simpan Kata Sandi',
            loading: _isLoading,
            onPressed: _saveNewPassword,
          ),
          const SizedBox(height: 14),

          TextButton(
            onPressed: _handleBack,
            child: const Text(
              'Batal & Kembali',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ──────────────────────────────────────────────────────────
  /// HALAMAN 4: Konfirmasi Sukses
  /// ──────────────────────────────────────────────────────────
  Widget _buildStep4Success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.green, 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tint(AppColors.green, 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 38,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'Kata Sandi Berhasil Diperbarui',
          textAlign: TextAlign.center,
          style: AppText.display(22),
        ),
        const SizedBox(height: 10),

        Text(
          'Kata sandi akun Anda telah berhasil diubah. Silakan masuk kembali dengan menggunakan kata sandi yang baru.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        PrimaryButton(
          label: 'Masuk Sekarang',
          onPressed: _navigateToLogin,
        ),
      ],
    );
  }
}

/// Kotak Digit OTP Clean & Modern
class _OtpDigitBox extends StatelessWidget {
  final String char;
  final bool active;

  const _OtpDigitBox({
    required this.char,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;

    return Container(
      width: 44,
      height: 50,
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
