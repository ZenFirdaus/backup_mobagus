import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../widgets/common_widgets.dart';
import '../widgets/foodie_logo.dart';
import 'login.dart';
import 'register.dart';

/// Halaman onboarding: gambar makanan + 2 tombol (Register, Login).
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero image (60% layar) ──
            Expanded(
              flex: 6,
              child: const _HeroSection(),
            ),
            // ── Button section (40% layar) ──
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // // Logo teks oranye dari assets
                    // Center(
                    //   child: FoodieLogoWidget(
                    //     variant: FoodieLogoVariant.textOrange,
                    //     width: 50,
                    //   ),
                    // ),
                    const SizedBox(height: 20),
                    _registerBtn(context),
                    const SizedBox(height: 10),
                    _loginBtn(context),
                    const Spacer(),
                    const Text(
                      'Dengan melanjutkan, Anda menyetujui Ketentuan Layanan FOODIE.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registerBtn(BuildContext context) => SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.paprika,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Daftar Akun Baru',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      );

  Widget _loginBtn(BuildContext context) => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.charcoal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Masuk ke Akun Anda',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      );


}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto makanan full-bleed
        const FoodImage(
          imageUrl:
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=900&q=85',
          width: double.infinity,
          height: double.infinity,
          icon: Icons.restaurant_rounded,
          colors: [AppColors.paprika, AppColors.charcoal],
        ),
        // Gradient overlay atas — tempat logo teks putih
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Logo teks putih di pojok kiri atas gambar
        Positioned(
          top: 16,
          left: 20,
          child: FoodieLogoWidget(
            variant: FoodieLogoVariant.textWhite,
            height: 28,
          ),
        ),
        // Gradient overlay bawah
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.98),
                ],
              ),
            ),
          ),
        ),
        // Caption di atas gambar
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paprika,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'KULINER AUTENTIK MATARAMAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Jelajahi Rasa\nWarisan Nusantara.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'DIY & Jawa Tengah · 400+ Warung Terverifikasi',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
