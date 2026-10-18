import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/buttons.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/step_progress.dart';
import 'biometric.dart';

/// Alur: RegisterPage ─► VerifyEmailPage (langkah 2) ─► BiometricPage (langkah 3)
class VerifyEmailPage extends StatefulWidget {
  final String name;
  final String email;

  const VerifyEmailPage({super.key, required this.name, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 60;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = _resendSeconds;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _resend() {
    if (_seconds > 0) return;
    // TODO: ganti dengan Supabase auth.resend(type: signup, email: ...)
    _code.clear();
    _startTimer();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Kode baru dikirim ke ${widget.email}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.greenDark,
        ),
      );
  }

  Future<void> _verify() async {
    if (_code.text.length != _codeLength) return;
    setState(() => _loading = true);
    // TODO: ganti dengan Supabase verifyOTP(email, token: _code.text)
    // Mode demo: kode 6 digit apa pun diterima.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BiometricPage(name: widget.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _code.text.length == _codeLength;

    return Scaffold(
      body: PageBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            children: [
              // --- Header + petunjuk alur ---
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const StepPill(current: 2),
                ],
              ),
              const SizedBox(height: 12),
              const StepBar(current: 2),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Berikutnya: Keamanan Biometrik',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 22),
              _mailIcon(),
              const SizedBox(height: 16),
              Text(
                'Verifikasi Kurator Rasa',
                style: AppText.display(
                  14,
                  italic: true,
                  weight: FontWeight.w700,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Konfirmasi Email Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kami telah mengirimkan tautan konfirmasi dan kode keamanan 6 digit ke alamat surel kurasi Anda:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              _emailChip(),
              const SizedBox(height: 18),
              _otpCard(),
              const SizedBox(height: 14),
              _openMailTile(),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Verifikasi & Lanjutkan',
                trailingArrow: true,
                loading: _loading,
                onPressed: ready ? _verify : null,
              ),
              const SizedBox(height: 14),
              const InfoPill(
                icon: Icons.verified_user,
                text: 'Dilindungi oleh Supabase Auth SSL 256-bit',
              ),
              const SizedBox(height: 10),
              const Text(
                'Mode demo: masukkan 6 digit angka apa saja.',
                style: TextStyle(
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mailIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.tint(AppColors.orange, 0.3),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            size: 40,
            color: AppColors.greenDark,
          ),
        ),
        Positioned(
          right: -8,
          bottom: -8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.restaurant,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, size: 13, color: AppColors.green),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          LinkText(
            'Ubah',
            size: 11,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _otpCard() {
    final canResend = _seconds == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(AppColors.orange, 0.18),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'KODE KEAMANAN 6 DIGIT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.timer_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 3),
              Text(
                _timeLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Kotak OTP + TextField transparan di atasnya (menerima ketikan).
          SizedBox(
            height: 52,
            child: Stack(
              children: [
                ListenableBuilder(
                  listenable: Listenable.merge([_code, _focus]),
                  builder: (context, _) {
                    final text = _code.text;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_codeLength, (i) {
                        final char = i < text.length ? text[i] : '';
                        final active =
                            _focus.hasFocus &&
                            i == text.length.clamp(0, _codeLength - 1);
                        return _OtpBox(char: char, active: active);
                      }),
                    );
                  },
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _code,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: _codeLength,
                      enableSuggestions: false,
                      autocorrect: false,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tidak menerima surel?',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ),
              GestureDetector(
                onTap: canResend ? _resend : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 13,
                      color: canResend ? AppColors.red : AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      canResend
                          ? 'Kirim Ulang Surel'
                          : 'Kirim ulang ($_timeLabel)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: canResend ? AppColors.red : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openMailTile() {
    return Material(
      color: AppColors.tint(Colors.white, 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showComingSoon(context, 'Buka aplikasi email'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.open_in_new,
                  size: 17,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buka Aplikasi Email',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Akses langsung Gmail atau Mail client Anda',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String char;
  final bool active;

  const _OtpBox({required this.char, required this.active});

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.tint(AppColors.yellow, 0.65)
            : AppColors.tint(AppColors.yellow, 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (active || filled) ? AppColors.orange : AppColors.line,
          width: active ? 2.2 : 1.4,
        ),
      ),
      child: filled
          ? Text(char, style: AppText.display(22, weight: FontWeight.w700))
          : Text(
              '•',
              style: TextStyle(
                fontSize: 18,
                color: active
                    ? AppColors.orange
                    : AppColors.tint(AppColors.textMuted, 0.4),
              ),
            ),
    );
  }
}
