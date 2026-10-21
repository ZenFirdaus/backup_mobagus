import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationModel {
  final double lat;
  final double lng;
  final String address;
  final String city;
  final bool isGps;

  const LocationModel({
    required this.lat,
    required this.lng,
    required this.address,
    required this.city,
    this.isGps = true,
  });
}

/// Service tunggal untuk mengelola lokasi pengguna, GPS, dan perhitungan jarak LBS
class LocationService {
  LocationService._() {
    _loadSavedLocation();
  }
  static final instance = LocationService._();

  final ValueNotifier<LocationModel?> currentLocation = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> statusMessage = ValueNotifier(null);

  static const _nominatimUserAgent = 'MoBagus-App/1.0 (flutter_application_1)';

  // Preset wilayah kuliner di DIY & Jawa Tengah
  static const List<Map<String, dynamic>> presetRegions = [
    {
      'name': 'Kota Yogyakarta',
      'desc': 'Malioboro, Wijilan, Kraton, Kotagede',
      'lat': -7.7956,
      'lng': 110.3695,
      'city': 'Yogyakarta',
    },
    {
      'name': 'Sleman',
      'desc': 'UGM, Kaliurang, Kalasan, Seturan',
      'lat': -7.7713,
      'lng': 110.3775,
      'city': 'Sleman',
    },
    {
      'name': 'Bantul',
      'desc': 'Sewon, Kasihan, Imogiri, Parangtritis',
      'lat': -7.8712,
      'lng': 110.3298,
      'city': 'Bantul',
    },
    {
      'name': 'Surakarta (Solo)',
      'desc': 'Pasar Gede, Slamet Riyadi, Laweyan',
      'lat': -7.5693,
      'lng': 110.8284,
      'city': 'Surakarta',
    },
    {
      'name': 'Semarang',
      'desc': 'Simpang Lima, Kota Lama, Pandanaran',
      'lat': -6.9926,
      'lng': 110.4208,
      'city': 'Semarang',
    },
  ];

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('foodie_loc_lat');
      final lng = prefs.getDouble('foodie_loc_lng');
      final addr = prefs.getString('foodie_loc_addr');
      final city = prefs.getString('foodie_loc_city');
      final isGps = prefs.getBool('foodie_loc_is_gps') ?? false;

      if (lat != null && lng != null && addr != null) {
        currentLocation.value = LocationModel(
          lat: lat,
          lng: lng,
          address: addr,
          city: city ?? 'Yogyakarta',
          isGps: isGps,
        );
      } else {
        // Default ke Kota Yogyakarta jika belum pernah memilih
        currentLocation.value = const LocationModel(
          lat: -7.7956,
          lng: 110.3695,
          address: 'Pusat Kota Yogyakarta, Malioboro',
          city: 'Yogyakarta',
          isGps: false,
        );
      }
    } catch (_) {}
  }

  /// Deteksi lokasi GPS pengguna saat ini secara akurat
  Future<bool> fetchGpsLocation() async {
    isLoading.value = true;
    statusMessage.value = 'Memeriksa akses GPS...';

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        statusMessage.value = 'Layanan GPS tidak aktif. Ketuk untuk mengaktifkan.';
        isLoading.value = false;
        return false;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied) {
        statusMessage.value = 'Izin lokasi ditolak. Silakan izinkan akses lokasi.';
        isLoading.value = false;
        return false;
      }

      if (perm == LocationPermission.deniedForever) {
        statusMessage.value = 'Izin lokasi ditolak permanen di Pengaturan perangkat.';
        isLoading.value = false;
        return false;
      }

      statusMessage.value = 'Mendeteksi koordinat GPS...';

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      statusMessage.value = 'Mengambil nama jalan & area...';
      final geo = await _reverseGeocode(pos.latitude, pos.longitude);

      final model = LocationModel(
        lat: pos.latitude,
        lng: pos.longitude,
        address: geo['address'] ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        city: geo['city'] ?? _guessCity(pos.latitude, pos.longitude),
        isGps: true,
      );

      currentLocation.value = model;
      statusMessage.value = null;
      isLoading.value = false;

      _saveToPrefs(model);
      return true;
    } catch (e) {
      debugPrint('Error fetchGpsLocation: $e');
      statusMessage.value = 'Gagal mengambil sinyal GPS: ${e.toString().split(':').first}';
      isLoading.value = false;
      return false;
    }
  }

  /// Pilih lokasi manual dari preset / kota
  Future<void> setManualLocation({
    required String name,
    required String address,
    required String city,
    required double lat,
    required double lng,
  }) async {
    final model = LocationModel(
      lat: lat,
      lng: lng,
      address: address.isNotEmpty ? address : name,
      city: city,
      isGps: false,
    );
    currentLocation.value = model;
    statusMessage.value = null;
    await _saveToPrefs(model);
  }

  Future<void> _saveToPrefs(LocationModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('foodie_loc_lat', model.lat);
      await prefs.setDouble('foodie_loc_lng', model.lng);
      await prefs.setString('foodie_loc_addr', model.address);
      await prefs.setString('foodie_loc_city', model.city);
      await prefs.setBool('foodie_loc_is_gps', model.isGps);
    } catch (_) {}
  }

  /// Reverse geocoding dengan Nominatim OpenStreetMap
  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json',
      );
      final res = await http.get(url, headers: {
        'User-Agent': _nominatimUserAgent,
        'Accept-Language': 'id',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>?;

        if (addr != null) {
          final road = addr['road'] ?? addr['pedestrian'] ?? addr['neighbourhood'] ?? '';
          final sub = addr['suburb'] ?? addr['village'] ?? addr['hamlet'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['city_district'] ?? '';

          final parts = [road, sub, city].where((s) => s.toString().trim().isNotEmpty).toList();
          final shortAddr = parts.take(2).join(', ');
          final detectedCity = city.toString().replaceAll('Kota ', '').replaceAll('Kabupaten ', '').trim();

          return {
            'address': shortAddr.isNotEmpty ? shortAddr : (json['display_name'] ?? '$lat, $lng'),
            'city': detectedCity.isNotEmpty ? detectedCity : _guessCity(lat, lng),
          };
        }
      }
    } catch (_) {}

    return {
      'address': '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      'city': _guessCity(lat, lng),
    };
  }

  /// Tebak kota terdekat berdasarkan koordinat
  String _guessCity(double lat, double lng) {
    String closest = 'Yogyakarta';
    double minD = double.infinity;

    for (final reg in presetRegions) {
      final d = distanceM(lat, lng, reg['lat'] as double, reg['lng'] as double);
      if (d < minD) {
        minD = d;
        closest = reg['city'] as String;
      }
    }
    return closest;
  }

  /// Rumus Haversine: hitung jarak dalam meter
  double distanceM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Format jarak yang ramah dibaca
  String formatDistance(double meters) {
    if (meters < 100) return '< 100 m';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
