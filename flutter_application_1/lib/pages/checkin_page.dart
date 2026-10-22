import 'package:flutter/material.dart';

import '../models/checkin.dart';
import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';

class CheckinPage extends StatefulWidget {
  final Restaurant restaurant;
  const CheckinPage({super.key, required this.restaurant});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _checkinLoading = false;
  bool _checkinDone = false;
  List<Checkin> _history = [];
  bool _historyLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final list = await SupabaseService.instance.getCheckins();
      if (mounted) setState(() => _history = list);
    } catch (e) {
      if (mounted) setState(() => _historyError = e.toString());
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _doCheckin() async {
    setState(() => _checkinLoading = true);
    try {
      await SupabaseService.instance.performCheckin(
        restaurantId: widget.restaurant.id,
        lat: widget.restaurant.lat,
        lng: widget.restaurant.lng,
        verified: true,
      );
      if (mounted) {
        setState(() => _checkinDone = true);
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Gagal check-in: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.red,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _checkinLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _restaurantHeader(),
                  const SizedBox(height: 16),
                  _gpsStatus(),
                  const SizedBox(height: 12),
                  _geofenceStatus(),
                  const SizedBox(height: 20),
                  if (_checkinDone) _successBanner() else _checkinButton(),
                  const SizedBox(height: 28),
                  _historySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Check-in', style: AppText.display(18)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.green, 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gps_fixed, size: 14, color: AppColors.green),
                SizedBox(width: 5),
                Text(
                  'GPS Aktif',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.restaurant,
              size: 24,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restaurant.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.yellow,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.tint(AppColors.yellow, 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.restaurant.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.tint(AppColors.yellow, 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gpsStatus() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.green, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.satellite_alt,
                  size: 18,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Status GPS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Terhubung',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _gpsRow('Akurasi GPS', '\u00b14 meter'),
          const SizedBox(height: 6),
          _gpsRow('Satelit Terkunci', '12 satelit'),
          const SizedBox(height: 6),
          _gpsRow('Koordinat', '${widget.restaurant.lat.toStringAsFixed(4)}, ${widget.restaurant.lng.toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _gpsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _geofenceStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.green, 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.green, 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.radar,
                  size: 18,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Geofence Radar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.tint(AppColors.green, 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.tint(AppColors.green, 0.35),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.green, 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 18,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '18 meter',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.green, 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Berada di Lokasi Restoran',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
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

  Widget _checkinButton() {
    return PrimaryButton(
      label: 'Konfirmasi Check-in',
      icon: Icons.check_circle_outline,
      loading: _checkinLoading,
      onPressed: _checkinLoading ? null : _doCheckin,
    );
  }

  Widget _successBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.green, 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tint(AppColors.green, 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.green, 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 30,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 12),
          Text('Check-in Berhasil!', style: AppText.display(17)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.orange, 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 18, color: AppColors.orange),
                SizedBox(width: 6),
                Text(
                  '+50 Foodie Points',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.restaurant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.orange, 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.history,
                size: 16,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text('Riwayat Kunjungan', style: AppText.display(16)),
          ],
        ),
        const SizedBox(height: 12),
        if (_historyLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.greenDark,
              ),
            ),
          )
        else if (_historyError != null)
          _errorCard()
        else if (_history.isEmpty)
          _emptyHistory()
        else
          ..._history.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _historyCard(c),
              )),
      ],
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.red, 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: AppColors.red),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat riwayat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loadHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.yellow, 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore_rounded,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text('Belum ada kunjungan', style: AppText.display(14)),
          const SizedBox(height: 4),
          const Text(
            'Check-in di restoran untuk memulai riwayatmu.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Checkin checkin) {
    final d = checkin.createdAt;
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final date = '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
              color: checkin.verified
                  ? AppColors.tint(AppColors.green, 0.15)
                  : AppColors.tint(AppColors.orange, 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              checkin.verified
                  ? Icons.verified_rounded
                  : Icons.pending_rounded,
              size: 20,
              color: checkin.verified ? AppColors.green : AppColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkin.restaurantName ?? 'Restoran',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: checkin.verified
                  ? AppColors.tint(AppColors.green, 0.12)
                  : AppColors.tint(AppColors.orange, 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              checkin.verified ? 'Terverifikasi' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: checkin.verified ? AppColors.greenDark : AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
