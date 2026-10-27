import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/buttons.dart';
import '../widgets/foodie_logo.dart';
import 'login.dart';

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
  // Proyek Supabase ini menggunakan 8-digit token verifikasi secara default
  static const int _defaultCodeLength = 8;
  static const int _resendSeconds = 60;

  int _codeLength = _defaultCodeLength;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = _resendSeconds;
  bool _loading = false;
  String? _errorMessage;

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

  Future<void> _openMailApp() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Buka aplikasi Gmail Anda untuk melihat kode verifikasi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan periksa aplikasi Gmail pada perangkat Anda.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _loading) return;
    setState(() {
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      _code.clear();
      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email verifikasi baru telah dikirim ke ${widget.email}. Periksa notifikasi Gmail Anda.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.charcoal,
          ),
        );
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains('rate limit')) {
        msg = 'Terlalu sering meminta kode. Silakan tunggu hingga hitung mundur selesai.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ulang email. Periksa koneksi internet Anda.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _onCodeChanged(String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    final clean = value.trim();

    // Otomatis menyesuaikan jika pengguna menempelkan kode 6 digit atau 8 digit
    if (clean.length == 6 && _codeLength != 6) {
      setState(() => _codeLength = 6);
    } else if (clean.length == 8 && _codeLength != 8) {
      setState(() => _codeLength = 8);
    }

    setState(() {});

    if (clean.length == _codeLength) {
      _verify();
    }
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final token = _code.text.trim().replaceAll(' ', '');

    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Harap masukkan kode OTP verifikasi dari email Anda.';
      });
      return;
    }

    if (token.length != 8 && token.length != 6) {
      setState(() {
        _errorMessage = 'Kode OTP harus berjumlah $_codeLength digit lengkap.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    bool verified = false;
    String? failureMessage;

    // Verifikasi kode OTP registrasi resmi terhadap Supabase Auth
    final typesToTry = [
      OtpType.signup,
      OtpType.email,
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
      } on AuthException catch (e) {
        failureMessage = e.message;
      } catch (e) {
        failureMessage = e.toString();
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (verified) {
      await _handleSuccess();
    } else {
      String displayMsg = 'Kode verifikasi tidak cocok atau telah kedaluwarsa.';
      if (failureMessage != null) {
        final lower = failureMessage.toLowerCase();
        if (lower.contains('expired')) {
          displayMsg = 'Kode OTP telah kedaluwarsa. Silakan ketuk Kirim Ulang.';
        } else if (lower.contains('invalid') || lower.contains('not match') || lower.contains('wrong')) {
          displayMsg = 'Kode OTP salah. Silakan periksa kembali pesan masuk di Gmail Anda.';
        } else if (lower.contains('network') || lower.contains('socket')) {
          displayMsg = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
        }
      }

      setState(() {
        _errorMessage = displayMsg;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(displayMsg)),
            ],
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSuccess() async {
    // Sesi dibersihkan agar pengguna masuk secara resmi menggunakan email & kata sandi
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pendaftaran Berhasil!',
                textAlign: TextAlign.center,
                style: AppText.display(20, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              Text(
                'Akun Anda telah aktif dan terverifikasi. Silakan masuk menggunakan email dan kata sandi yang telah didaftarkan.',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Masuk ke Akun',
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _navigateToLogin();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(initialEmail: widget.email),
      ),
      (route) => false,
    );
  }

  void _toggleCodeLength() {
    setState(() {
      _codeLength = _codeLength == 8 ? 6 : 8;
      _code.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeText = _code.text.trim();
    final ready = codeText.length == _codeLength || codeText.length == 6 || codeText.length == 8;

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
                // Header Navigasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.line, width: 1),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    const FoodieHeaderLogo(),
                  ],
                ),
                const SizedBox(height: 28),

                // Ikon Hero Email
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      size: 38,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Judul & Keterangan
                Text(
                  'Verifikasi Registrasi Akun',
                  textAlign: TextAlign.center,
                  style: AppText.display(24, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan $_codeLength digit kode OTP pendaftaran yang dikirimkan ke:',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),

                // Pill Badge Gmail
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 15,
                        color: AppColors.slateBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Buka Aplikasi Gmail Langsung
                OutlinedButton.icon(
                  onPressed: _openMailApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.outgoing_mail, size: 18, color: AppColors.orange),
                  label: const Text(
                    'Buka Aplikasi Gmail',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // Input OTP Box (8 atau 6 digit responsif)
                SizedBox(
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: _code,
                        builder: (context, _) {
                          final text = _code.text;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_codeLength, (i) {
                              final char = i < text.length ? text[i] : '';
                              final isActive =
                                  i == text.length.clamp(0, _codeLength - 1);
                              return _OtpBox(
                                char: char,
                                active: isActive,
                                isCompact: _codeLength == 8,
                                hasError: _errorMessage != null,
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
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: _onCodeChanged,
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

                // Pesan Error jika ada
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppColors.red),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                // Opsi Ganti Format Digit (8 / 6 digit)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _toggleCodeLength,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      _codeLength == 8
                          ? 'Menerima kode 6 digit?'
                          : 'Kembali ke format 8 digit',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateBlue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Verifikasi Utama
                PrimaryButton(
                  label: 'Verifikasi Pendaftaran',
                  loading: _loading,
                  onPressed: ready ? _verify : null,
                ),

                const SizedBox(height: 20),

                // Kirim Ulang Kode & Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Tidak menerima email? ',
                      style: TextStyle(
                        fontSize: 12.5,
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _seconds == 0
                              ? AppColors.orange
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Tombol Navigasi ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah memiliki akun terverifikasi? ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToLogin,
                      child: const Text(
                        'Masuk Sekarang',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
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
}

class _OtpBox extends StatelessWidget {
  final String char;
  final bool active;
  final bool isCompact;
  final bool hasError;

  const _OtpBox({
    required this.char,
    required this.active,
    this.isCompact = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;
    final width = isCompact ? 36.0 : 46.0;
    final height = isCompact ? 48.0 : 54.0;

    Color borderColor = AppColors.line;
    if (hasError) {
      borderColor = AppColors.red;
    } else if (active) {
      borderColor = AppColors.orange;
    } else if (filled) {
      borderColor = AppColors.charcoal;
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: (active || hasError) ? 1.8 : 1.1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
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
