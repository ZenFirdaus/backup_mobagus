import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/review.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import 'achievements_page.dart';
import 'converter_page.dart';
import 'detail_page.dart';
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

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  late bool _biometric = widget.biometricOn;
  bool _notif = true;
  Profile? _profile;
  Map<String, int> _stats = {'favorites': 0, 'checkins': 0, 'reviews': 0};
  bool _loading = true;

  // Tab controller untuk RIWAYAT
  late final TabController _histTab = TabController(length: 2, vsync: this);

  // Data history pencarian & ulasan
  List<Map<String, dynamic>> _searchHistory = [];
  List<Review> _myReviews = [];
  bool _histLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
    _loadHistory();
  }

  @override
  void dispose() {
    _histTab.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _biometric =
            prefs.getBool('foodie_biometric_enabled') ?? widget.biometricOn;
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

  Future<void> _loadHistory() async {
    final svc = SupabaseService.instance;
    final results = await Future.wait([
      svc.getSearchHistory(),
      svc.getUserReviews(),
    ]);
    if (!mounted) return;
    setState(() {
      _searchHistory = results[0] as List<Map<String, dynamic>>;
      _myReviews = results[1] as List<Review>;
      _histLoading = false;
    });
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
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Kota Yogyakarta, Sleman, Bantul, Kulon Progo, Gunungkidul',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Provinsi Jawa Tengah',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
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

  // ─── EDIT PROFILE SHEET ───

  void _showEditProfile() {
    final nameCtrl = TextEditingController(
      text: _profile?.displayName ?? widget.name,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Edit Profil', style: AppText.display(20)),
                const SizedBox(height: 20),

                // ── Avatar area ──
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      // Tunjukkan pilihan: URL foto atau hapus foto
                      await _editAvatarDialog(setSheet);
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.orange,
                          backgroundImage: _profile?.avatarUrl != null &&
                                  _profile!.avatarUrl!.isNotEmpty
                              ? NetworkImage(_profile!.avatarUrl!)
                              : null,
                          child: (_profile?.avatarUrl == null ||
                                  _profile!.avatarUrl!.isEmpty)
                              ? Text(
                                  (nameCtrl.text.isNotEmpty
                                          ? nameCtrl.text
                                          : 'F')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.charcoal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Ketuk untuk ubah foto profil',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Nama ──
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  autofocus: false,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Nama kurator Anda',
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.orange, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tombol simpan ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) return;
                      Navigator.pop(ctx);
                      await SupabaseService.instance
                          .upsertProfile(displayName: newName);
                      _load();
                    },
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editAvatarDialog(StateSetter setSheet) async {
    final urlCtrl = TextEditingController(text: _profile?.avatarUrl ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Foto Profil', style: AppText.display(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan URL foto profil Anda (JPG/PNG):',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'https://...',
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Hapus Foto',
                style: TextStyle(color: AppColors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, urlCtrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await SupabaseService.instance.upsertProfile(
        displayName: _profile?.displayName ?? widget.name,
        avatarUrl: result,
      );
      await _load();
      setSheet(() {});
    }
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
        content:
            const Text('Kamu perlu login lagi untuk masuk ke FOODIE.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Keluar', style: TextStyle(color: AppColors.red)),
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
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined,
                color: AppColors.orange, size: 22),
            const SizedBox(width: 8),
            const Text('Saran & Kesan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Berikan penilaian dan saran Anda untuk mata kuliah ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: ratingCtrl,
              builder: (_, val, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => ratingCtrl.value = i + 1,
                    child: Icon(
                      i < val
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: AppColors.orange,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Tulis saran & kesan untuk mata kuliah...',
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
            ),
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
              content: Text('Terima kasih atas masukan Anda! ✨'),
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
                child:
                    CircularProgressIndicator(color: AppColors.orange))
            : RefreshIndicator(
                color: AppColors.orange,
                onRefresh: () async {
                  await _load();
                  await _loadHistory();
                },
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

                    // ── Riwayat Aktivitas ──
                    _sectionLabel('RIWAYAT AKTIVITAS'),
                    const SizedBox(height: 8),
                    _historySection(),
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

  // ─── HISTORY SECTION ───

  Widget _historySection() {
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
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 1)),
            ),
            child: TabBar(
              controller: _histTab,
              labelColor: AppColors.charcoal,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.orange,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Pencarian'),
                Tab(text: 'Ulasan Saya'),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: _histLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.orange))
                : TabBarView(
                    controller: _histTab,
                    children: [
                      _searchHistoryTab(),
                      _reviewsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchHistoryTab() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: AppColors.line),
            SizedBox(height: 8),
            Text(
              'Belum ada riwayat pencarian',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        // header hapus semua
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchHistory.length} pencarian',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              GestureDetector(
                onTap: () async {
                  await SupabaseService.instance.clearSearchHistory();
                  setState(() => _searchHistory = []);
                },
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _searchHistory.length,
            itemBuilder: (_, i) {
              final item = _searchHistory[i];
              final q = item['query'] as String? ?? '';
              return ListTile(
                dense: true,
                leading: const Icon(Icons.history_rounded,
                    size: 18, color: AppColors.textMuted),
                title: Text(
                  q,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                ),
                trailing: GestureDetector(
                  onTap: () async {
                    await SupabaseService.instance.removeSearchItem(q);
                    setState(() =>
                        _searchHistory.removeWhere((e) => e['query'] == q));
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textMuted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reviewsTab() {
    if (_myReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 32, color: AppColors.line),
            SizedBox(height: 8),
            Text(
              'Belum ada ulasan',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            SizedBox(height: 4),
            Text(
              'Kunjungi restoran dan tulis ulasan pertamamu!',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _myReviews.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 52,
        color: AppColors.line.withValues(alpha: 0.5),
      ),
      itemBuilder: (_, i) {
        final rev = _myReviews[i];
        return ListTile(
          dense: true,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_rounded,
                size: 18, color: AppColors.orange),
          ),
          title: Text(
            rev.restaurantName ?? rev.restaurantId,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (j) => Icon(
                    j < rev.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 12,
                    color: AppColors.orange,
                  ),
                ),
              ),
              Text(
                rev.comment,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () async {
            final resto = await SupabaseService.instance
                .getRestaurant(rev.restaurantId);
            if (resto != null && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => DetailPage(restaurant: resto)),
              );
            }
          },
        );
      },
    );
  }

  Widget _accountCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 1),
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
          // Avatar — bisa foto atau inisial
          GestureDetector(
            onTap: _showEditProfile,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.orange,
                  backgroundImage:
                      _profile?.avatarUrl != null &&
                              _profile!.avatarUrl!.isNotEmpty
                          ? NetworkImage(_profile!.avatarUrl!)
                          : null,
                  child: (_profile?.avatarUrl == null ||
                          _profile!.avatarUrl!.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
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
                    GestureDetector(
                      onTap: _showEditProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
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
          Icon(Icons.celebration_outlined,
              size: 20, color: AppColors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akun berhasil dibuat! Lengkapi profilmu agar rekomendasi makin pas.',
              style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textDark),
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
                offset: Offset(0, 2)),
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
                        color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mainkan tantangan kuis kuliner harian',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                offset: Offset(0, 2)),
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
                  color: AppColors.textMuted),
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
              color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
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
        border: Border.all(
            color: AppColors.line.withValues(alpha: 0.8), width: 0.8),
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
            color: AppColors.greenDark),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
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
            color: AppColors.greenDark),
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
                  color: AppColors.red),
            ),
          ],
        ),
      ),
    );
  }
}
