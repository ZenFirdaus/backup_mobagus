import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:flutter_application_1/theme/app_colors.dart';

/// Menampilkan pemilih waktu modern tanpa dial jam lingkaran (anti AI-slop).
/// Menggunakan Cupertino time wheel dengan preset cepat & preview digital.
Future<TimeOfDay?> showModernTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'Atur Waktu Pengingat',
  List<TimeOfDay>? presets,
}) async {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ModernTimePickerSheet(
      initialTime: initialTime,
      title: title,
      presets: presets,
    ),
  );
}

class _ModernTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;
  final List<TimeOfDay>? presets;

  const _ModernTimePickerSheet({
    required this.initialTime,
    required this.title,
    this.presets,
  });

  @override
  State<_ModernTimePickerSheet> createState() => _ModernTimePickerSheetState();
}

class _ModernTimePickerSheetState extends State<_ModernTimePickerSheet> {
  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  final List<Map<String, dynamic>> _defaultPresets = const [
    {'label': 'Sarapan', 'hour': 7, 'minute': 0},
    {'label': 'Makan Siang', 'hour': 12, 'minute': 30},
    {'label': 'Makan Malam', 'hour': 19, 'minute': 0},
    {'label': 'Camilan', 'hour': 21, 'minute': 15},
  ];

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _applyPreset(int h, int m) {
    setState(() {
      _hour = h;
      _minute = m;
    });
    if (_hourController.hasClients) {
      _hourController.jumpToItem(h);
    }
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(m);
    }
  }

  String _format2Digits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E4E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Digital Time Preview Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeUnitBox(_format2Digits(_hour), 'JAM'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
                  _timeUnitBox(_format2Digits(_minute), 'MENIT'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset Quick Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _defaultPresets.map((p) {
                final isSelected = p['hour'] == _hour && p['minute'] == _minute;
                final label = p['label'] as String;
                final h = p['hour'] as int;
                final m = p['minute'] as int;
                final timeStr = '${_format2Digits(h)}:${_format2Digits(m)}';

                return GestureDetector(
                  onTap: () => _applyPreset(h, m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.greenDark : const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Cupertino Wheel Scroll Pickers
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Wheel (00 - 23)
                  SizedBox(
                    width: 72,
                    child: CupertinoPicker.builder(
                      scrollController: _hourController,
                      itemExtent: 38,
                      useMagnifier: true,
                      magnification: 1.15,
                      onSelectedItemChanged: (index) {
                        setState(() => _hour = index);
                      },
                      childCount: 24,
                      itemBuilder: (ctx, index) {
                        final active = index == _hour;
                        return Center(
                          child: Text(
                            _format2Digits(index),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                              color: active ? AppColors.greenDark : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),

                  // Minute Wheel (00 - 59)
                  SizedBox(
                    width: 72,
                    child: CupertinoPicker.builder(
                      scrollController: _minuteController,
                      itemExtent: 38,
                      useMagnifier: true,
                      magnification: 1.15,
                      onSelectedItemChanged: (index) {
                        setState(() => _minute = index);
                      },
                      childCount: 60,
                      itemBuilder: (ctx, index) {
                        final active = index == _minute;
                        return Center(
                          child: Text(
                            _format2Digits(index),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                              color: active ? AppColors.greenDark : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F5F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: _hour, minute: _minute),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Simpan Waktu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeUnitBox(String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.greenDark,
            fontFamily: 'Gotham',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
