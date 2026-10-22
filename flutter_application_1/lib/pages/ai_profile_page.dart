import 'package:flutter/material.dart';

import '../models/user_ai_profile.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/ai_recommendation_service.dart';
import '../services/location_service.dart';

/// Halaman untuk melengkapi data diri, gaya hidup, dan preferensi kuliner pengguna.
/// Data ini diproses oleh AI FOODIE untuk menghasilkan rekomendasi tempat makan personal.
class AiProfilePage extends StatefulWidget {
  const AiProfilePage({super.key});

  @override
  State<AiProfilePage> createState() => _AiProfilePageState();
}

class _AiProfilePageState extends State<AiProfilePage> {
  final _svc = AiRecommendationService.instance;
  final _formKey = GlobalKey<FormState>();

  String? _gender;
  final _ageCtrl = TextEditingController();
  String? _occupation;
  String? _monthlyIncome;
  String? _housingType;
  final _addressCtrl = TextEditingController();
  final List<String> _favoriteTastes = [];
  final List<String> _preferredPlaces = [];
  String? _mealBudget;
  String? _preferredVibe;
  String _dietaryPreference = 'Semua Makanan';

  bool _loading = true;
  bool _saving = false;
  bool _fetchingLocation = false;

  static const _occupations = [
    'Mahasiswa / Pelajar',
    'Karyawan Swasta',
    'PNS / ASN / BUMN',
    'Wirausaha / Bisnis',
    'Freelancer / Kreatif',
    'Ibu Rumah Tangga',
    'Lainnya',
  ];

  static const _incomes = [
    '< Rp 2.000.000 (Anak Kos / Hemat)',
    'Rp 2.000.000 - Rp 5.000.000',
    'Rp 5.000.000 - Rp 10.000.000',
    '> Rp 10.000.000',
  ];

  static const _housingTypes = [
    'Kos',
    'Kontrakan',
    'Rumah Sendiri',
    'Rumah Orang Tua',
    'Apartemen',
  ];

  // Pilihan kategori tempat makan sesuai yang ada di tab Explore
  static const _placeTypeOptions = [
    'Rumah Makan / Restoran',
    'Cafe',
    'Fast Food',
    'Food Court',
    'Warung Tradisional / Angkringan',
    'Gudeg',
    'Soto',
    'Bakmi Jawa',
  ];

  static const _tasteOptions = [
    'Pedas',
    'Manis',
    'Gurih / Asin',
    'Asam Segar',
    'Rempah Nusantara',
  ];

  static const _budgetOptions = [
    'Hemat (< Rp 20.000)',
    'Menengah (Rp 20.000 - Rp 45.000)',
    'Santai (Rp 45.000 - Rp 80.000)',
    'Eksklusif (> Rp 80.000)',
  ];

  static const _vibeOptions = [
    'WFC / Nugas (Wi-Fi & Colokan)',
    'Nongkrong Santai Bareng Teman',
    'Cepat Saji / Praktis Bungkus',
    'Warung Tradisional / Legendaris',
    'Kumpul Keluarga / Rombongan',
  ];

  static const _dietOptions = [
    'Semua Makanan',
    'Halal',
    'Bebas Santan',
    'Vegetarian',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final p = await _svc.getProfile();
    if (p != null) {
      _gender = p.gender;
      if (p.age != null && p.age! > 0) _ageCtrl.text = p.age.toString();
      _occupation = p.occupation;
      _monthlyIncome = p.monthlyIncome;
      _housingType = p.housingType;
      _addressCtrl.text = p.address ?? '';
      _favoriteTastes.clear();
      _favoriteTastes.addAll(p.favoriteTastes);
      _preferredPlaces.clear();
      _preferredPlaces.addAll(p.preferredPlaces);
      _mealBudget = p.mealBudget;
      _preferredVibe = p.preferredVibe;
      _dietaryPreference = p.dietaryPreference ?? 'Semua Makanan';
    }
    if (mounted) setState(() => _loading = false);
  }

  int _calculateCurrentProgress() {
    int total = 9;
    int filled = 0;
    if (_gender != null && _gender!.isNotEmpty) filled++;
    if (int.tryParse(_ageCtrl.text.trim()) != null) filled++;
    if (_occupation != null && _occupation!.isNotEmpty) filled++;
    if (_monthlyIncome != null && _monthlyIncome!.isNotEmpty) filled++;
    if (_housingType != null && _housingType!.isNotEmpty) filled++;
    if (_addressCtrl.text.trim().isNotEmpty) filled++;
    if (_favoriteTastes.isNotEmpty) filled++;
    if (_preferredPlaces.isNotEmpty) filled++;
    if (_mealBudget != null && _mealBudget!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  /// Mengambil lokasi GPS saat ini dan otomatis mengisi kolom alamat
  Future<void> _useCurrentLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _fetchingLocation = true);

    try {
      final success = await LocationService.instance.fetchGpsLocation();
      if (!mounted) return;

      if (success) {
        final loc = LocationService.instance.currentLocation.value;
        if (loc != null && loc.address.isNotEmpty) {
          _addressCtrl.text = loc.address;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alamat terdeteksi: ${loc.address}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.greenDark,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        final msg = LocationService.instance.statusMessage.value ??
            'Gagal mendeteksi lokasi GPS. Anda dapat mengetik alamat secara manual.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kendala saat membaca GPS: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _save() async {
    // Tutup keyboard terlebih dahulu untuk menghindari freeze input di iOS
    FocusManager.instance.primaryFocus?.unfocus();

    final ageVal = int.tryParse(_ageCtrl.text.trim());
    if (_gender == null ||
        _occupation == null ||
        _monthlyIncome == null ||
        _housingType == null ||
        _favoriteTastes.isEmpty ||
        _mealBudget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi bagian yang penting agar AI bekerja maksimal!'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = UserAiProfile(
        gender: _gender,
        age: ageVal,
        occupation: _occupation,
        monthlyIncome: _monthlyIncome,
        housingType: _housingType,
        address: _addressCtrl.text.trim(),
        favoriteTastes: List.from(_favoriteTastes),
        preferredPlaces: List.from(_preferredPlaces),
        mealBudget: _mealBudget,
        preferredVibe: _preferredVibe,
        dietaryPreference: _dietaryPreference,
      );

      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      await _svc.saveProfile(profile);

      if (!mounted) return;

      // Pop halaman terlebih dahulu agar transisi UI mulus tanpa freeze
      nav.pop(true);

      // Tampilkan notifikasi konfirmasi di layar utama
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Persona & preferensi berhasil diterapkan! Rekomendasi telah diperbarui ✨',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.greenDark,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving AI profile: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateCurrentProgress();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Persona & Preferensi AI', style: AppText.display(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, color: AppColors.orange, size: 18),
            label: Text(
              _saving ? 'Menerapkan...' : 'Terapkan',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                children: [
                  _headerBanner(progress),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '1. Profil Personal & Finansial',
                    subtitle:
                        'Membantu AI menyesuaikan kapasitas porsi & level harga restoran',
                    icon: Icons.person_rounded,
                    children: [
                      _label('Jenis Kelamin *'),
                      const SizedBox(height: 8),
                      _genderSelector(),
                      const SizedBox(height: 16),
                      _label('Umur (Tahun) *'),
                      const SizedBox(height: 8),
                      _ageField(),
                      const SizedBox(height: 16),
                      _label('Pekerjaan / Aktivitas *'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih pekerjaan Anda',
                        value: _occupation,
                        items: _occupations,
                        onChanged: (v) => setState(() => _occupation = v),
                      ),
                      const SizedBox(height: 16),
                      _label('Estimasi Pendapatan Bulanan *'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih rentang pendapatan',
                        value: _monthlyIncome,
                        items: _incomes,
                        onChanged: (v) => setState(() => _monthlyIncome = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: '2. Tempat Tinggal & Domisili',
                    subtitle:
                        'AI menyelaraskan pilihan kuliner dengan mobilitas harian Anda',
                    icon: Icons.home_rounded,
                    children: [
                      _label('Tipe Tempat Tinggal *'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih tipe tempat tinggal',
                        value: _housingType,
                        items: _housingTypes,
                        onChanged: (v) => setState(() => _housingType = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _label('Alamat / Area Domisili'),
                          ),
                          InkWell(
                            onTap: _fetchingLocation ? null : _useCurrentLocation,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.tint(AppColors.orange, 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_fetchingLocation)
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.orange,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.my_location_rounded,
                                      size: 14,
                                      color: AppColors.orange,
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _fetchingLocation
                                        ? 'Mencari...'
                                        : 'Gunakan Alamat Saat Ini',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI akan merekomendasikan kuliner terdekat dari alamat ini. Anda bisa tekan tombol di atas atau ketik manual.',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      _addressField(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: '3. Selera Rasa & Preferensi Kuliner',
                    subtitle:
                        'AI mencocokkan profil rempah dan rasa favorit lidah Anda',
                    icon: Icons.restaurant_menu_rounded,
                    children: [
                      _label('Rasa Kesukaan * (Bisa pilih lebih dari satu)'),
                      const SizedBox(height: 10),
                      _tasteChips(),
                      const SizedBox(height: 20),
                      _label('Pilihan Tipe Tempat Favorit * (Sesuai Explore)'),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih jenis tempat kuliner yang paling Anda sukai saat berburu makanan',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      _placeTypeChips(),
                      const SizedBox(height: 20),
                      _label('Target Budget Sekali Makan *'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih budget per porsi',
                        value: _mealBudget,
                        items: _budgetOptions,
                        onChanged: (v) => setState(() => _mealBudget = v),
                      ),
                      const SizedBox(height: 16),
                      _label('Suasana Tempat Makan Favorit'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih suasana favorit',
                        value: _preferredVibe,
                        items: _vibeOptions,
                        onChanged: (v) => setState(() => _preferredVibe = v),
                      ),
                      const SizedBox(height: 16),
                      _label('Preferensi Diet Khusus'),
                      const SizedBox(height: 8),
                      _dropdown(
                        hint: 'Pilih preferensi diet',
                        value: _dietaryPreference,
                        items: _dietOptions,
                        onChanged: (v) => setState(() => _dietaryPreference = v ?? 'Semua Makanan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _saveButton(),
                ],
              ),
            ),
    );
  }

  // ---------- Widgets Pembantu ----------

  Widget _headerBanner(int progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.charcoal, Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOODIE AI Smart Match Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kelengkapan Data: $progress%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Semakin lengkap data yang Anda isi, semakin presisi AI merekomendasikan kuliner yang cocok dengan selera, kantong, dan gaya hidup Anda.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.display(16)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.line),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }

  Widget _genderSelector() {
    return Row(
      children: [
        Expanded(
          child: _genderButton(
            label: 'Laki-laki',
            icon: Icons.male_rounded,
            isSelected: _gender == 'Laki-laki',
            onTap: () => setState(() => _gender = 'Laki-laki'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _genderButton(
            label: 'Perempuan',
            icon: Icons.female_rounded,
            isSelected: _gender == 'Perempuan',
            onTap: () => setState(() => _gender = 'Perempuan'),
          ),
        ),
      ],
    );
  }

  Widget _genderButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tint(AppColors.orange, 0.12)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.orange : AppColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.orange : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.orange : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageField() {
    return TextFormField(
      controller: _ageCtrl,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Contoh: 21',
        prefixIcon: const Icon(Icons.cake_rounded, size: 20, color: AppColors.textMuted),
        suffixIcon: IconButton(
          tooltip: 'Selesai / Sembunyikan Keyboard',
          icon: const Icon(
            Icons.keyboard_hide_rounded,
            size: 20,
            color: AppColors.orange,
          ),
          onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _addressField() {
    return TextFormField(
      controller: _addressCtrl,
      maxLines: 2,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Ketik alamat manual atau gunakan tombol di atas...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Icon(Icons.location_on_rounded, size: 20, color: AppColors.textMuted),
        ),
        suffixIcon: _addressCtrl.text.isNotEmpty
            ? IconButton(
                tooltip: 'Hapus Alamat',
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                onPressed: () {
                  _addressCtrl.clear();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _tasteChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tasteOptions.map((taste) {
        final isSelected = _favoriteTastes.contains(taste);
        return FilterChip(
          label: Text(taste),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _favoriteTastes.add(taste);
              } else {
                _favoriteTastes.remove(taste);
              }
            });
          },
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          backgroundColor: const Color(0xFFF4F4F6),
          selectedColor: AppColors.orange,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.orange : AppColors.line,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _placeTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _placeTypeOptions.map((place) {
        final isSelected = _preferredPlaces.contains(place);
        return FilterChip(
          label: Text(place),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredPlaces.add(place);
              } else {
                _preferredPlaces.remove(place);
              }
            });
          },
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.charcoal,
          ),
          backgroundColor: const Color(0xFFF4F4F6),
          selectedColor: AppColors.orange,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.orange : AppColors.line,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Terapkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
