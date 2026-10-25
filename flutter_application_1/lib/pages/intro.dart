import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/face_biometric_service.dart';
import '../services/supabase_service.dart';
import '../widgets/foodie_logo.dart';
import 'home.dart';
import 'onboarding.dart';

/// Splash screen FOODIE — tampil animasi, cek sesi Supabase aktif.
/// Jika ada sesi login aktif, otomatis langsung masuk ke HomePage.
/// Jika belum login atau sesi habis, fade ke OnboardingPage.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Tampilkan animasi splash screen minimal 2 detik
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      // Jika ada session dan token belum expired
      if (session != null && user != null && !session.isExpired) {
        await SupabaseService.instance.initStorage();
        final profile = await SupabaseService.instance.getProfile();

        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('foodie_current_display_name') ??
            prefs.getString('foodie_name_${user.id}') ??
            prefs.getString('foodie_last_user_name');

        final effectiveName = (profile?.displayName != null &&
                profile!.displayName.trim().isNotEmpty)
            ? profile.displayName.trim()
            : (savedName != null && savedName.trim().isNotEmpty)
                ? savedName.trim()
                : (user.userMetadata?['name'] as String?)?.trim().isNotEmpty ==
                        true
                    ? (user.userMetadata!['name'] as String).trim()
                    : (user.email != null && user.email!.isNotEmpty)
                        ? user.email!.split('@').first
                        : 'Kurator Rasa';

        final biometricEnrolled =
            await FaceBiometricService.instance.isFaceEnrolled(
          email: user.email,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => HomePage(
              name: effectiveName,
              biometricOn: biometricEnrolled,
            ),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error pengecekan sesi: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const OnboardingPage(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF751F),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo teks putih baru dari assets
              const FoodieLogoWidget(
                variant: FoodieLogoVariant.textWhite,
                width: 280,
              ),
              const Spacer(flex: 3),
              // Loading indicator tipis di bawah
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
