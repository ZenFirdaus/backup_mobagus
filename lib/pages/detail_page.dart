import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../models/food.dart';
import '../models/review.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import '../widgets/common_widgets.dart';
import 'checkin_page.dart';

class DetailPage extends StatefulWidget {
  final Restaurant restaurant;

  const DetailPage({super.key, required this.restaurant});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Restaurant _r;
  bool _isFavorite = false;
  List<Food> _foods = [];
  bool _foodsLoading = true;
  String? _foodsError;
  List<Review> _reviews = [];
  bool _reviewsLoading = true;
  String? _reviewsError;

  @override
  void initState() {
    super.initState();
    _r = widget.restaurant;
    _checkFavorite();
    _loadFoods();
    _loadReviews();
  }

  Future<void> _checkFavorite() async {
    final fav = await SupabaseService.instance.isFavorite(_r.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    await SupabaseService.instance.toggleFavorite(_r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? 'Tersimpan ke favorit'
              : 'Dihapus dari favorit',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _loadFoods() async {
    setState(() {
      _foodsLoading = true;
      _foodsError = null;
    });
    try {
      final list = await SupabaseService.instance.getFoods(_r.id);
      if (mounted) setState(() => _foods = list);
    } catch (e) {
      if (mounted) setState(() => _foodsError = e.toString());
    } finally {
      if (mounted) setState(() => _foodsLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final list = await SupabaseService.instance.getReviews(_r.id);
      if (mounted) setState(() => _reviews = list);
    } catch (e) {
      if (mounted) setState(() => _reviewsError = e.toString());
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  void _showAddReviewDialog() {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tulis Ulasan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = i + 1),
                    child: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: AppColors.orange,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Bagikan pengalaman rasa Anda...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (commentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await SupabaseService.instance.addReview(
                  restaurantId: _r.id,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                );
                _loadReviews();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ulasan berhasil ditambahkan! (+20 Poin)'),
                      backgroundColor: AppColors.greenDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDirectionsDialog() async {
    double? userLat;
    double? userLng;
    try {
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
      userLat = pos.latitude;
      userLng = pos.longitude;
    } catch (_) {}

    final fromLat = userLat ?? -7.7956;
    final fromLng = userLng ?? 110.3695;
    final distKm = _haversineDist(fromLat, fromLng, _r.lat, _r.lng);
    final estMins = math.max(3, (distKm * 3.5).round());
    final isFromGPS = userLat != null;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.navigation_rounded,
                    color: AppColors.greenDark, size: 24),
                const SizedBox(width: 10),
                Text('Petunjuk Arah', style: AppText.display(18)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _r.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _r.address,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.yellow, 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      color: AppColors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFromGPS
                              ? 'Estimasi dari Posisi Anda Saat Ini'
                              : 'Estimasi dari Titik Nol KM Jogja (GPS Belum Aktif)',
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${distKm.toStringAsFixed(1)} km (~$estMins menit perjalanan)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Mulai Rute di Google Maps',
              icon: Icons.directions_rounded,
              onPressed: () async {
                Navigator.pop(ctx);
                final gmapsUrl = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${_r.lat},${_r.lng}&destination_place_id=&travelmode=driving',
                );
                try {
                  if (await canLaunchUrl(gmapsUrl)) {
                    await launchUrl(gmapsUrl, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(gmapsUrl);
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka rute ke ${_r.name}...'),
                        backgroundColor: AppColors.greenDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  double _haversineDist(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  void _shareRestaurant() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan ${_r.name} disalin ke papan klip!'),
        backgroundColor: AppColors.greenDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _imageHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _restaurantInfo(),
                      const SizedBox(height: 16),
                      _quickActions(),
                      const SizedBox(height: 20),
                      _menuSection(),
                      const SizedBox(height: 20),
                      _reviewsSection(),
                    ]),
                  ),
                ),
              ],
            ),
            _topBar(),
            _bottomStickyBar(),
          ],
        ),
      ),
    );
  }

  Widget _imageHeader() {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_r.imageUrl != null && _r.imageUrl!.isNotEmpty)
            Image.network(
              _r.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackImage(),
            )
          else
            _fallbackImage(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _r.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _r.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return const FoodImage(
      height: 240,
      width: double.infinity,
      icon: Icons.restaurant,
      borderRadius: BorderRadius.zero,
      colors: [AppColors.greenDark, AppColors.green],
    );
  }

  Widget _topBar() {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 8, 12, 0),
        child: Row(
          children: [
            _circleButton(
              Icons.arrow_back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            _circleButton(
              Icons.share_outlined,
              onTap: _shareRestaurant,
            ),
            const SizedBox(width: 8),
            _circleButton(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.red : AppColors.textDark,
              onTap: _toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line.withValues(alpha: 0.8), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.textDark),
      ),
    );
  }

  Widget _restaurantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 15, color: AppColors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${_r.address} - ${_r.province}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.payments_outlined,
                size: 16, color: AppColors.greenDark),
            const SizedBox(width: 6),
            Text(
              _r.priceRange,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.greenDark,
              ),
            ),
            const Spacer(),
            if (_r.openingHours != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.greenDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _r.openingHours!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.directions, 'Petunjuk', _showDirectionsDialog),
        _actionButton(Icons.login_rounded, 'Check-in', () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckinPage(restaurant: _r),
            ),
          );
        }),
        _actionButton(
          _isFavorite ? Icons.bookmark : Icons.bookmark_border,
          'Simpan',
          _toggleFavorite,
        ),
        _actionButton(Icons.rate_review_outlined, 'Ulas', _showAddReviewDialog),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: AppColors.greenDark),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Unggulan', style: AppText.display(16)),
        const SizedBox(height: 10),
        if (_foodsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          )
        else if (_foodsError != null)
          _errorTile(_foodsError!, _loadFoods)
        else if (_foods.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada menu yang terdaftar.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ..._foods.map(_foodTile),
      ],
    );
  }

  Widget _foodTile(Food f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodImage(
            imageUrl: f.imageUrl,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(12),
            icon: Icons.lunch_dining_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (f.description != null && f.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    f.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  f.priceLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Catatan Rasa Kurator', style: AppText.display(16)),
            ),
            GestureDetector(
              onTap: _showAddReviewDialog,
              child: const Text(
                '+ Tambah Ulasan',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_reviewsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
          )
        else if (_reviewsError != null)
          _errorTile(_reviewsError!, _loadReviews)
        else if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada ulasan untuk tempat ini. Jadilah yang pertama!',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ..._reviews.map(_reviewTile),
      ],
    );
  }

  Widget _reviewTile(Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.greenDark,
                child: Text(
                  (r.userName != null && r.userName!.isNotEmpty)
                      ? r.userName![0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.yellow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.userName ?? 'Kurator Rasa',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.orange,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.comment,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorTile(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.red),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gagal memuat data.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomStickyBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: PrimaryButton(
          label: 'Petunjuk Arah',
          icon: Icons.directions,
          onPressed: _showDirectionsDialog,
        ),
      ),
    );
  }
}
