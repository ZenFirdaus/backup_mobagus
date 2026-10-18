import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'home.dart';
import 'login.dart';
import 'register.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 14),
              _heroCard(),
              const SizedBox(height: 14),
              _featureRow(),
              const SizedBox(height: 16),
              _registerButton(context),
              const SizedBox(height: 10),
              _loginButton(context),
              const SizedBox(height: 10),
              _guestButton(context),
              const SizedBox(height: 14),
              const Text(
                'Dengan melanjutkan, Anda menyetujui Ketentuan\nLayanan Kurasi FOODIE DIY & Jateng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.restaurant, size: 16, color: AppColors.orange),
      ),
      const SizedBox(width: 8),
      const Text(
        'FOODIE',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'PRO',
          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900),
        ),
      ),
      const Spacer(),
      _progressDots(),
      const SizedBox(width: 14),
      GestureDetector(
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage(name: 'Tamu')),
          (route) => false,
        ),
        child: const Text(
          'Masuk Mode Tamu',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.greenDark,
          ),
        ),
      ),
    ],
  );

  Widget _progressDots() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        _dot(AppColors.tint(AppColors.orange, 0.4), 5),
        const SizedBox(width: 4),
        _dot(AppColors.orange, 16),
        const SizedBox(width: 4),
        _dot(AppColors.tint(AppColors.orange, 0.4), 5),
      ],
    ),
  );

  Widget _dot(Color c, double w) => Container(
    width: w,
    height: 5,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
  );

  Widget _heroCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.tint(AppColors.orange, 0.18),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto + judul
        Stack(
          children: [
            const FoodImage(
              height: 170,
              width: double.infinity,
              icon: Icons.ramen_dining,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              colors: [AppColors.red, AppColors.orange],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.greenDark, 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, size: 12, color: AppColors.orange),
                    SizedBox(width: 5),
                    Text(
                      'GPS Sah <50m',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'KURASI AUTENTIK KERATON',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Rasa Asli yang Tak Pernah Berbohong.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified, size: 18, color: AppColors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Validasi check-in instan via sinyal radar fisik di lokasi warung untuk memastikan ulasan 100% riil dari kurator terdaftar.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  InfoChip(
                    label: 'Offline Ready (Hive DB)',
                    icon: Icons.cloud_off,
                  ),
                  InfoChip(
                    label: 'Tebak Kuliner Mini-Game',
                    icon: Icons.sports_esports,
                  ),
                  InfoChip(
                    label: 'Konverter Valas & Zona Waktu',
                    icon: Icons.currency_exchange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _pointsBox(),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _pointsBox() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.tint(AppColors.yellow, 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.tint(AppColors.orange, 0.4)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sell, size: 18, color: AppColors.textDark),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 11, height: 1.4),
              children: [
                TextSpan(text: 'Dapatkan '),
                TextSpan(
                  text: '+100 Foodie Points',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
                TextSpan(
                  text: ' saat mendaftar akun baru dan buka lencana kurator warisan kuliner Kraton.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _featureRow() => const Row(
    children: [
      Expanded(
        child: _FeatureCard(
          icon: Icons.shield,
          title: '420+ Warung',
          subtitle: 'Legendaris\nTerverifikasi',
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _FeatureCard(
          icon: Icons.star,
          title: 'Koleksi Lencana',
          subtitle: 'Tukar Voucher\nMakan',
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: _FeatureCard(
          icon: Icons.smart_toy,
          title: 'Rekomendasi AI',
          subtitle: 'Shake to\nDecide',
        ),
      ),
    ],
  );

  Widget _registerButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const RegisterPage())),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.textDark,
        elevation: 4,
        shadowColor: AppColors.tint(AppColors.orange, 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Daftar Akun Baru (+100 Poin)  →',
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
    ),
  );

  Widget _loginButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LoginPage())),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Masuk ke Akun Anda',
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _guestButton(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton(
      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage(name: 'Tamu')),
        (route) => false,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textDark,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Jelajahi Sebagai Tamu',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(AppColors.orange, 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.green, 0.2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: AppColors.greenDark),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              height: 1.3,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
