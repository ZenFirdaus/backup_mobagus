import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/format.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/modern_time_picker.dart';

class _CurrencyInfo {
  final String label;
  final String code;
  final String symbol;
  final double rate;
  final IconData icon;

  const _CurrencyInfo({
    required this.label,
    required this.code,
    required this.symbol,
    required this.rate,
    required this.icon,
  });
}

class _TzInfo {
  final String label;
  final int utcOffset;
  const _TzInfo(this.label, this.utcOffset);
}

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

  static const List<_CurrencyInfo> _currencies = [
    _CurrencyInfo(label: 'USD - Dollar Amerika Serikat', code: 'USD', symbol: '\$', rate: 18107, icon: Icons.attach_money_rounded),
    _CurrencyInfo(label: 'MYR - Ringgit Malaysia', code: 'MYR', symbol: 'RM', rate: 4432, icon: Icons.currency_exchange_rounded),
    _CurrencyInfo(label: 'SGD - Dollar Singapura', code: 'SGD', symbol: 'S\$', rate: 14162, icon: Icons.monetization_on_outlined),
    _CurrencyInfo(label: 'JPY - Yen Jepang', code: 'JPY', symbol: '¥', rate: 115, icon: Icons.currency_yen_rounded),
    _CurrencyInfo(label: 'CNY - Yuan China', code: 'CNY', symbol: 'CN¥', rate: 2711, icon: Icons.currency_yuan_rounded),
  ];

  static const List<_TzInfo> _zones = [
    _TzInfo('WIB', 7),
    _TzInfo('WITA', 8),
    _TzInfo('WIT', 9),
    _TzInfo('London', 0),
  ];

  TimeOfDay _customTime = const TimeOfDay(hour: 12, minute: 0);
  late _TzInfo _selectedSourceTz;

  @override
  void initState() {
    super.initState();
    _selectedSourceTz = _zones[0];
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

  String _formatTime(DateTime utc, int offsetHours) {
    final local = utc.add(Duration(hours: offsetHours));
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
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
            child: _buildTabBar(),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildCurrencyTab(),
            _buildTimezoneTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
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
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Konverter Kurs'),
          Tab(text: 'Zona Waktu'),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text('Masukkan Jumlah (IDR)', style: AppText.display(16)),
        const SizedBox(height: 10),
        _buildIdrInputField(),
        const SizedBox(height: 16),
        ..._currencies.map((c) {
          final converted = _idr / c.rate;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCurrencyCard(
              label: c.label,
              icon: c.icon,
              value: '${c.symbol} ${converted.toStringAsFixed(2)}',
              rate: '1 ${c.code} = ${formatRp(c.rate)}',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIdrInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tint(AppColors.greenDark, 0.15)),
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
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
              onChanged: (v) => setState(() => _idr = double.tryParse(v) ?? 0),
            ),
          ),
          if (_idrController.text.isNotEmpty)
            IconButton(
              tooltip: 'Hapus input',
              icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () {
                _idrController.clear();
                setState(() => _idr = 0);
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          IconButton(
            tooltip: 'Selesai / Sembunyikan Keyboard',
            icon: const Icon(Icons.keyboard_hide_rounded, color: AppColors.greenDark, size: 20),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard({
    required String label,
    required IconData icon,
    required String value,
    required String rate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
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
                Text(value, style: AppText.display(18)),
              ],
            ),
          ),
          Text(rate, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTimezoneTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text('Waktu Saat Ini', style: AppText.display(16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildClockCard(_zones[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildClockCard(_zones[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildClockCard(_zones[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildClockCard(_zones[3])),
          ],
        ),
        const SizedBox(height: 24),
        Text('Konversi Waktu Kustom', style: AppText.display(16)),
        const SizedBox(height: 4),
        const Text(
          'Atur jam sendiri untuk dikonversi secara presisi ke 4 zona waktu.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        _buildCustomTimeInputCard(),
        const SizedBox(height: 20),
        Text('Hasil Konversi (4 Zona)', style: AppText.display(15)),
        const SizedBox(height: 10),
        ..._zones.map(_buildCustomConvertedCard),
      ],
    );
  }

  Widget _buildClockCard(_TzInfo tz) {
    final time = _formatTime(_now, tz.utcOffset);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
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
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                tz.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(time, style: AppText.display(20)),
          ),
          const SizedBox(height: 2),
          Text(
            'UTC${tz.utcOffset >= 0 ? '+' : ''}${tz.utcOffset}',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTimeInputCard() {
    final hourStr = _customTime.hour.toString().padLeft(2, '0');
    final minuteStr = _customTime.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jam Input Pengguna',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  final nowLocal = _now.add(Duration(hours: _selectedSourceTz.utcOffset));
                  setState(() {
                    _customTime = TimeOfDay(hour: nowLocal.hour, minute: nowLocal.minute);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.greenDark, 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 12, color: AppColors.greenDark),
                      SizedBox(width: 4),
                      Text(
                        'Waktu Saat Ini',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showModernTimePicker(
                context,
                initialTime: _customTime,
                title: 'Atur Jam Input',
              );
              if (picked != null) {
                setState(() => _customTime = picked);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.yellow, 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 24, color: AppColors.greenDark),
                      const SizedBox(width: 12),
                      Text(
                        '$hourStr:$minuteStr',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.greenDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _selectedSourceTz.label,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Pilih Jam',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zona Waktu Asal (Input):',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _zones.map((tz) {
                final isSelected = tz.label == _selectedSourceTz.label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedSourceTz = tz),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.greenDark
                            : AppColors.tint(AppColors.greenDark, 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.greenDark : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${tz.label} (UTC${tz.utcOffset >= 0 ? '+' : ''}${tz.utcOffset})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomConvertedCard(_TzInfo tz) {
    final result = _calculateConvertedTime(tz.utcOffset);
    final isSource = tz.label == _selectedSourceTz.label;
    final hour = result['hour'] as int;
    final formattedTime = result['formatted'] as String;
    final dayDiff = result['dayDiff'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSource
            ? Border.all(color: AppColors.greenDark.withValues(alpha: 0.35), width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSource
                  ? AppColors.tint(AppColors.greenDark, 0.12)
                  : AppColors.tint(AppColors.yellow, 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTimeIcon(hour),
              size: 22,
              color: isSource ? AppColors.greenDark : AppColors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tz.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (isSource) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.tint(AppColors.greenDark, 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Zona Asal',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'UTC${tz.utcOffset >= 0 ? '+' : ''}${tz.utcOffset} · Waktu ${_getTimePeriod(hour)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.greenDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _dayDiffColor(dayDiff).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _dayDiffLabel(dayDiff),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: _dayDiffColor(dayDiff),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateConvertedTime(int targetUtcOffset) {
    final diffHours = targetUtcOffset - _selectedSourceTz.utcOffset;
    final totalMinutes = _customTime.hour * 60 + _customTime.minute + (diffHours * 60);

    final dayDiff = (totalMinutes / 1440).floor();
    final normalizedMinutes = ((totalMinutes % 1440) + 1440) % 1440;
    final hour = normalizedMinutes ~/ 60;
    final minute = normalizedMinutes % 60;

    return {
      'hour': hour,
      'minute': minute,
      'formatted': '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      'dayDiff': dayDiff,
    };
  }

  String _dayDiffLabel(int dayDiff) {
    if (dayDiff > 0) return '+$dayDiff Hari (Besok)';
    if (dayDiff < 0) return '$dayDiff Hari (Kemarin)';
    return 'Hari yang sama';
  }

  Color _dayDiffColor(int dayDiff) {
    if (dayDiff > 0) return const Color(0xFF2563EB);
    if (dayDiff < 0) return const Color(0xFFD97706);
    return AppColors.greenDark;
  }

  String _getTimePeriod(int hour) {
    if (hour >= 4 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  IconData _getTimeIcon(int hour) {
    if (hour >= 5 && hour < 11) return Icons.wb_sunny_rounded;
    if (hour >= 11 && hour < 16) return Icons.sunny;
    if (hour >= 16 && hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }
}
