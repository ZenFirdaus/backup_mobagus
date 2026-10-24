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

      await _handlePostLoginNavigation(name, _email.text.trim(), pwd);
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

        await _handlePostLoginNavigation(name, _email.text.trim(), pwd);
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
          fallbackName.isEmpty ? 'Kurator Rasa' : fallbackName;
      await _saveUserSession(resolvedName, _email.text.trim(), pwd);
      SupabaseService.instance.setDemoUser(_email.text.trim());
      await SupabaseService.instance.initStorage(force: true);

      await _handlePostLoginNavigation(resolvedName, _email.text.trim(), pwd);
    }
  }

  /// Tombol Login Wajah di halaman login:
  /// Masuk cepat menggunakan pemindai kamera Apple Face ID.
  /// Hanya dapat digunakan jika akun pengguna sudah mendaftarkan wajah sebelumnya.
  Future<void> _loginWithFaceId() async {
    final inputEmail = _email.text.trim();
    String targetEmail;
    String targetName;
    String? targetPassword;

    if (inputEmail.isNotEmpty) {
      // 1. Jika user mengetikkan email, pastikan Face ID terdaftar KHUSUS untuk email tersebut
      final isUserEnrolled = await FaceBiometricService.instance.isFaceEnrolled(
        email: inputEmail,
      );
      if (!isUserEnrolled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Face ID belum didaftarkan untuk akun $inputEmail. Silakan masuk menggunakan kata sandi.',
            ),
            backgroundColor: AppColors.charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = inputEmail.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      targetEmail = inputEmail;
      targetName = prefs.getString('foodie_face_name_$key') ??
          prefs.getString('foodie_last_user_name') ??
          inputEmail.split('@').first;
      targetPassword = prefs.getString('foodie_face_pwd_$key') ??
          prefs.getString('foodie_saved_password');
    } else {
      // 2. Jika email belum diisi, periksa akun biometrik aktif yang terdaftar di perangkat ini
      final account = await FaceBiometricService.instance.getActiveBiometricAccount();
      if (account == null) {
        if (!mounted) return;
        _showBiometricNotEnrolledSheet();
        return;
      }
      targetEmail = account['email']!;
      targetName = account['name']!;
      targetPassword = account['password'];
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
        savedPassword: targetPassword,
        isEnrollment: false,
        onSuccess: () async {
          Navigator.of(ctx).pop();

          // AUTENTIKASI SUPABASE SECARA REAL-TIME DENGAN FACE ID:
          if (targetPassword != null &&
              targetPassword.isNotEmpty &&
              targetEmail.isNotEmpty) {
            try {
              await Supabase.instance.client.auth.signInWithPassword(
                email: targetEmail,
                password: targetPassword,
              );
            } catch (_) {
              // Jika offline atau server lambat, fallback ke sesi lokal
            }
          }
          if (SupabaseService.instance.userId == null &&
              targetEmail.isNotEmpty) {
            SupabaseService.instance.setDemoUser(targetEmail);
          }

          await _saveUserSession(targetName, targetEmail, targetPassword);
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
                      'Face ID terverifikasi. Selamat datang kembali, $targetName',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          _goHome(targetName, biometricOn: true);
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

  Future<void> _handlePostLoginNavigation(
    String name,
    String email,
    String pwd,
  ) async {
    final isEnrolled = await FaceBiometricService.instance.isFaceEnrolled(
      email: email,
    );
    if (!mounted) return;
    _showPostLoginBiometricPrompt(
      name: name,
      email: email,
      password: pwd,
      alreadyEnrolled: isEnrolled,
    );
  }

  /// Dialog penawaran daftarkan wajah setelah pengguna berhasil login email
  void _showPostLoginBiometricPrompt({
    required String name,
    required String email,
    required String password,
    required bool alreadyEnrolled,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 22),

              // Icon Visual Premium
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.orange, 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.28),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.face_unlock_rounded,
                    size: 38,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      alreadyEnrolled
                          ? Icons.check_circle_rounded
                          : Icons.shield_rounded,
                      size: 13,
                      color: alreadyEnrolled ? AppColors.greenDark : AppColors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      alreadyEnrolled
                          ? 'FACE ID TELAH AKTIF DI AKUN INI'
                          : '1 AKUN KHUSUS 1 WAJAH TERDAFTAR',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: alreadyEnrolled
                            ? AppColors.greenDark
                            : AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Judul & Deskripsi
              Text(
                alreadyEnrolled
                    ? 'Perbarui Face ID Anda?'
                    : 'Daftarkan Wajah Face ID?',
                textAlign: TextAlign.center,
                style: AppText.display(22),
              ),
              const SizedBox(height: 8),
              Text(
                alreadyEnrolled
                    ? 'Akun $email telah memiliki data wajah terdaftar. Anda dapat memperbarui rekaman wajah atau langsung lanjut ke beranda.'
                    : 'Halo $name! Daftarkan pemindaian wajah Anda sekarang agar kunjungan berikutnya bisa masuk instan 1-ketukan tanpa kata sandi.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),

              // Feature Security Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.orange, 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 20,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Perlindungan Wajah Eksklusif',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '1 akun hanya terikat pada 1 wajah pemilik sah. Wajah orang lain akan otomatis ditolak.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              PrimaryButton(
                label: alreadyEnrolled
                    ? 'Pindai & Perbarui Wajah'
                    : 'Daftarkan Wajah Sekarang',
                icon: Icons.camera_alt_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  _openEnrollFaceSheet(name, email, password);
                },
              ),
              const SizedBox(height: 10),
              SoftButton(
                label: 'Langsung Masuk ke Beranda',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  _goHome(name, biometricOn: alreadyEnrolled);
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
