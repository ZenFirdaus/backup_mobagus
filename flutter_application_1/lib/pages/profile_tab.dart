import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';

/// Tab "Profile": info akun, statistik, dan pengaturan.
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
      // TODO: hapus sesi/token, lalu arahkan ke halaman login.
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name.trim().isEmpty ? 'Foodie' : widget.name.trim();
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Profil', style: AppText.display(22)),
            const SizedBox(height: 16),

            // ---- Kartu akun ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.orange,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
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
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Pemburu kuliner • Yogyakarta',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.tint(AppColors.yellow, 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.yellow,
                  ),
                ],
              ),
            ),

            if (widget.fromRegister) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.yellow, 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.celebration_outlined,
                      size: 18,
                      color: AppColors.red,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Akun berhasil dibuat! Lengkapi profilmu agar '
                        'rekomendasi makin pas.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ---- Statistik ----
            Row(
              children: [
                _stat('12', 'Favorit'),
                const SizedBox(width: 10),
                _stat('8', 'Ulasan'),
                const SizedBox(width: 10),
                _stat('27', 'Dikunjungi'),
              ],
            ),
            const SizedBox(height: 20),

            // ---- Pengaturan ----
            const Text(
              'PENGATURAN',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            _group([
              _switchTile(
                Icons.fingerprint,
                'Login Biometrik',
                _biometric,
                (v) => setState(() => _biometric = v),
              ),
              _switchTile(
                Icons.notifications_none_rounded,
                'Notifikasi',
                _notif,
                (v) => setState(() => _notif = v),
              ),
              _tile(Icons.language, 'Bahasa', trailing: 'Indonesia'),
              _tile(Icons.favorite_border, 'Tempat Favorit'),
            ]),
            const SizedBox(height: 16),
            _group([
              _tile(Icons.help_outline, 'Bantuan'),
              _tile(Icons.info_outline, 'Tentang FOODIE', trailing: 'v1.0.0'),
            ]),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _logout,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.tint(AppColors.red, 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.red),
                    SizedBox(width: 8),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.red,
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

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tint(AppColors.greenDark, 0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: AppText.display(20)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tint(AppColors.greenDark, 0.1)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.tint(AppColors.greenDark, 0.08),
              ),
          ],
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppColors.greenDark),
    );
  }

  Widget _tile(IconData icon, String title, {String? trailing}) {
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
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
      onTap: () {},
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
        activeColor: Colors.white,
        activeTrackColor: AppColors.orange,
      ),
    );
  }
}
