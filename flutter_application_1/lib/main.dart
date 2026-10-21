import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/intro.dart';
import 'props/app_colors.dart';
import 'props/app_text.dart';

import 'services/hive_service.dart';
import 'services/notification_service.dart';

/// ALUR APLIKASI FOODIE
///
///  IntroPage ──► OnboardingPage ─┬─► RegisterPage ─► VerifyEmailPage ─► BiometricPage ─► HomePage
///                                │     (langkah 1)     (langkah 2)        (langkah 3)
///                                │
///                                └─► LoginPage ───────────────────────────────────────► HomePage
///
///  - Login & Register bisa saling pindah lewat tab "Masuk Akun / Daftar Akun".
///  - "Nanti Saja" di BiometricPage langsung ke HomePage.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi basis data lokal Hive NoSQL (terpisah dari Supabase)
  await HiveService.instance.init();

  // Inisialisasi layanan notifikasi lokal sistem
  await NotificationService.instance.init();

  await Supabase.initialize(
    url: 'https://pasbipbzosiifdkqlxtl.supabase.co',
    publishableKey: 'sb_publishable_DWyoa4A5cOH8vISaS375yA_oOvPybT1',
  );
  runApp(const FoodieApp());
}

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
          surface: AppColors.surface,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.line,
          thickness: 1,
          space: 1,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      // Di browser/desktop, tampilan dibatasi selebar HP supaya rapi.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFEBE7DD),
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
