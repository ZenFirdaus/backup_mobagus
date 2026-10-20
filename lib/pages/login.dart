import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/text_field.dart';
import 'biometric.dart';
import 'home.dart';
import 'register.dart';

/// Login dengan username + password.
/// - Jika akun ditemukan di Supabase → login online, simpan sesi ke Hive.
/// - Login lokal offline juga dicek dari Hive jika offline.
class LoginPage extends StatefulWidget {
  final String? initialUsername;
  const LoginPage({super.key, this.initialUsername});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goHome(String name) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage(name: name)),
      (route) => false,
    );
  }

  void _goBiometric(String name) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => BiometricPage(name: name)),
      (route) => false,
    );
  }

  /// Simpan sesi login lokal ke Hive agar bisa login offline
  Future<void> _saveLocalSession(String username, String password, {String? email}) async {
    try {
      final box = await Hive.openBox('foodie_auth');
      await box.put('local_username', username);
      await box.put('local_password', password);
      if (email != null) {
        await box.put('map_user_$username', email);
      }
    } catch (_) {}
  }

  /// Coba login dari cache Hive (mode offline)
  Future<bool> _tryLocalLogin(String username, String password) async {
    try {
      final box = await Hive.openBox('foodie_auth');
      final savedUser = box.get('local_username') as String?;
      final savedPass = box.get('local_password') as String?;
      return (savedUser == username || box.get('map_user_$username') == savedUser) && savedPass == password;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final inputUser = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Supabase menggunakan email untuk auth
    String emailToUse = inputUser;
    if (!inputUser.contains('@')) {
      try {
        final box = await Hive.openBox('foodie_auth');
        final cachedEmail = box.get('map_user_$inputUser') as String?;
        if (cachedEmail != null && cachedEmail.isNotEmpty) {
          emailToUse = cachedEmail;
        } else {
          // Cari email dari tabel profiles jika ada
          final res = await Supabase.instance.client
              .from('profiles')
              .select('email')
              .eq('username', inputUser)
              .maybeSingle();
          if (res != null && res['email'] != null) {
            emailToUse = res['email'] as String;
          }
        }
      } catch (_) {}
    }

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );
      if (!mounted) return;
      setState(() => _loading = false);

      final displayName = res.user?.userMetadata?['name'] as String? ??
          res.user?.userMetadata?['username'] as String? ??
          inputUser;

      // Simpan sesi lokal Hive untuk login offline
      await _saveLocalSession(inputUser, password, email: emailToUse);

      // Cek apakah perlu setup biometric
      _goHome(displayName);
    } on AuthException catch (e) {
      if (!mounted) return;

      // Coba login lokal (offline/Hive)
      final localOk = await _tryLocalLogin(inputUser, password);
      if (localOk && mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login offline menggunakan data tersimpan.'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _goHome(inputUser);
        return;
      }

      setState(() => _loading = false);

      String msg = e.message;
      if (msg.toLowerCase().contains('invalid login') ||
          msg.toLowerCase().contains('invalid credentials') ||
          msg.toLowerCase().contains('wrong password')) {
        msg = 'Username atau kata sandi salah. Silakan periksa kembali.';
      } else if (msg.toLowerCase().contains('email not confirmed')) {
        msg = 'Email belum diverifikasi. Masuk dalam mode terbatas.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _goHome(inputUser);
        }
        return;
      } else if (msg.toLowerCase().contains('network') ||
          msg.toLowerCase().contains('connection')) {
        msg = 'Tidak ada koneksi internet. Coba cek jaringan Anda.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Coba login lokal jika ada error jaringan
      final localOk = await _tryLocalLogin(inputUser, password);
      setState(() => _loading = false);

      if (localOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login offline menggunakan data tersimpan.'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _goHome(inputUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
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
                  // ── Header: back + logo FOODIE (tanpa DIY) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line, width: 1),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                      // Logo FOODIE tanpa DIY badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.paprika,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'F',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'FOODIE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Masuk Akun', style: AppText.display(26)),
                  const SizedBox(height: 6),
                  const Text(
                    'Jelajahi kuliner autentik dengan akun Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Username ──
                  AppTextField(
                    label: 'Username',
                    hint: 'Masukkan username Anda',
                    icon: Icons.person_outline_rounded,
                    controller: _usernameCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Username'),
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.required(v, 'Kata sandi'),
                  ),
                  const SizedBox(height: 22),

                  PrimaryButton(
                    label: 'Masuk',
                    trailingArrow: true,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 14),

                  SoftButton(
                    label: 'Jelajahi Sebagai Tamu',
                    icon: Icons.person_outline_rounded,
                    onPressed: () => _goHome('Tamu'),
                  ),
                  const SizedBox(height: 24),
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
