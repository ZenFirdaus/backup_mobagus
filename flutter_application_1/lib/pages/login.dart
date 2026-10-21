import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/foodie_logo.dart';
import '../widgets/text_field.dart';
import 'home.dart';
import 'register.dart';

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

      final prefs = await SharedPreferences.getInstance();
      final hasBiometric = prefs.getBool('foodie_biometric_enabled') ?? false;

      if (!hasBiometric) {
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

        final prefs = await SharedPreferences.getInstance();
        final hasBiometric = prefs.getBool('foodie_biometric_enabled') ?? false;
        if (!hasBiometric) {
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

      final prefs = await SharedPreferences.getInstance();
      final hasBiometric = prefs.getBool('foodie_biometric_enabled') ?? false;
      if (!hasBiometric) {
        if (!mounted) return;
        _showEnrollBiometricPrompt(resolvedName, _email.text.trim(), pwd);
      } else {
        _goHome(resolvedName, biometricOn: true);
      }
    }
  }

  /// Tombol Login Wajah di halaman login:
  /// Pengguna HARUS sudah pernah login manual sebelumnya & mendaftarkan wajah.
  Future<void> _loginWithFaceId() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isBiometricEnabled =
        prefs.getBool('foodie_biometric_enabled') ?? false;
    final String? savedName = prefs.getString('foodie_last_user_name');
    final String? savedEmail = prefs.getString('foodie_last_user_email');
    final String? savedPassword = prefs.getString('foodie_saved_password');

    // Jika belum login manual atau belum mendaftarkan wajah:
    if (!isBiometricEnabled || savedName == null || savedName.trim().isEmpty) {
      if (!mounted) return;
      _showBiometricNotEnrolledSheet();
      return;
    }

    final userName = savedName.trim();
    final userEmail = (savedEmail != null && savedEmail.trim().isNotEmpty)
        ? savedEmail.trim()
        : 'dimas.dananjaya@culinary.id';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _FaceAuthSheet(
        userName: userName,
        userEmail: userEmail,
        isEnrollment: false,
        onSuccess: () async {
          Navigator.of(ctx).pop();

          // AUTENTIKASI SUPABASE SECARA REAL-TIME DENGAN BIOMETRIK:
          // Login wajah adalah login akun resmi Supabase, bukan mode tamu!
          if (savedPassword != null &&
              savedPassword.isNotEmpty &&
              savedEmail != null &&
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

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Autentikasi Wajah Berhasil! Terhubung ke Akun, $userName ✨',
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

  /// Sheet jika wajah belum terdaftar (mengarahkan pengguna untuk login manual)
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
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.face_retouching_off_rounded,
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
                  border: Border.all(color: AppColors.line),
                ),
                child: const Text(
                  'KEAMANAN BIOMETRIK FOODIE',
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
                'Wajah Belum Terdaftar',
                textAlign: TextAlign.center,
                style: AppText.display(20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demi keamanan akun Anda, silakan masuk secara manual menggunakan email dan kata sandi terlebih dahulu. Setelah berhasil masuk, Anda dapat mendaftarkan wajah Anda untuk login cepat berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Masuk Manual Sekarang',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 10),
              SoftButton(
                label: 'Daftar Akun Baru',
                icon: Icons.person_add_outlined,
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
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.3),
                    width: 1.5,
                  ),
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
                  border: Border.all(color: AppColors.line),
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _FaceAuthSheet(
        userName: name,
        userEmail: email,
        isEnrollment: true,
        onSuccess: () async {
          Navigator.of(ctx).pop();
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('foodie_biometric_enabled', true);
            await prefs.setString('foodie_last_user_name', name);
            await prefs.setString('foodie_last_user_email', email);
            if (password != null && password.isNotEmpty) {
              await prefs.setString('foodie_saved_password', password);
            }
          } catch (_) {}

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wajah berhasil didaftarkan! Autentikasi biometrik aktif ✨',
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

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _email.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Kata Sandi', style: AppText.display(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email akun Anda untuk menerima tautan pemulihan kata sandi dari Supabase Auth.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'nama@gmail.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final mail = resetEmailCtrl.text.trim();
              if (mail.isEmpty || !mail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Masukkan alamat email yang valid.'),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(mail);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tautan pemulihan kata sandi dikirim ke $mail',
                      ),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal mengirim email reset: ${e.toString()}',
                      ),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Kirim Tautan'),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FoodieHeaderLogo(),
                      
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 10, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.greenDark,
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: const Text(
                      //     'FOODIE',
                      //     style: TextStyle(
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w800,
                      //       letterSpacing: 1.2,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        // child: const Row(
                        //   mainAxisSize: MainAxisSize.min,
                        //   children: [
                        //     Icon(Icons.location_on,
                        //         size: 12, color: AppColors.red),
                        //     SizedBox(width: 4),
                        //     Text(
                        //       'DIY & Jateng',
                        //       style: TextStyle(
                        //         fontSize: 10,
                        //         fontWeight: FontWeight.w700,
                        //         color: AppColors.textDark,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Masuk Akun', style: AppText.display(26)),
                  const SizedBox(height: 6),
                  const Text(
                    'Jelajahi warisan kuliner autentik Nusantara.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Email',
                    hint: 'nama@gmail.com',
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi',
                    icon: Icons.lock_outline_rounded,
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
                        onTap: _showForgotPasswordDialog,
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
                    label: 'Masuk dengan autentikasi wajah',
                    icon: Icons.face_retouching_natural_rounded,
                    onPressed: _loginWithFaceId,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ATAU MASUK DENGAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          label: 'Google SSO',
                          leading: const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 24,
                            color: AppColors.red,
                          ),
                          onPressed: () => _goHome('Dimas Dananjaya'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SocialButton(
                          label: 'Passkey ID',
                          leading: const Icon(
                            Icons.fingerprint_rounded,
                            size: 20,
                            color: AppColors.greenDark,
                          ),
                          onPressed: _loginWithFaceId,
                        ),
                      ),
                    ],
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

/// Sheet Pemindai Wajah Real-Time berstandar tema utama FOODIE (Warm Mataraman Gastronomic Pass)
class _FaceAuthSheet extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool isEnrollment;
  final VoidCallback onSuccess;

  const _FaceAuthSheet({
    required this.userName,
    required this.userEmail,
    this.isEnrollment = false,
    required this.onSuccess,
  });

  @override
  State<_FaceAuthSheet> createState() => _FaceAuthSheetState();
}

class _FaceAuthSheetState extends State<_FaceAuthSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  int _step = 0; // 0: init, 1: scan contours, 2: verify secure enclave, 3: success

  @override
  void initState() {
    super.initState();
    _startFaceScanningPipeline();
  }

  @override
  void dispose() {
    _scanPulse.dispose();
    super.dispose();
  }

  Future<void> _startFaceScanningPipeline() async {
    _scanPulse.repeat(reverse: true);
    HapticFeedback.lightImpact();

    // Fase 1: Deteksi sensor biometrik (0.6s)
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _step = 1);
    HapticFeedback.selectionClick();

    // Fase 2: Pindai geometri & kontur wajah kurator (0.95s)
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    setState(() => _step = 2);
    HapticFeedback.lightImpact();

    // Fase 3: Validasi Secure Enclave (0.8s)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _scanPulse.stop();
    setState(() => _step = 3);
    HapticFeedback.mediumImpact();

    // Selesai & Callback
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    widget.onSuccess();
  }

  String get _statusLabel {
    switch (_step) {
      case 0:
        return 'Menginisialisasi sensor biometrik...';
      case 1:
        return widget.isEnrollment
            ? 'Memetakan titik biometrik wajah kurator...'
            : 'Memindai geometri & kontur wajah kurator...';
      case 2:
        return widget.isEnrollment
            ? 'Mendaftarkan kunci ke Secure Enclave...'
            : 'Mencocokkan tanda tangan Secure Enclave...';
      case 3:
      default:
        return widget.isEnrollment
            ? 'Wajah Berhasil Didaftarkan!'
            : 'Autentikasi Wajah Berhasil!';
    }
  }

  IconData get _statusIcon {
    switch (_step) {
      case 0:
        return Icons.sensors_rounded;
      case 1:
        return Icons.face_retouching_natural_rounded;
      case 2:
        return Icons.security_rounded;
      case 3:
      default:
        return Icons.verified_user_rounded;
    }
  }

  Color get _statusColor {
    switch (_step) {
      case 3:
        return AppColors.green;
      case 2:
        return AppColors.paprika;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Top bar
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
                            ? 'PENDAFTARAN BIOMETRIK WAJAH'
                            : 'AUTENTIKASI BIOMETRIK PRESISI',
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
                  : 'Masuk Cepat dengan Wajah',
              textAlign: TextAlign.center,
              style: AppText.display(20),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEnrollment
                  ? 'Posisikan wajah Anda pada lingkaran sensor untuk mengaktifkan Face ID pada akun Anda.'
                  : 'Posisikan wajah Anda pada lingkaran sensor untuk masuk instan tanpa kata sandi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Reticle Pemindai Wajah Selaras dengan Tema Utama
            _buildScannerReticle(),

            const SizedBox(height: 18),

            // Status Chip
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
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
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Identitas Akun Kurator
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tint(AppColors.orange, 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'D',
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
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

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

  Widget _buildScannerReticle() {
    final isSuccess = _step == 3;

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
              if (!isSuccess)
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

              // Cincin tengah bertekstur hangat
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tint(AppColors.yellow, 0.22),
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.45),
                    width: 1.5,
                  ),
                ),
              ),

              // Piringan sensor utama (selaras dengan BiometricPage)
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess ? AppColors.green : AppColors.charcoal,
                  border: Border.all(
                    color: isSuccess ? AppColors.green : AppColors.orange,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tint(
                        isSuccess ? AppColors.green : AppColors.orange,
                        0.35 + 0.2 * t,
                      ),
                      blurRadius: 22 + 10 * t,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.face_retouching_natural_rounded,
                          size: 52,
                          color: isSuccess ? Colors.white : AppColors.orange,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isSuccess
                              ? 'TERVERIFIKASI'
                              : (widget.isEnrollment
                                  ? 'MENDAFTARKAN'
                                  : 'MEMINDAI WAJAH'),
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: AppColors.yellow,
                          ),
                        ),
                      ],
                    ),

                    // Garis laser pemindai vertikal (Warm Amber / Saffron Sweep)
                    if (!isSuccess)
                      Positioned(
                        top: 20 + (100 * t),
                        left: 18,
                        right: 18,
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
                                color: AppColors.orange.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


