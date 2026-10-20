import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/text_field.dart';
import 'login.dart';
import 'verify_email.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui syarat dan ketentuan.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final usernameVal = _username.text.trim();
    final emailVal = _email.text.trim();

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: emailVal,
        password: _password.text,
        data: {
          'name': usernameVal,
          'username': usernameVal,
        },
      );

      // Simpan asosiasi username <-> email ke Hive lokal
      try {
        final box = await Hive.openBox('foodie_auth');
        await box.put('map_user_$usernameVal', emailVal);
        await box.put('map_user_${usernameVal.toLowerCase()}', emailVal);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _loading = false);

      // Jika confirm email dimatikan di Supabase, user langsung dapat session atau email sudah confirmed
      if (res.session != null || (res.user != null && res.user!.emailConfirmedAt != null)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(initialUsername: usernameVal),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(name: usernameVal, email: emailVal),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String msg = e.message;
      if (msg.toLowerCase().contains('already registered') ||
          msg.toLowerCase().contains('already exists') ||
          msg.toLowerCase().contains('email already')) {
        msg = 'Email sudah terdaftar. Silakan masuk.';
      } else if (msg.toLowerCase().contains('invalid email')) {
        msg = 'Format email tidak valid.';
      } else if (msg.toLowerCase().contains('weak password') ||
          msg.toLowerCase().contains('should be at least')) {
        msg = 'Kata sandi terlalu lemah. Minimal 8 karakter.';
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
      setState(() => _loading = false);

      // Jika Supabase tidak kirim konfirmasi email, langsung lanjut
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              VerifyEmailPage(name: usernameVal, email: emailVal),
        ),
      );
    }
  }

  void _toLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
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
                  // ── Header ──
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
                      // Logo FOODIE (tanpa DIY)
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
                  const SizedBox(height: 24),
                  Text('Buat Akun Baru', style: AppText.display(26)),
                  const SizedBox(height: 6),
                  const Text(
                    'Daftar untuk menjelajahi kuliner autentik Nusantara.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),

                  // ── Username ──
                  AppTextField(
                    label: 'Username',
                    hint: 'contoh: budi_jogja',
                    icon: Icons.person_outline_rounded,
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    validator: Validators.username,
                  ),
                  const SizedBox(height: 12),

                  // ── Email ──
                  AppTextField(
                    label: 'Email',
                    hint: 'nama@email.com',
                    icon: Icons.mail_outline_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),

                  // ── Password ──
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Minimal 8 karakter',
                    icon: Icons.lock_outline_rounded,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),

                  // ── Konfirmasi Password ──
                  AppTextField(
                    label: 'Konfirmasi Kata Sandi',
                    hint: 'Ulangi kata sandi',
                    icon: Icons.lock_outline_rounded,
                    controller: _confirm,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirm(v, _password.text),
                  ),
                  const SizedBox(height: 14),

                  // ── Agree ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _agree,
                          activeColor: AppColors.greenDark,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setState(() => _agree = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Saya menyetujui Syarat & Ketentuan FOODIE',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  PrimaryButton(
                    label: 'Daftar',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah memiliki akun? ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toLogin,
                          child: const Text(
                            'Masuk',
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
