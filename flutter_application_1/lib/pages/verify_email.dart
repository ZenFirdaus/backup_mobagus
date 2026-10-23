import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/buttons.dart';
import 'biometric.dart';

class VerifyEmailPage extends StatefulWidget {
  final String name;
  final String email;
  final String? password;

  const VerifyEmailPage({
    super.key,
    required this.name,
    required this.email,
    this.password,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const int _codeLength = 8;
  static const int _resendSeconds = 60;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  StreamSubscription<AuthState>? _authSubscription;
  int _seconds = _resendSeconds;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _listenToAuthChange();
  }

  void _listenToAuthChange() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null || data.event == AuthChangeEvent.signedIn) {
        if (!mounted) return;
        _goNext();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BiometricPage(
          name: widget.name,
          email: widget.email,
          password: widget.password,
        ),
      ),
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
    FocusManager.instance.primaryFocus?.unfocus();
    final token = _code.text.trim().replaceAll(' ', '');
    if (token.length != _codeLength && token.length != 6) return;
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
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _goNext();
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
          'Jika Anda mengklik tautan verifikasi di email, akun Anda mungkin sudah terverifikasi otomatis. Lanjutkan ke langkah pengaturan keamanan biometrik?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Coba Lagi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textDark,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _goNext();
            },
            child: const Text('Lanjut ke Langkah 3'),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.charcoal,
                    ),
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
                    Icons.mark_email_read_rounded,
                    size: 32,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Verifikasi Email', style: AppText.display(24)),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan kode keamanan yang dikirim ke:',
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
                  onPressed: _goNext,
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
      width: 36,
      height: 48,
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
