import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common_widgets.dart';
import 'home.dart';
import 'register.dart';

/// Alur: Onboarding ─► LoginPage ─► HomePage
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

  void _goHome(String name) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage(name: name)),
      (route) => false,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: ganti dengan Supabase signInWithPassword(email, password)
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    _goHome(_email.text.trim().split('@').first);
  }

  Future<void> _loginWithFingerprint() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ScanningDialog(),
    );
    // TODO: ganti dengan local_auth (authenticate)
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pop(); // tutup dialog
    _goHome('Kurator');
  }

  void _toRegister() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(),
                const SizedBox(height: 14),
                _banner(),
                const SizedBox(height: 18),
                Text('Sugeng Rawuh,', style: AppText.display(24)),
                Text(
                  'Kurator Rasa',
                  style: AppText.display(
                    24,
                    italic: true,
                    weight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masuk ke akun FOODIE Anda untuk mengakses 420+ kurasi kuliner legendaris, simpan favorit, dan kumpulkan Foodie Points.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AuthTabs(
                  selected: 0,
                  onChanged: (i) {
                    if (i == 1) _toRegister();
                  },
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Alamat Email',
                  hint: 'nama@email.com',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  showValid: Validators.email(_email.text) == null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Kata Sandi',
                  hint: 'Masukkan kata sandi',
                  icon: Icons.lock_outline,
                  controller: _password,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.required(v, 'Kata sandi'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _remember,
                        activeColor: AppColors.greenDark,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (v) => setState(() => _remember = v ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ingat Saya di Perangkat Ini',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    LinkText(
                      'Lupa Kata Sandi?',
                      size: 10.5,
                      onTap: () => showComingSoon(context, 'Reset kata sandi'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Masuk dengan Supabase',
                  trailingArrow: true,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                DarkButton(
                  title: 'Masuk dengan Sidik Jari',
                  subtitle: 'Tersambung ke Biometrik Lokal',
                  leadingIcon: Icons.fingerprint,
                  trailingIcon: Icons.lock_outline,
                  onPressed: _loginWithFingerprint,
                ),
                const SizedBox(height: 16),
                const OrDivider('ATAU MASUK DENGAN'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        label: 'Google SSO',
                        leading: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red,
                          ),
                        ),
                        onPressed: () => showComingSoon(context, 'Google SSO'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SocialButton(
                        label: 'Passkey ID',
                        leading: const Icon(
                          Icons.key,
                          size: 17,
                          color: AppColors.greenDark,
                        ),
                        onPressed: () => showComingSoon(context, 'Passkey'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Text(
                        'Belum memiliki akun FOODIE?',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      LinkText('Daftar Sekarang', onTap: _toRegister),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: InfoPill(
                    icon: Icons.verified_user,
                    text: 'Supabase Auth • TLS 1.3 End-to-End',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in const [
                      'Kebijakan Privasi',
                      'Syarat Ketentuan',
                      'Bantuan Resto',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _banner() {
    return Stack(
      children: [
        const FoodImage(
          height: 112,
          width: double.infinity,
          icon: Icons.ramen_dining,
          borderRadius: BorderRadius.all(Radius.circular(18)),
          colors: [AppColors.greenDark, AppColors.green],
        ),
        Positioned(
          left: 14,
          bottom: 12,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GASTRONOMI NUSANTARA',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pawon Kuno & Kurasi Rasa',
                style: AppText.display(
                  17,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanningDialog extends StatelessWidget {
  const _ScanningDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 56, color: AppColors.orange),
            SizedBox(height: 12),
            Text(
              'Memindai sidik jari...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14),
            LinearProgressIndicator(
              color: AppColors.orange,
              backgroundColor: AppColors.line,
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }
}
