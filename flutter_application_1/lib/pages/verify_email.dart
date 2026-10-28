import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _VerifyEmailPageState extends State<VerifyEmailPage> with WidgetsBindingObserver {
  // Kode OTP pendaftaran berstandar 8 digit angka
  static const int _codeLength = 8;
  static const int _resendSeconds = 60;
  static const int _maxAttempts = 5;

  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  StreamSubscription<AuthState>? _authSubscription;
  int _seconds = _resendSeconds;
  int _failedAttempts = 0;
  bool _loading = false;
  String? _errorMessage;

  bool get _isBlocked => _failedAttempts >= _maxAttempts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    _listenToAuthChange();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat pengguna kembali ke aplikasi setelah mengklik tautan di email
      _checkLinkConfirmation(showLoading: false);
    }
  }

  void _listenToAuthChange() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null && user.emailConfirmedAt != null) {
        if (!mounted) return;
        _handleSuccess();
      }
    });
  }

  Future<void> _checkLinkConfirmation({bool showLoading = false}) async {
    if (_loading) return;
    if (widget.password == null || widget.password!.isEmpty) return;
    if (showLoading) setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email,
        password: widget.password!,
      );

      if (res.user != null && res.user!.emailConfirmedAt != null) {
        if (!mounted) return;
        if (showLoading) setState(() => _loading = false);
        await _handleSuccess();
        return;
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (showLoading) {
        setState(() => _loading = false);
        final lower = e.message.toLowerCase();
        if (lower.contains('email not confirmed')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tautan email belum diklik atau belum terkonfirmasi di server. Silakan klik tombol di email Anda atau masukkan kode OTP 8-digit.'),
              backgroundColor: AppColors.charcoal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted && showLoading) {
        setState(() => _loading = false);
      }
    }
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

  Future<void> _resend() async {
    if (_seconds > 0 || _loading) return;
    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );

      _code.clear();
      _failedAttempts = 0;
      _startTimer();

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Email verifikasi baru telah dikirimkan ke ${widget.email}. Periksa kotak masuk Gmail Anda.',
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
      if (!mounted) return;
      setState(() => _loading = false);
      String msg = e.message;
      if (msg.toLowerCase().contains('rate limit')) {
        msg = 'Terlalu sering meminta kode. Silakan tunggu hingga hitung mundur selesai.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim ulang email OTP. Periksa koneksi internet Anda.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _onCodeChanged(String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    setState(() {});

    final clean = value.trim();
    if (clean.length == _codeLength && !_isBlocked) {
      _verify();
    }
  }

  Future<void> _verify() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isBlocked) {
      setState(() {
        _errorMessage =
            'Batas 5 kali percobaan OTP tercapai. Silakan kirim ulang kode baru setelah hitung mundur selesai.';
      });
      return;
    }

    final token = _code.text.trim().replaceAll(' ', '');

    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Harap masukkan 8 digit kode OTP dari email Anda.';
      });
      return;
    }

    if (token.length != _codeLength) {
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
      _failedAttempts++;
      final remaining = _maxAttempts - _failedAttempts;

      String displayMsg;
      if (remaining <= 0) {
        displayMsg =
            'Batas 5 kali percobaan OTP tercapai. Harap minta kode OTP baru setelah hitung mundur selesai.';
      } else {
        if (failureMessage != null) {
          final lower = failureMessage.toLowerCase();
          if (lower.contains('expired')) {
            displayMsg = 'Kode OTP telah kedaluwarsa. Silakan ketuk Kirim Ulang.';
          } else if (lower.contains('invalid') ||
              lower.contains('not match') ||
              lower.contains('wrong')) {
            displayMsg = 'Kode OTP salah. Sisa percobaan: $remaining kali.';
          } else if (lower.contains('network') || lower.contains('socket')) {
            displayMsg = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
          } else {
            displayMsg = 'Kode OTP tidak cocok. Sisa percobaan: $remaining kali.';
          }
        } else {
          displayMsg = 'Kode OTP tidak cocok. Sisa percobaan: $remaining kali.';
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
    // 1. Sinkronisasi status dan profil ke tabel database Supabase
    try {
      final curUser = Supabase.instance.client.auth.currentUser;
      if (curUser != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': curUser.id,
          'display_name': widget.name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    // 2. Sesi dibersihkan agar pengguna masuk secara resmi menggunakan email & kata sandi
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
                'Email Anda telah terverifikasi dan akun aktif di database. Silakan masuk menggunakan kata sandi Anda.',
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

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Batalkan Verifikasi?',
          style: AppText.display(18, color: AppColors.charcoal),
        ),
        content: Text(
          'Pendaftaran akun Anda belum selesai. Email belum terverifikasi dan belum dapat digunakan untuk masuk.',
          style: AppText.body(13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tetap di Sini', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Batalkan & Keluar', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final codeText = _code.text.trim();
    final ready = codeText.length == _codeLength && !_isBlocked;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                        onTap: () async {
                          final shouldPop = await _onWillPop();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
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
                    'Masukkan 8 digit kode OTP atau klik tombol pada email yang dikirimkan ke:',
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

                  const SizedBox(height: 28),

                  // Input OTP Box (8 digit responsif dan nyaman)
                  SizedBox(
                    height: 54,
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
                              enabled: !_isBlocked && !_loading,
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
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 15, color: AppColors.red),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tombol Verifikasi Utama (Kode OTP)
                  PrimaryButton(
                    label: _isBlocked ? 'Percobaan Diblokir' : 'Verifikasi Kode OTP',
                    loading: _loading,
                    onPressed: ready ? _verify : null,
                  ),

                  const SizedBox(height: 14),

                  // Tombol Cek Status jika User Mengklik Tautan di Email
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _checkLinkConfirmation(showLoading: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 18, color: AppColors.orange),
                      label: const Text(
                        'Sudah Klik Tombol di Email? Cek Status',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
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
                        onTap: (_seconds == 0 && !_loading) ? _resend : null,
                        child: Text(
                          _seconds == 0
                              ? 'Kirim Ulang Email'
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

                  const SizedBox(height: 24),

                  // Status Batas Percobaan
                  if (_failedAttempts > 0 && !_isBlocked)
                    Text(
                      'Sisa percobaan verifikasi: ${_maxAttempts - _failedAttempts} dari $_maxAttempts kali',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
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

class _OtpBox extends StatelessWidget {
  final String char;
  final bool active;
  final bool hasError;

  const _OtpBox({
    required this.char,
    required this.active,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;
    const width = 36.0;
    const height = 48.0;

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
          fontWeight: FontWeight.w800,
          color: char.isEmpty ? AppColors.line : AppColors.textDark,
        ),
      ),
    );
  }
}
