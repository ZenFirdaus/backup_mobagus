import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/buttons.dart';
import 'home.dart';

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

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(name: widget.name, fromRegister: true),
      ),
      (route) => false,
    );
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
    } catch (_) {}
    _code.clear();
    _startTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode baru telah dikirim ke ${widget.email}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.greenDark,
        ),
      );
    }
  }

  Future<void> _verify() async {
    final token = _code.text.trim();
    if (token.length != _codeLength) return;
    setState(() => _loading = true);

    bool verified = false;
    final typesToTry = [
      OtpType.signup,
      OtpType.email,
      OtpType.magiclink,
    ];

    for (final type in typesToTry) {
      try {
        final res = await Supabase.instance.client.auth.verifyOTP(
          email: widget.email,
          token: token,
          type: type,
        );
        if (res.user != null || res.session != null) {
          verified = true;
          break;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi email berhasil! Selamat datang.'),
          backgroundColor: AppColors.greenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _goHome();
    } else {
      _showVerificationDialog();
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kode Belum Terkonfirmasi'),
        content: const Text(
          'Jika Anda mengklik tautan verifikasi di email, akun Anda mungkin sudah terverifikasi otomatis. Ingin langsung masuk sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Coba Lagi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _goHome();
            },
            child: const Text('Lanjut ke Beranda'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _code.text.length == _codeLength;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.orange, 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 32,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Verifikasi Email', style: AppText.display(24)),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan 6 digit kode keamanan yang dikirim ke:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: Stack(
                    children: [
                      ListenableBuilder(
                        listenable: _code,
                        builder: (context, _) {
                          final text = _code.text;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_codeLength, (i) {
                              final char = i < text.length ? text[i] : '';
                              return _OtpBox(
                                char: char,
                                active:
                                    i == text.length.clamp(0, _codeLength - 1),
                              );
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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
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
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Verifikasi',
                  loading: _loading,
                  onPressed: ready ? _verify : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tidak menerima kode? ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: _seconds == 0 ? _resend : null,
                      child: Text(
                        _seconds == 0
                            ? 'Kirim Ulang'
                            : 'Kirim Ulang ($_timeLabel)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _seconds == 0
                              ? AppColors.red
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _goHome,
                  child: const Text(
                    'Lewati Verifikasi untuk Sekarang',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
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
    return Container(
      width: 44,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (active || filled) ? AppColors.orange : AppColors.line,
          width: active ? 2 : 1.2,
        ),
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
