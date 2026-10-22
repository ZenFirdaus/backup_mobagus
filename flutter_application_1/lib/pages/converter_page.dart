import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _idrController = TextEditingController();
  double _idr = 0;
  Timer? _clock;
  DateTime _now = DateTime.now().toUtc();

  static const double _usdRate = 15923;
  static const double _myrRate = 3614;

  static const List<_Benchmark> _benchmarks = [
    _Benchmark('Gudeg', 45000),
    _Benchmark('Soto', 12000),
    _Benchmark('Kopi Joss', 8000),
  ];

  static const List<_MealPreset> _meals = [
    _MealPreset('Sarapan', 6, 0),
    _MealPreset('Makan Siang', 12, 0),
    _MealPreset('Makan Malam', 19, 0),
    _MealPreset('Supper', 23, 0),
  ];

  static const List<_TzInfo> _zones = [
    _TzInfo('WIB', 7),
    _TzInfo('WITA', 8),
    _TzInfo('WIT', 9),
    _TzInfo('London', 0),
  ];

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now().toUtc()),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _idrController.dispose();
    _clock?.cancel();
    super.dispose();
  }

  String _formatRp(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  String _formatCurrency(double value, String symbol) {
    return '$symbol ${value.toStringAsFixed(2)}';
  }

  String _formatTime(DateTime utc, int offsetHours) {
    final local = utc.add(Duration(hours: offsetHours));
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  String _formatMealTime(int hour, int minute, int offsetFromWib) {
    final totalMinutes = hour * 60 + minute + offsetFromWib * 60;
    final h = ((totalMinutes % 1440) + 1440) % 1440 ~/ 60;
    final m = ((totalMinutes % 1440) + 1440) % 1440 % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text('Konverter', style: AppText.display(20)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: _tabBar(),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _currencyTab(),
            _timezoneTab(),
          ],
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Konverter Kurs'),
          Tab(text: 'Zona Waktu Makan'),
        ],
      ),
    );
  }

  Widget _currencyTab() {
    final usd = _idr / _usdRate;
    final myr = _idr / _myrRate;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text('Masukkan Jumlah (IDR)', style: AppText.display(16)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.tint(AppColors.greenDark, 0.15)),
          ),
          child: Row(
            children: [
              const Text(
                'Rp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _idrController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) {
                    setState(() => _idr = double.tryParse(v) ?? 0);
                  },
                ),
              ),
              if (_idrController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Hapus input',
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _idrController.clear();
                    setState(() => _idr = 0);
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              IconButton(
                tooltip: 'Selesai / Sembunyikan Keyboard',
                icon: const Icon(
                  Icons.keyboard_hide_rounded,
                  color: AppColors.greenDark,
                  size: 20,
                ),
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _conversionResult(
          'USD',
          Icons.attach_money,
          _formatCurrency(usd, '\$'),
          '1 USD = ${_formatRp(_usdRate)}',
        ),
        const SizedBox(height: 10),
        _conversionResult(
          'MYR',
          Icons.currency_exchange,
          _formatCurrency(myr, 'RM'),
          '1 MYR = ${_formatRp(_myrRate)}',
        ),
        const SizedBox(height: 24),
        Text('Patokan Kuliner', style: AppText.display(16)),
        const SizedBox(height: 4),
        const Text(
          'Berapa harga makanan khas dalam mata uang asing?',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        ..._benchmarks.map(_benchmarkCard),
      ],
    );
  }

  Widget _conversionResult(
    String label,
    IconData icon,
    String value,
    String rate,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.yellow, 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.display(18),
                ),
              ],
            ),
          ),
          Text(
            rate,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _benchmarkCard(_Benchmark b) {
    final usd = b.priceIdr / _usdRate;
    final myr = b.priceIdr / _myrRate;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, size: 20,
                color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '~${_formatRp(b.priceIdr)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(usd, '\$'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(myr, 'RM'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timezoneTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text('Waktu Saat Ini', style: AppText.display(16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _zones.map(_clockCard).toList(),
        ),
        const SizedBox(height: 24),
        Text('Jadwal Makan', style: AppText.display(16)),
        const SizedBox(height: 4),
        const Text(
          'Waktu makan standar di WIB dikonversi ke zona lain.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        ..._meals.map(_mealScheduleCard),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Simpan Preferensi Zona Wisatawan',
          icon: Icons.bookmark_added_rounded,
          onPressed: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('foodie_tz_pref', 'WIB_GMT');
            } catch (_) {}
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preferensi zona waktu wisatawan berhasil disimpan.'),
                backgroundColor: AppColors.charcoal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _clockCard(_TzInfo tz) {
    final time = _formatTime(_now, tz.utcOffset);
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tz.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: AppText.display(20),
          ),
          const SizedBox(height: 2),
          Text(
            'UTC${tz.utcOffset >= 0 ? '+' : ''}${tz.utcOffset}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealScheduleCard(_MealPreset meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.orange, 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _mealIcon(meal.name),
                  size: 18,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${meal.hour.toString().padLeft(2, '0')}:'
                      '${meal.minute.toString().padLeft(2, '0')} WIB',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _zones.map((tz) {
              final offsetFromWib = tz.utcOffset - 7;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      tz.label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: offsetFromWib == 0
                            ? AppColors.tint(AppColors.green, 0.15)
                            : AppColors.tint(AppColors.yellow, 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatMealTime(
                            meal.hour, meal.minute, offsetFromWib),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: offsetFromWib == 0
                              ? AppColors.greenDark
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _mealIcon(String name) {
    switch (name) {
      case 'Sarapan':
        return Icons.wb_sunny_rounded;
      case 'Makan Siang':
        return Icons.wb_cloudy_rounded;
      case 'Makan Malam':
        return Icons.nightlight_rounded;
      case 'Supper':
        return Icons.dark_mode_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}

class _Benchmark {
  final String name;
  final double priceIdr;
  const _Benchmark(this.name, this.priceIdr);
}

class _MealPreset {
  final String name;
  final int hour;
  final int minute;
  const _MealPreset(this.name, this.hour, this.minute);
}

class _TzInfo {
  final String label;
  final int utcOffset;
  const _TzInfo(this.label, this.utcOffset);
}
