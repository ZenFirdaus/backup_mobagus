import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/foodie_logo.dart';
import '../widgets/text_field.dart';
import '../widgets/face_id_scanner_sheet.dart';
import '../services/face_biometric_service.dart';
import 'home.dart';
import 'onboarding.dart';
import 'register.dart';
import 'forgot_password_page.dart';
import '../services/supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _saveUserSession(String name, String email,
      [String? password]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('foodie_last_user_name', name);
      await prefs.setString('foodie_last_user_email', email);
      if (password != null && password.isNotEmpty) {
        await prefs.setString('foodie_saved_password', password);
      }
    } catch (_) {}
  }

  void _goHome(String name, {bool biometricOn = false}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          name: name,
          biometricOn: biometricOn,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final pwd = _password.text;
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: pwd,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      final name =
          res.user?.userMetadata?['name'] as String? ??
          _email.text.trim().split('@').first;
      await _saveUserSession(name, _email.text.trim(), pwd);
      await SupabaseService.instance.initStorage(force: true);

      final isEnrolled = await FaceBiometricService.instance.isFaceEnrolled();
      if (!isEnrolled) {
        if (!mounted) return;
        _showEnrollBiometricPrompt(name, _email.text.trim(), pwd);
      } else {
        _goHome(name, biometricOn: true);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String msg = e.message;
      if (msg.toLowerCase().contains('invalid login credentials')) {
        msg = 'Email atau kata sandi salah. Silakan periksa kembali.';
      } else if (msg.toLowerCase().contains('email not confirmed')) {
        msg = 'Email belum diverifikasi. Masuk langsung dalam mode demo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        final name = _email.text.trim().split('@').first;
        await _saveUserSession(name, _email.text.trim(), pwd);
        SupabaseService.instance.setDemoUser(_email.text.trim());
        await SupabaseService.instance.initStorage(force: true);

        final isEnrolled = await FaceBiometricService.instance.isFaceEnrolled();
        if (!isEnrolled) {
          if (!mounted) return;
          _showEnrollBiometricPrompt(name, _email.text.trim(), pwd);
        } else {
          _goHome(name, biometricOn: true);
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final fallbackName = _email.text.trim().split('@').first;
      final resolvedName =
          fallbackName.isEmpty ? 'Dimas Dananjaya' : fallbackName;
      await _saveUserSession(resolvedName, _email.text.trim(), pwd);
      SupabaseService.instance.setDemoUser(_email.text.trim());
      await SupabaseService.instance.initStorage(force: true);

      final isEnrolled = await FaceBiometricService.instance.isFaceEnrolled();
      if (!isEnrolled) {
        if (!mounted) return;
        _showEnrollBiometricPrompt(resolvedName, _email.text.trim(), pwd);
      } else {
        _goHome(resolvedName, biometricOn: true);
      }
    }
  }

  /// Tombol Login Wajah di halaman login:
  /// Masuk cepat menggunakan pemindai kamera Apple Face ID.
  /// Hanya dapat digunakan jika user sudah login email & mendaftarkan wajah sebelumnya.
  Future<void> _loginWithFaceId() async {
    final isEnrolled = await FaceBiometricService.instance.isFaceEnrolled();
    final prefs = await SharedPreferences.getInstance();
    final String? savedName = prefs.getString('foodie_last_user_name');
    final String? savedEmail = prefs.getString('foodie_last_user_email');
    final String? savedPassword = prefs.getString('foodie_saved_password');

    // Jika belum login email dan belum mendaftarkan wajah:
    if (!isEnrolled || savedName == null || savedName.trim().isEmpty || savedEmail == null) {
      if (!mounted) return;
      _showBiometricNotEnrolledSheet();
      return;
    }

    final userName = savedName.trim();
    final userEmail = savedEmail.trim();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => FaceIdScannerSheet(
        userName: userName,
        userEmail: userEmail,
        savedPassword: savedPassword,
        isEnrollment: false,
        onSuccess: () async {
          Navigator.of(ctx).pop();

          // AUTENTIKASI SUPABASE SECARA REAL-TIME DENGAN FACE ID:
          if (savedPassword != null &&
              savedPassword.isNotEmpty &&
              savedEmail.isNotEmpty) {
            try {
              await Supabase.instance.client.auth.signInWithPassword(
                email: savedEmail,
                password: savedPassword,
              );
            } catch (_) {
              // Jika offline atau jaringan lambat, sesi lokal tetap aktif
            }
          }
          if (SupabaseService.instance.userId == null &&
              savedEmail.isNotEmpty) {
            SupabaseService.instance.setDemoUser(savedEmail);
          }
          await SupabaseService.instance.initStorage(force: true);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.face_unlock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Face ID terverifikasi. Selamat datang kembali, $userName',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          _goHome(userName, biometricOn: true);
        },
      ),
    );
  }

  /// Sheet jika wajah belum terdaftar (wajib login email & kata sandi terlebih dahulu)
  void _showBiometricNotEnrolledSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.orange, 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_accounts_rounded,
                  size: 34,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'APPLE FACE ID • KEAMANAN BIOMETRIK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Face ID Belum Didaftarkan',
                textAlign: TextAlign.center,
                style: AppText.display(20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Untuk menggunakan Apple Face ID, Anda harus masuk menggunakan Email & Kata Sandi terlebih dahulu. Setelah berhasil masuk ke akun, Anda dapat mendaftarkan wajah Anda melalui kamera depan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Masuk dengan Email & Kata Sandi',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 10),
              SoftButton(
                label: 'Daftar Akun Baru',
                icon: Icons.person_add_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  _toRegister();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog penawaran daftarkan wajah setelah pengguna berhasil login manual
  void _showEnrollBiometricPrompt(String name, String email,
      [String? password]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.orange, 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 34,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FITUR LOGIN CEPAT & AMAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Daftarkan Wajah Anda?',
                textAlign: TextAlign.center,
                style: AppText.display(20),
              ),
              const SizedBox(height: 8),
              Text(
                'Sugeng rawuh, $name! Anda telah berhasil masuk. Daftarkan wajah Anda sekarang agar di kunjungan berikutnya bisa masuk dengan 1-ketukan instan tanpa kata sandi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Daftarkan Wajah Sekarang',
                icon: Icons.face_retouching_natural_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  _openEnrollFaceSheet(name, email, password);
                },
              ),
              const SizedBox(height: 10),
              SoftButton(
                label: 'Nanti Saja (Masuk ke Beranda)',
                onPressed: () {
                  Navigator.pop(ctx);
                  _goHome(name, biometricOn: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Buka sheet scanner pendaftaran wajah setelah login manual
  void _openEnrollFaceSheet(String name, String email, [String? password]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => FaceIdScannerSheet(
        userName: name,
        userEmail: email,
        savedPassword: password,
        isEnrollment: true,
        onSuccess: () async {
          Navigator.of(ctx).pop();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.face_unlock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Face ID berhasil didaftarkan untuk $name.',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          _goHome(name, biometricOn: true);
        },
      ),
    );
  }

  void _toRegister() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(
          initialEmail: _email.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const OnboardingPage(),
                              ),
                            );
                          }
                        },
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
                  const SizedBox(height: 28),
                  Center(
                    child: Text('Masuk', style: AppText.display(26)),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Email',
                    hint: 'nama@gmail.com',
                    icon: Icons.mail_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi',
                    icon: Icons.lock_rounded,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'Kata sandi'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _remember,
                          activeColor: AppColors.greenDark,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) =>
                              setState(() => _remember = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ingat saya',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openForgotPassword,
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Masuk',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  SoftButton(
                    label: 'Masuk dengan Face ID',
                    icon: Icons.face_retouching_natural_rounded,
                    onPressed: _loginWithFaceId,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toRegister,
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Supabase Auth • TLS 1.3 End-to-End',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet Pemindai Wajah Real-Time berstandar tema utama FOODIE (Warm Gastronomic Pass)
