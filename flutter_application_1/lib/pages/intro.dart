import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../widgets/foodie_logo.dart';
import 'onboarding.dart';

/// Splash screen FOODIE — tampil 3 detik, fade ke Onboarding.
/// Menggunakan logo teks putih di atas background oranye paprika.
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
    Future.delayed(const Duration(seconds: 3), _toOnboarding);
  }

  void _toOnboarding() {
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
      backgroundColor: AppColors.paprika,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo teks putih dari assets
              FoodieLogoWidget(
                variant: FoodieLogoVariant.textWhite,
                width: 350,
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
