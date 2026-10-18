import 'package:flutter/material.dart';

import 'pages/intro.dart';
import 'props/app_colors.dart';
import 'props/app_text.dart';

/// ALUR APLIKASI FOODIE
///
///  IntroPage ──► OnboardingPage ─┬─► RegisterPage ─► VerifyEmailPage ─► BiometricPage ─► HomePage
///                                │     (langkah 1)     (langkah 2)        (langkah 3)
///                                │
///                                └─► LoginPage ───────────────────────────────────────► HomePage
///
///  - Login & Register bisa saling pindah lewat tab "Masuk Akun / Daftar Akun".
///  - "Nanti Saja" di BiometricPage langsung ke HomePage.
void main() => runApp(const FoodieApp());

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOODIE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.body,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          secondary: AppColors.green,
          error: AppColors.red,
        ),
      ),
      // Di browser/desktop, tampilan dibatasi selebar HP supaya rapi.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFEDE6D2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const IntroPage(),
    );
  }
}
