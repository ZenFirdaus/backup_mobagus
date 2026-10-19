import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import 'achievements_page.dart';
import 'converter_page.dart';
import 'favorites_page.dart';
import 'game_page.dart';
import 'intro.dart';

class ProfileTab extends StatefulWidget {
  final String name;
  final bool fromRegister;
  final bool biometricOn;

  const ProfileTab({
    super.key,
    required this.name,
    this.fromRegister = false,
    this.biometricOn = false,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late bool _biometric = widget.biometricOn;
  bool _notif = true;
  Profile? _profile;
  Map<String, int> _stats = {'favorites': 0, 'checkins': 0, 'reviews': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _biometric = prefs.getBool('foodie_biometric_enabled') ?? widget.biometricOn;
        _notif = prefs.getBool('foodie_notifications_enabled') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool val) async {
    setState(() => _biometric = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_biometric_enabled', val);
    } catch (_) {}
  }

  Future<void> _toggleNotif(bool val) async {
    setState(() => _notif = val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_notifications_enabled', val);
    } catch (_) {}
  }

  void _showCoverageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.map_rounded, color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            Text('Cakupan Wilayah', style: AppText.display(18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FOODIE mengkurasi warisan kuliner secara eksklusif pada wilayah:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Daerah Istimewa Yogyakarta (DIY)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Kota Yogyakarta, Sleman, Bantul, Kulon Progo, Gunungkidul',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Provinsi Jawa Tengah',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Surakarta (Solo), Semarang, Magelang, Klaten, dan sekitarnya',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile() {
    final ctrl = TextEditingController(text: _profile?.displayName ?? widget.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ubah Nama Profil', style: AppText.display(18)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            labelText: 'Nama Lengkap Kurator',
            filled: true,
            fillColor: AppColors.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await SupabaseService.instance.upsertProfile(displayName: newName);
                _load();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.getProfile(),
        SupabaseService.instance.getUserStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Profile?;
        _stats = results[1] as Map<String, int>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar akun?'),
        content: const Text('Kamu perlu login lagi untuk masuk ke FOODIE.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const IntroPage()),
        (route) => false,
      );
    }
  }

  Future<void> _showFeedback() async {
    final ratingCtrl = ValueNotifier<int>(5);
    final msgCtrl = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saran & Kesan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Berikan penilaian dan saran Anda untuk mata kuliah ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: ratingCtrl,
              builder: (_, val, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => ratingCtrl.value = i + 1,
                    child: Icon(
                      i < val ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 32,
                      color: AppColors.orange,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tulis saran & kesan...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (sent == true && msgCtrl.text.trim().isNotEmpty) {
      await SupabaseService.instance.submitFeedback(
        rating: ratingCtrl.value,
        message: msgCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Terima kasih atas masukan Anda!'),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
    ratingCtrl.dispose();
    msgCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = Supabase.instance.client.auth.currentUser == null;
    final name = _profile?.displayName.isNotEmpty == true
        ? _profile!.displayName
        : widget.name.trim().isEmpty
            ? (isGuest ? 'Tamu Mataraman' : 'Foodie')
            : widget.name.trim();
    final email = isGuest
        ? 'Mode Tamu (Akses Lengkap)'
        : (Supabase.instance.client.auth.currentUser?.email ?? '');
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange))
            : RefreshIndicator(
                color: AppColors.orange,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Text('Profil', style: AppText.display(22)),
                    const SizedBox(height: 16),
                    _accountCard(name, email),
                    if (widget.fromRegister) ...[
                      const SizedBox(height: 12),
                      _welcomeBanner(),
                    ],
                    const SizedBox(height: 14),
                    _statsRow(),
                    const SizedBox(height: 14),
                    _quizBanner(),
                    const SizedBox(height: 20),
                    _sectionLabel('AKTIVITAS KULINER'),
                    const SizedBox(height: 8),
                    _group([
                      _tile(
                        Icons.favorite_border,
                        'Favorit & Koleksi',
                        trailing: '${_stats['favorites']}',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FavoritesPage()),
                        ),
                      ),
                      _tile(
                        Icons.emoji_events_outlined,
                        'Pencapaian & Poin',
                        trailing: '${_profile?.points ?? 0} Poin',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AchievementsPage()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('UTILITAS WISATAWAN'),
                    const SizedBox(height: 8),
                    _group([
                      _tile(
                        Icons.currency_exchange,
                        'Konverter Kurs & Zona Waktu',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ConverterPage()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('PREFERENSI SISTEM'),
                    const SizedBox(height: 8),
                    _group([
                      _switchTile(
                        Icons.fingerprint,
                        'Login Biometrik',
                        _biometric,
                        _toggleBiometric,
                      ),
                      _switchTile(
                        Icons.notifications_none_rounded,
                        'Notifikasi',
                        _notif,
                        _toggleNotif,
                      ),
                      _tile(Icons.map_outlined, 'Cakupan Wilayah',
                          trailing: 'DIY & Jateng',
                          onTap: _showCoverageDialog),
                      _tile(
                        Icons.rate_review_outlined,
                        'Saran & Kesan Kurator',
                        onTap: _showFeedback,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _logoutButton(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'FOODIE INDONESIA\nMATARAMAN EDITION - v1.0.0\nDaerah Istimewa Yogyakarta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _accountCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.orange,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'F',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                      tooltip: 'Ubah Nama',
                      onPressed: _showEditProfile,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profile != null
                        ? 'Level ${_profile!.curatorLevel}: ${_profile!.levelTitle}'
                        : 'Kurator Yogyakarta',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.celebration_outlined, size: 20, color: AppColors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akun berhasil dibuat! Lengkapi profilmu agar rekomendasi makin pas.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _stat('${_stats['favorites']}', 'Favorit'),
        const SizedBox(width: 10),
        _stat('${_stats['reviews']}', 'Ulasan'),
        const SizedBox(width: 10),
        _stat('${_stats['checkins']}', 'Check-in'),
      ],
    );
  }

  Widget _quizBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GamePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tebak Kuliner Jogja',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mainkan tantangan kuis kuliner harian',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: AppText.display(20)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.line.withValues(alpha: 0.6),
              ),
          ],
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8), width: 0.8),
      ),
      child: Icon(icon, size: 18, color: AppColors.greenDark),
    );
  }

  Widget _tile(IconData icon, String title,
      {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      leading: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.greenDark,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textMuted),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      dense: true,
      leading: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.greenDark,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.orange,
      ),
    );
  }

  Widget _logoutButton() {
    final isGuest = Supabase.instance.client.auth.currentUser == null;
    return GestureDetector(
      onTap: _logout,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tint(AppColors.red, 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
            const SizedBox(width: 8),
            Text(
              isGuest ? 'Keluar Mode Tamu' : 'Keluar Akun',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
