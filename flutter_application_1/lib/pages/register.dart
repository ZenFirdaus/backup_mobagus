import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/validators.dart';
import '../widgets/buttons.dart';
import '../widgets/text_field.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/step_progress.dart';
import 'login.dart';
import 'verify_email.dart';

/// Alur: Onboarding ─► RegisterPage (langkah 1) ─► VerifyEmailPage (langkah 2)
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
  bool _agree = false;
  bool _agreeError = false;
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
    final valid = _formKey.currentState!.validate();
    setState(() => _agreeError = !_agree);
    if (!valid || !_agree) return;

    setState(() => _loading = true);
    // TODO: ganti dengan Supabase signUp(email, password, data: {name, phone})
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VerifyEmailPage(name: _name.text.trim(), email: _email.text.trim()),
      ),
    );
  }

  void _toLogin() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final confirmOk =
        _confirm.text.isNotEmpty &&
        Validators.confirm(_confirm.text, _password.text) == null;

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
                const SizedBox(height: 16),
                // --- Petunjuk alur ---
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Langkah 1 dari 3: Buat Akun',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                    Text(
                      'Berikutnya: Verifikasi Email',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const StepBar(current: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 18, height: 2, color: AppColors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'MATARAMAN GASTRONOMIC PASS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai Petualangan Gastronomi',
                  style: AppText.display(23),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daftarkan diri Anda untuk menjelajahi warisan kuliner autentik Mataram, verifikasi check-in GPS, dan klaim lencana eksklusif.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                AuthTabs(
                  selected: 1,
                  onChanged: (i) {
                    if (i == 0) _toLogin();
                  },
                ),
                const SizedBox(height: 14),
                _perkCard(),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Nama Lengkap (Kurator)',
                  hint: 'Nama lengkap Anda',
                  icon: Icons.person_outline,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Nama lengkap'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Alamat Email',
                  hint: 'nama@email.com',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Nomor WhatsApp / Kontak',
                  trailingLabel: 'OTP Cepat',
                  hint: '0812 3456 7890',
                  icon: Icons.phone_outlined,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  helper: 'Digunakan untuk autentikasi check-in GPS warung kuliner tradisional.',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Kata Sandi',
                  hint: 'Minimal 8 karakter unik',
                  icon: Icons.lock_outline,
                  controller: _password,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _StrengthMeter(password: _password.text),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Konfirmasi Kata Sandi',
                  hint: 'Ulangi kata sandi',
                  icon: Icons.history_toggle_off,
                  controller: _confirm,
                  isPassword: true,
                  showValid: confirmOk,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirm(v, _password.text),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _termsRow(),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Daftar Akun Baru',
                  icon: Icons.auto_awesome,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                const OrDivider('ATAU DAFTAR CEPAT DENGAN'),
                const SizedBox(height: 14),
                SocialButton(
                  label: 'Daftar dengan Google',
                  leading: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.red,
                    ),
                  ),
                  onPressed: () => showComingSoon(context, 'Daftar Google'),
                ),
                const SizedBox(height: 10),
                DarkButton(
                  title: 'Daftar dengan Apple ID / Passkey',
                  leadingIcon: Icons.fingerprint,
                  onPressed: () => showComingSoon(context, 'Daftar Passkey'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Text(
                        'Sudah memiliki akun?',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      LinkText('Masuk di sini', onTap: _toLogin),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'KERATON YOGYAKARTA • SURAKARTA HADININGRAT • JALUR REMPAH MATARAM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: InfoPill(
                    icon: Icons.lock,
                    text: 'Encrypted via Supabase Auth PostgreSQL & TLS 1.3',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _perkCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.tint(AppColors.yellow, 0.9),
            AppColors.tint(AppColors.orange, 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tint(AppColors.orange, 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 19,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'PERK SPESIAL ANGGOTA BARU',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+100 Poin',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.yellow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 11, height: 1.45),
                    children: [
                      TextSpan(text: 'Bonus Selamat Datang, '),
                      TextSpan(
                        text: '+100 Foodie Points',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: ' instan & Akses Peta Kuliner Offline setelah aktivasi akun.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agree,
                activeColor: AppColors.greenDark,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: _agreeError ? AppColors.red : AppColors.textMuted,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (v) => setState(() {
                  _agree = v ?? false;
                  if (_agree) _agreeError = false;
                }),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 10.5, height: 1.5),
                  children: [
                    TextSpan(text: 'Saya menyetujui '),
                    TextSpan(
                      text: 'Syarat & Ketentuan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' FOODIE serta kebijakan kurasi kuliner wilayah ',
                    ),
                    TextSpan(
                      text: 'DIY & Jateng',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_agreeError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 32),
            child: Text(
              'Centang persetujuan untuk melanjutkan',
              style: TextStyle(fontSize: 10.5, color: AppColors.red),
            ),
          ),
      ],
    );
  }
}

/// Indikator kekuatan kata sandi (4 segmen).
class _StrengthMeter extends StatelessWidget {
  final String password;
  const _StrengthMeter({required this.password});

  int get _score {
    if (password.isEmpty) return 0;
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      s++;
    }
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Belum diisi', 'Lemah', 'Menengah', 'Kuat', 'Sangat Kuat'];
    final colors = [
      AppColors.line,
      AppColors.red,
      AppColors.orange,
      AppColors.green,
      AppColors.greenDark,
    ];
    final score = _score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: i < score ? colors[score] : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              'Kekuatan: ${labels[score]}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: score == 0 ? AppColors.textMuted : colors[score],
              ),
            ),
            const Spacer(),
            const Text(
              '8+ Karakter, Huruf Besar & Angka',
              style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
