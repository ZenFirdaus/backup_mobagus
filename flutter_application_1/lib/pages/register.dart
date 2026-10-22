import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/foodie_logo.dart';
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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
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

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);
    final nameVal = _name.text.trim();
    final emailVal = _email.text.trim();

    try {
      await Supabase.instance.client.auth.signUp(
        email: emailVal,
        password: _password.text,
        data: {
          'name': nameVal,
          'phone': _phone.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            name: nameVal,
            email: emailVal,
            password: _password.text,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String msg = e.message;
      if (msg.toLowerCase().contains('already registered')) {
        msg = 'Email sudah terdaftar. Silakan masuk.';
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

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailPage(
            name: nameVal,
            email: emailVal,
            password: _password.text,
          ),
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
                          onTap: () => Navigator.of(context).maybePop(),
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
                  const SizedBox(height: 24),
                  Center(
                    child: Text('Daftar', style: AppText.display(26)),
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama Anda',
                    icon: Icons.person_rounded,
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Nama lengkap'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Email',
                    hint: 'nama@gmail.com',
                    icon: Icons.mail_rounded,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Nomor WhatsApp / Telepon',
                    hint: '0812 3456 7890',
                    icon: Icons.phone_rounded,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Kata Sandi',
                    hint: 'Minimal 8 karakter',
                    icon: Icons.lock_rounded,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Konfirmasi Kata Sandi',
                    hint: 'Ulangi kata sandi',
                    icon: Icons.lock_rounded,
                    controller: _confirm,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.confirm(v, _password.text),
                  ),
                  const SizedBox(height: 14),
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
