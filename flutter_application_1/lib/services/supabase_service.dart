import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/restaurant.dart';
import '../models/food.dart';
import '../models/profile.dart';
import '../models/review.dart';
import '../models/checkin.dart';
import '../models/seed_data.dart';
import '../models/course_feedback.dart';
import 'hive_service.dart';

class SupabaseService {
  SupabaseService._() {
    initStorage();
    _initRealtime();
    _initAuthListener();
  }
  static final instance = SupabaseService._();

  SupabaseClient? get _safeClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser {
    try {
      return _safeClient?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }
  String? _demoUserId;
  void setDemoUser(String? id) => _demoUserId = id;
  String? get userId => currentUser?.id ?? _demoUserId;
  String curatorName = 'Kurator Rasa';
  String get guestName => curatorName;
  set guestName(String val) => curatorName = val;

  final Set<String> _localFavorites = {};
  final List<Checkin> _localCheckins = [];
  final List<Review> _localReviews = [];
  final List<Map<String, dynamic>> _localSearchHistory = [];
  int _localBonusPoints = 0;
  bool _initialized = false;

  // ─── REAL-TIME BROADCAST STREAMS ───
  final StreamController<Set<String>> _favoritesController =
      StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get favoritesStream => _favoritesController.stream;

  final StreamController<Review> _reviewAddedController =
      StreamController<Review>.broadcast();
  Stream<Review> get onReviewAdded => _reviewAddedController.stream;

  final StreamController<String> _reviewsChangedController =
      StreamController<String>.broadcast();
  Stream<String> get onReviewsChanged => _reviewsChangedController.stream;

  final StreamController<void> _profileChangedController =
      StreamController<void>.broadcast();
  Stream<void> get onProfileChanged => _profileChangedController.stream;

  void notifyProfileChanged() {
    _profileChangedController.add(null);
  }

  final StreamController<CourseFeedback> _courseFeedbackAddedController =
      StreamController<CourseFeedback>.broadcast();
  Stream<CourseFeedback> get onCourseFeedbackAdded =>
      _courseFeedbackAddedController.stream;

  RealtimeChannel? _reviewsChannel;
  RealtimeChannel? _favoritesChannel;
  RealtimeChannel? _courseFeedbackChannel;
  StreamSubscription<AuthState>? _authSub;

  void _initAuthListener() {
    try {
      final client = _safeClient;
      if (client == null) return;
      _authSub?.cancel();
      _authSub = client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          await initStorage(force: true);
          await syncBiometricsFromCloud();
          _initRealtime();
          try {
            await getUserReviews();
            await getFavoriteIds();
          } catch (_) {}
          _favoritesController.add(Set<String>.from(_localFavorites));
          _profileChangedController.add(null);
        } else if (event == AuthChangeEvent.signedOut) {
          _localFavorites.clear();
          _localCheckins.clear();
          _localReviews.clear();
          _localSearchHistory.clear();
          _localBonusPoints = 0;
          _demoUserId = null;
          _initialized = false;
          _reviewsChannel?.unsubscribe();
          _favoritesChannel?.unsubscribe();
          _courseFeedbackChannel?.unsubscribe();
          _reviewsChannel = null;
          _favoritesChannel = null;
          _courseFeedbackChannel = null;
        }
      });
    } catch (_) {}
  }

  void _initRealtime() {
    try {
      _reviewsChannel?.unsubscribe();
      _reviewsChannel = _client
          .channel('public:reviews')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reviews',
            callback: (payload) {
              final newRec = payload.newRecord;
              final restoId = newRec['restaurant_id']?.toString() ?? '';
              _reviewsChangedController.add(restoId);
              _profileChangedController.add(null);
            },
          )
          .subscribe();

      _favoritesChannel?.unsubscribe();
      _favoritesChannel = _client
          .channel('public:favorites')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'favorites',
            callback: (payload) async {
              await getFavoriteIds();
              _favoritesController.add(Set<String>.from(_localFavorites));
              _profileChangedController.add(null);
            },
          )
          .subscribe();

      _courseFeedbackChannel?.unsubscribe();
      _courseFeedbackChannel = _client
          .channel('public:course_feedback')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'course_feedback',
            callback: (payload) {
              if (payload.newRecord.isNotEmpty) {
                try {
                  final fb = CourseFeedback.fromJson(payload.newRecord);
                  _courseFeedbackAddedController.add(fb);
                } catch (_) {}
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> initStorage({bool force = false}) async {
    if (_initialized && !force) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';

      _localFavorites.clear();
      _localSearchHistory.clear();
      _localCheckins.clear();
      _localReviews.clear();

      // Load favorites
      final favList = prefs.getStringList('foodie_fav_$uid');
      if (favList != null) {
        _localFavorites.addAll(favList);
      }

      // Load bonus points
      _localBonusPoints = prefs.getInt('foodie_points_$uid') ?? 0;

      // Load search history
      final historyRaw = prefs.getStringList('foodie_hist_$uid');
      if (historyRaw != null) {
        for (final item in historyRaw) {
          try {
            _localSearchHistory.add(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {}
        }
      }

      // Load checkins
      final checkinsRaw = prefs.getStringList('foodie_chk_$uid');
      if (checkinsRaw != null) {
        for (final item in checkinsRaw) {
          try {
            _localCheckins.add(Checkin.fromJson(jsonDecode(item) as Map<String, dynamic>));
          } catch (_) {}
        }
      }

      // Load reviews
      final reviewsRaw = prefs.getStringList('foodie_rev_$uid');
      if (reviewsRaw != null) {
        for (final item in reviewsRaw) {
          try {
            final r = Review.fromJson(jsonDecode(item) as Map<String, dynamic>);
            if (!_localReviews.any((x) => x.id == r.id)) {
              _localReviews.add(r);
            }
          } catch (_) {}
        }
      }

      // Hanya muat ulasan tamu jika user saat ini memang berstatus guest
      if (uid == 'guest') {
        final guestRaw = prefs.getStringList('foodie_rev_guest');
        if (guestRaw != null) {
          for (final item in guestRaw) {
            try {
              final r = Review.fromJson(jsonDecode(item) as Map<String, dynamic>);
              if (!_localReviews.any((x) =>
                  x.id == r.id ||
                  (x.restaurantId == r.restaurantId && x.comment == r.comment))) {
                _localReviews.add(r);
              }
            } catch (_) {}
          }
        }
      }

      _initialized = true;
    } catch (_) {}
  }

  Future<void> _persistFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';
      await prefs.setStringList('foodie_fav_$uid', _localFavorites.toList());
    } catch (_) {}
  }

  Future<void> _persistPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';
      await prefs.setInt('foodie_points_$uid', _localBonusPoints);
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';
      final list = _localSearchHistory.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('foodie_hist_$uid', list);
    } catch (_) {}
  }

  Future<void> _persistCheckins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';
      final list = _localCheckins.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('foodie_chk_$uid', list);
    } catch (_) {}
  }

  Future<void> _persistReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';
      final list = _localReviews.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('foodie_rev_$uid', list);
      if (uid == 'guest') {
        await prefs.setStringList('foodie_rev_guest', list);
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    _reviewsChannel?.unsubscribe();
    _favoritesChannel?.unsubscribe();
    _courseFeedbackChannel?.unsubscribe();
    _reviewsChannel = null;
    _favoritesChannel = null;
    _courseFeedbackChannel = null;
    _localFavorites.clear();
    _localCheckins.clear();
    _localReviews.clear();
    _localSearchHistory.clear();
    _localBonusPoints = 0;
    _demoUserId = null;
    curatorName = 'Kurator Rasa';
    _initialized = false;
    _favoritesController.add({});
    _profileChangedController.add(null);

    // Bersihkan cache display name & avatar sementara agar profil bersih saat logout
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('foodie_current_display_name');
      await prefs.remove('foodie_current_avatar');
    } catch (_) {}

    try {
      await _safeClient?.auth.signOut();
    } catch (_) {}
  }

  // ─── BIOMETRICS SYNC (SUPABASE CLOUD + LOCAL HIVE DB) ───

  /// Menyimpan metrik biometrik wajah ke Supabase user metadata dan Hive local database
  Future<void> saveFaceBiometricsToCloud({
    required String email,
    required String name,
    required Map<String, dynamic> metrics,
    String? password,
  }) async {
    // 1. Simpan di database NoSQL lokal Hive (tahan logout berkali-kali)
    await HiveService.instance.saveBiometricProfile(
      email: email,
      name: name,
      password: password,
      metrics: metrics,
      userId: userId,
    );

    // 2. Simpan di Supabase Auth User Metadata (Cloud)
    try {
      final client = _safeClient;
      if (client != null && currentUser != null) {
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'face_biometric_enrolled': true,
              'face_metrics': metrics,
              'face_name': name,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Supabase cloud biometric sync error: $e');
    }
  }

  /// Sinkronisasi data biometrik dari Supabase Cloud ke database lokal Hive
  Future<void> syncBiometricsFromCloud() async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return;
      final meta = user.userMetadata;
      if (meta != null && meta['face_metrics'] != null) {
        final metricsMap =
            Map<String, dynamic>.from(meta['face_metrics'] as Map);
        final name = meta['face_name']?.toString() ??
            meta['name']?.toString() ??
            user.email!.split('@').first;
        await HiveService.instance.saveBiometricProfile(
          email: user.email!,
          name: name,
          metrics: metricsMap,
          userId: user.id,
        );
      }
    } catch (e) {
      debugPrint('Error syncing biometrics from cloud: $e');
    }
  }

  // ─── PROFILES ───

  Future<Profile?> getProfile() async {
    final uid = userId;
    final keyUid = uid ?? 'guest';
    String? localName;
    String? localAvatar;
    String? localActiveBorder;
    int? localSavedPoints;
    bool isAvatarDeleted = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      // Hanya ambil preferensi nama & avatar & border yang terikat pada keyUid pengguna saat ini
      localName = prefs.getString('foodie_name_$keyUid');
      localAvatar = prefs.getString('foodie_avatar_$keyUid');
      localActiveBorder = prefs.getString('foodie_active_border_$keyUid');
      localSavedPoints = prefs.getInt('foodie_points_$keyUid');
      isAvatarDeleted = prefs.getBool('foodie_avatar_deleted_$keyUid') ?? false;
    } catch (_) {}

    final metaAvatar = isAvatarDeleted
        ? null
        : (currentUser?.userMetadata?['avatar_url'] as String?);

    final defaultFallbackName = (currentUser?.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
        ? (currentUser!.userMetadata!['name'] as String).trim()
        : (currentUser?.email != null && currentUser!.email!.isNotEmpty)
            ? currentUser!.email!.split('@').first
            : (uid != null && uid.contains('@'))
                ? uid.split('@').first
                : curatorName;

    if (uid != null && _safeClient != null) {
      try {
        final res = await _safeClient!
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (res != null) {
          final p = Profile.fromJson(res);
          final effectiveAvatar = isAvatarDeleted
              ? null
              : (localAvatar != null && localAvatar.isNotEmpty)
                  ? localAvatar
                  : (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                      ? p.avatarUrl
                      : metaAvatar;

          final effectiveName = (localName != null && localName.trim().isNotEmpty)
              ? localName.trim()
              : p.displayName.trim().isNotEmpty
                  ? p.displayName.trim()
                  : defaultFallbackName;

          final effectiveActiveBorder = (p.activeBorderId != null && p.activeBorderId!.isNotEmpty)
              ? p.activeBorderId
              : localActiveBorder;

          final effectivePoints = localSavedPoints ?? (p.points + _localBonusPoints);

          return Profile(
            id: p.id,
            displayName: effectiveName,
            avatarUrl: effectiveAvatar,
            activeBorderId: effectiveActiveBorder,
            points: effectivePoints,
            createdAt: p.createdAt,
          );
        }
      } catch (e) {
        debugPrint('Supabase getProfile error: $e');
      }
    }

    final effectiveName = (localName != null && localName.trim().isNotEmpty)
        ? localName.trim()
        : defaultFallbackName;

    final effectiveAvatar = isAvatarDeleted
        ? null
        : (localAvatar != null && localAvatar.isNotEmpty)
            ? localAvatar
            : metaAvatar;

    return Profile(
      id: uid ?? 'curator_user',
      displayName: effectiveName,
      avatarUrl: effectiveAvatar,
      activeBorderId: localActiveBorder,
      points: localSavedPoints ?? (100 + _localBonusPoints + (_localCheckins.length * 50)),
      createdAt: DateTime.now(),
    );
  }

  Future<void> upsertProfile({
    required String displayName,
    String? avatarUrl,
    String? activeBorderId,
  }) async {
    final uid = userId;
    final keyUid = uid ?? 'guest';
    curatorName = displayName;

    // 1. Simpan di SharedPreferences lokal secara persisten di berbagai key
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('foodie_name_$keyUid', displayName);
      await prefs.setString('foodie_current_display_name', displayName);
      await prefs.setString('foodie_last_user_name', displayName);

      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        await prefs.setString('foodie_avatar_$keyUid', avatarUrl.trim());
        await prefs.setBool('foodie_avatar_deleted_$keyUid', false);
      } else {
        await prefs.remove('foodie_avatar_$keyUid');
        await prefs.setBool('foodie_avatar_deleted_$keyUid', true);
      }

      if (activeBorderId != null) {
        if (activeBorderId.trim().isNotEmpty) {
          await prefs.setString('foodie_active_border_$keyUid', activeBorderId.trim());
        } else {
          await prefs.remove('foodie_active_border_$keyUid');
        }
      }
    } catch (_) {}

    // Jika user adalah guest murni
    if (uid == null) {
      _profileChangedController.add(null);
      return;
    }

    // 2. Simpan di Supabase Auth user metadata
    try {
      final data = <String, dynamic>{'name': displayName};
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        data['avatar_url'] = avatarUrl.trim();
      } else {
        data['avatar_url'] = '';
      }
      await _client.auth.updateUser(UserAttributes(data: data));
    } catch (e) {
      debugPrint('Supabase auth.updateUser error: $e');
    }

    // 3. Simpan di tabel public.profiles di Supabase
    try {
      final payload = <String, dynamic>{
        'id': uid,
        'display_name': displayName,
        'avatar_url': (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : null,
      };
      if (activeBorderId != null) {
        payload['active_border_id'] = activeBorderId.trim().isNotEmpty
            ? activeBorderId.trim()
            : null;
      }
      await _client.from('profiles').upsert(payload, onConflict: 'id');
    } catch (e) {
      debugPrint('Supabase profiles.upsert with avatar_url error: $e');
      try {
        await _client.from('profiles').upsert({
          'id': uid,
          'display_name': displayName,
        }, onConflict: 'id');
      } catch (_) {}
    }

    _profileChangedController.add(null);
  }

  // ─── RESTAURANTS ───

  Future<List<Restaurant>> getRestaurants({
    String? search,
    int? maxPrice,
    String? category,
    String? sortBy,
  }) async {
    try {
      var query = _client.from('restaurants').select();

      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,category.ilike.%$search%');
      }
      if (maxPrice != null) {
        query = query.lte('price_min', maxPrice);
      }
      if (category != null && category.isNotEmpty) {
        final lower = category.trim().toLowerCase();
        if (lower == 'fast food' || lower == 'fast_food') {
          query = query.or('category.ilike.%fast_food%,category.ilike.%fast food%,category.ilike.%cepat saji%');
        } else if (lower == 'food court' || lower == 'food_court') {
          query = query.or('category.ilike.%food_court%,category.ilike.%food court%,category.ilike.%court%,category.ilike.%sentra%');
        } else if (lower == 'cafe' || lower == 'kafe') {
          query = query.or('category.ilike.%cafe%,category.ilike.%kafe%,category.ilike.%coffee%');
        } else if (lower == 'restoran' || lower == 'restaurant') {
          query = query.or('category.ilike.%resto%,category.ilike.%restaurant%,category.ilike.%rumah makan%,category.ilike.%gudeg%');
        } else if (lower == 'warung tradisional' || lower == 'warung') {
          query = query.or('category.ilike.%warung%,category.ilike.%tradisional%,category.ilike.%soto%,category.ilike.%mie%,category.ilike.%bakmi%,category.ilike.%sate%');
        } else if (lower == 'angkringan') {
          query = query.or('category.ilike.%angkringan%');
        } else {
          final catClean = category.replaceAll('_', ' ');
          final catUnderscore = category.replaceAll(' ', '_');
          query = query.or('category.ilike.%$catClean%,category.ilike.%$catUnderscore%');
        }
      }

      PostgrestTransformBuilder<PostgrestList> ordered;
      switch (sortBy) {
        case 'termurah':
          ordered = query.order('price_min', ascending: true);
        default:
          ordered = query.order('name', ascending: true);
      }

      final res = await ordered;
      final list = (res as List).map((e) => Restaurant.fromJson(e)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    var filtered = List<Restaurant>.from(kDefaultRestaurants);
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      filtered = filtered
          .where((r) =>
              r.name.toLowerCase().contains(s) ||
              r.category.toLowerCase().contains(s) ||
              r.address.toLowerCase().contains(s))
          .toList();
    }
    if (maxPrice != null) {
      filtered = filtered.where((r) => r.priceMin <= maxPrice).toList();
    }
    if (category != null && category.isNotEmpty) {
      final catNorm = category.toLowerCase().replaceAll('_', ' ').trim();
      filtered = filtered.where((r) {
        final rCat = r.category.toLowerCase().replaceAll('_', ' ').trim();
        final rName = r.name.toLowerCase();
        final rDesc = (r.description ?? '').toLowerCase();

        if (catNorm == 'fast food' || catNorm == 'cepat saji') {
          return rCat.contains('fast') ||
              rCat.contains('cepat') ||
              rName.contains('burger') ||
              rName.contains('chicken') ||
              rName.contains('pizza') ||
              rDesc.contains('cepat saji') ||
              rDesc.contains('fast food');
        }
        if (catNorm == 'food court') {
          return rCat.contains('court') ||
              rCat.contains('sentra') ||
              rName.contains('food court') ||
              rDesc.contains('food court');
        }
        if (catNorm == 'cafe' || catNorm == 'kafe') {
          return rCat.contains('cafe') ||
              rCat.contains('kafe') ||
              rCat.contains('coffee') ||
              rCat.contains('kopi');
        }
        if (catNorm == 'restoran' || catNorm == 'restaurant') {
          return rCat.contains('resto') ||
              rCat.contains('restaurant') ||
              rCat.contains('rumah makan') ||
              rCat.contains('gudeg');
        }
        if (catNorm == 'warung tradisional' || catNorm == 'warung') {
          return rCat.contains('warung') ||
              rCat.contains('tradisional') ||
              rCat.contains('soto') ||
              rCat.contains('bakmi') ||
              rCat.contains('mie') ||
              rCat.contains('sate');
        }
        if (catNorm == 'angkringan') {
          return rCat.contains('angkringan');
        }
        return rCat.contains(catNorm) || catNorm.contains(rCat);
      }).toList();
    }
    if (sortBy == 'termurah') {
      filtered.sort((a, b) => a.priceMin.compareTo(b.priceMin));
    }
    return filtered;
  }

  Future<Restaurant?> getRestaurant(String id) async {
    try {
      final res =
          await _client.from('restaurants').select().eq('id', id).maybeSingle();
      if (res != null) return Restaurant.fromJson(res);
    } catch (_) {}
    return kDefaultRestaurants.where((r) => r.id == id).firstOrNull;
  }

  Future<List<String>> getCategories() async {
    // Hanya kategori bentuk tempat (Restoran, Cafe, Fast Food, Food Court, Warung Tradisional, Angkringan)
    return List<String>.from(kDefaultCategories);
  }

  // ─── FOODS ───

  Future<List<Food>> getFoods(String restaurantId, [Restaurant? restaurant]) async {
    try {
      final res = await _client
          .from('foods')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('price', ascending: true);
      final list = (res as List).map((e) => Food.fromJson(e)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}

    Restaurant? targetResto = restaurant;
    targetResto ??= await getRestaurant(restaurantId);
    if (targetResto != null) {
      return generateDynamicFoods(targetResto);
    }

    final seedList = kDefaultFoods[restaurantId] ??
        kDefaultFoods['resto_$restaurantId'] ??
        (restaurantId.startsWith('resto_')
            ? kDefaultFoods[restaurantId.replaceFirst('resto_', '')]
            : null);
    if (seedList != null && seedList.isNotEmpty) {
      return seedList;
    }

    return [];
  }

  /// Membuat daftar hidangan otentik berdasarkan detail cuisine, nama, kategori,
  /// dan rentang harga restoran (price_min - price_max)
  /// Membuat daftar hidangan otentik berdasarkan detail cuisine, nama, kategori,
  /// dan rentang harga restoran (price_min - price_max)
  List<Food> generateDynamicFoods(Restaurant r) {
    final List<Food> items = [];
    final pMin = r.priceMin > 0 ? r.priceMin : 12000;
    final pMax = r.priceMax > pMin ? r.priceMax : pMin + 25000;

    int priceAt(double fraction) {
      final raw = pMin + (pMax - pMin) * fraction;
      final rounded = (raw / 1000).round() * 1000;
      return math.max(3000, rounded);
    }

    final query =
        '${r.name.toLowerCase()} ${r.cuisine?.toLowerCase() ?? ''} ${r.category.toLowerCase()}';

    // ─── 1. KATA KUNCI SPESIFIK INDONESIA PRIORITAS UTAMA ───

    // A. Bakpia / Pia / Oleh-oleh Khas Jogja
    if (query.contains('bakpia') ||
        query.contains('pia ') ||
        query.contains('pathok') ||
        query.contains('djava') ||
        query.contains('kurnia sari') ||
        query.contains('oleh-oleh')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Bakpia Basah Kacang Hijau Asli',
          price: priceAt(0.50),
          category: 'Bakpia & Oleh-Oleh',
          description: 'Kulit lembut isi pasta kacang hijau manis legit',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Bakpia Keju Spesial Lumer',
          price: priceAt(0.65),
          category: 'Bakpia & Oleh-Oleh',
          description: 'Isian keju cheddar gurih berpadu manis harum',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Bakpia Cokelat Premium',
          price: priceAt(0.60),
          category: 'Bakpia & Oleh-Oleh',
          description: 'Cokelat lumer khas dengan aroma mentega wangi',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Bakpia Kering Aneka Rasa (Isi 20)',
          price: priceAt(0.75),
          category: 'Bakpia & Oleh-Oleh',
          description: 'Tahan lebih lama cocok untuk buah tangan keluarga',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Bakpia Kukus Lembut Khas Jogja',
          price: priceAt(0.70),
          category: 'Bakpia & Oleh-Oleh',
          description: 'Tekstur sponge cake lembut isi cokelat / keju',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // B. Nasi Padang / Minang / Rendang / Ampera
    if (query.contains('padang') ||
        query.contains('minang') ||
        query.contains('rendang') ||
        query.contains('ampera') ||
        query.contains('salero') ||
        query.contains('sederhana')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Nasi Rendang Daging Sapi Balado',
          price: priceAt(0.75),
          category: 'Menu Utama',
          description: 'Daging sapi empuk bumbu rempah hitam pekat khas Padang',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Ayam Pop Khas Minang & Sambal Merah',
          price: priceAt(0.65),
          category: 'Menu Utama',
          description: 'Ayam lembut gurih disajikan dengan sambal tomat khas',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Gulai Tunjang / Cincang Sapi Gurih',
          price: priceAt(0.80),
          category: 'Menu Utama',
          description: 'Kuah santan kental berempah dengan kikil tunjang empuk',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Telur Dadar Padang Tebal Gurih',
          price: math.max(6000, priceAt(0.35)),
          category: 'Pendamping',
          description: 'Dadar telur bebek tebal bertabur daun bawang dan cabai',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Sambal Ijo & Daun Singkong Rebus',
          price: math.max(4000, priceAt(0.20)),
          category: 'Pendamping',
          description: 'Pelengkap wajib nasi padang dengan cabai hijau gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_6',
          restaurantId: r.id,
          name: 'Es Tebak / Es Teh Manis Segar',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Minuman dingin penyegar santapan bersantan',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // C. Pempek / Palembang
    if (query.contains('pempek') ||
        query.contains('empek') ||
        query.contains('palembang')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Pempek Kapal Selam Telur Utuh',
          price: priceAt(0.70),
          category: 'Menu Utama',
          description: 'Pempek ikan tenggiri asli dengan isian telur bebek utuh',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Pempek Lenjer Asli Tenggiri',
          price: priceAt(0.50),
          category: 'Menu Utama',
          description: 'Tekstur kenyal gurih dengan aroma ikan segar',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Pempek Kulit Crispy Gurih',
          price: priceAt(0.45),
          category: 'Menu Utama',
          description: 'Garing renyah di luar, empuk gurih di dalam',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Cuko Hitam Kental Asli Palembang',
          price: math.max(3000, priceAt(0.15)),
          category: 'Pendamping',
          description: 'Gula aren batok asli berpadu asam manis pedas pas',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Kacang Merah Segar',
          price: math.max(5000, priceAt(0.25)),
          category: 'Minuman',
          description: 'Kacang merah empuk manis berpadu es serut dan susu',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // D. Gudeg Khas Yogyakarta
    if (query.contains('gudeg') ||
        query.contains('yu djum') ||
        query.contains('bu tjitro')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Nasi Gudeg Komplit Telur & Ayam Suwir',
          price: priceAt(0.65),
          category: 'Menu Utama',
          description: 'Gudeg nangka manis legit disajikan dengan krecek pedas',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Sambal Goreng Krecek Pedas Gurih',
          price: priceAt(0.50),
          category: 'Menu Utama',
          description: 'Kulit sapi kenyal gurih dengan cabai rawit utuh',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Nasi Gudeg Paha Ayam Utuh',
          price: priceAt(0.85),
          category: 'Menu Utama',
          description: 'Paha ayam opor empuk bumbu meresap hingga tulang',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Tahu & Tempe Bacem Legit',
          price: math.max(4000, priceAt(0.25)),
          category: 'Pendamping',
          description: 'Bumbu gula kelapa manis rempah meresap sempurna',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Teh Poci Gula Batu Hangat',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Seduhan teh melati wangi dengan manisnya gula batu',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // E. Bakso / Pentol / Baso
    if (query.contains('bakso') ||
        query.contains('pentol') ||
        query.contains('baso')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Bakso Urat Granat Jumbo Kuah Sapi',
          price: priceAt(0.70),
          category: 'Menu Utama',
          description: 'Pentol urat kenyal mantap dengan kaldu sumsum gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Bakso Halus Komplit Tahu & Mie',
          price: priceAt(0.55),
          category: 'Menu Utama',
          description: 'Bakso daging sapi halus disajikan dengan bihun dan sawi',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Tetelan Daging Sapi Gurih Melimpah',
          price: priceAt(0.40),
          category: 'Pendamping',
          description: 'Potongan tetelan sapi empuk berlemak lezat',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Pangsit Goreng Renyah & Bakso Goreng',
          price: math.max(4000, priceAt(0.25)),
          category: 'Camilan',
          description: 'Gorengan renyah pelengkap makan bakso berkuah hangat',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Teh Manis Segar Jumbo',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Penyegar tenggorokan setelah menyantap bakso pedas',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // F. Soto / Sop / Sroto / Saoto
    if (query.contains('soto') ||
        query.contains('sop') ||
        query.contains('soup') ||
        query.contains('sroto') ||
        query.contains('saoto')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Soto Daging Sapi Kuah Bening Gurih',
          price: priceAt(0.60),
          category: 'Menu Utama',
          description: 'Kuah kaldu sapi bening kaya rempah dengan irisan daging',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Soto Ayam Kampung Spesial Koya',
          price: priceAt(0.50),
          category: 'Menu Utama',
          description: 'Suwiran ayam kampung gurih dengan taburan koya gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Soto Pisah Nasi + Babat / Paru Goreng',
          price: priceAt(0.75),
          category: 'Menu Utama',
          description: 'Porsi lengkap kenyang dengan jeroan sapi goreng gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Perkedel Kentang & Tempe Bacem',
          price: math.max(4000, priceAt(0.25)),
          category: 'Pendamping',
          description: 'Lauk pelengkap soto yang gurih dan renyah',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Jeruk Peras Segar Asli',
          price: math.max(4000, priceAt(0.20)),
          category: 'Minuman',
          description: 'Perasan jeruk asli manis asam menyegarkan',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // G. Sate / Kambing / Tongseng / Gule
    if (query.contains('sate') ||
        query.contains('satay') ||
        query.contains('tongseng') ||
        query.contains('gule') ||
        query.contains('kambing')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Sate Daging Bumbu Kecap / Kacang (10 Tusuk)',
          price: priceAt(0.75),
          category: 'Menu Utama',
          description: 'Daging empuk dibakar arang dengan lumuran bumbu gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Tongseng Kuah Rempah Gurih',
          price: priceAt(0.80),
          category: 'Menu Utama',
          description: 'Kuah santan gurih manis berpadu kol, tomat, dan cabai',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Gulai Hangat Bumbu Sedap',
          price: priceAt(0.65),
          category: 'Menu Utama',
          description: 'Kuah kuning kaya kapulaga dan rempah nusantara',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Lontong / Nasi Putih Hangat',
          price: math.max(4000, priceAt(0.18)),
          category: 'Pendamping',
          description: 'Pelengkap nikmat bersantap sate dan kuah tongseng',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Jeruk Nipis / Teh Manis',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Penyegar penyeimbang hidangan daging',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // H. Bebek Goreng / Bakar
    if (query.contains('bebek') || query.contains('duck')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Bebek Goreng Kremes Sambal Korek',
          price: priceAt(0.75),
          category: 'Menu Utama',
          description: 'Bebek empuk tidak amis bertabur kremesan garing gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Bebek Bakar Bumbu Madu Manis Pedas',
          price: priceAt(0.80),
          category: 'Menu Utama',
          description: 'Bumbu bakar manis meresap hingga serat daging terdalam',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Nasi Bebek Bumbu Hitam Madura',
          price: priceAt(0.70),
          category: 'Menu Utama',
          description: 'Minyak bumbu hitam rempah khas dengan nasi hangat',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Lalapan Segar & Tahu Tempe',
          price: math.max(4000, priceAt(0.20)),
          category: 'Pendamping',
          description: 'Timun, kemangi, kubis goreng dan tahu tempe hangat',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Teh Manis Dingin Segar',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Minuman pelepas dahaga sempurna',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // I. Ayam Goreng / Bakar / Geprek / Kremes
    if (query.contains('ayam') ||
        query.contains('chicken') ||
        query.contains('kremes') ||
        query.contains('geprek') ||
        query.contains('penyet')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Paket Ayam Goreng Kremes + Nasi Hangat',
          price: priceAt(0.65),
          category: 'Menu Utama',
          description: 'Ayam bumbu kuning empuk bertabur kremes renyah melimpah',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Ayam Bakar Madu Spesial Sambal Terasi',
          price: priceAt(0.70),
          category: 'Menu Utama',
          description: 'Bakar kecap madu beraroma asap harum menggugah selera',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Ayam Geprek Crispy Sambal Bawang',
          price: priceAt(0.55),
          category: 'Menu Utama',
          description: 'Ayam goreng tepung renyah digeprek dengan cabai pedas',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Tahu & Tempe Goreng Sambal Bawang',
          price: math.max(4000, priceAt(0.25)),
          category: 'Pendamping',
          description: 'Lauk gurih pendamping nasi dan ayam',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Jeruk Manis Segar',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Minuman jeruk manis segar pelepas dahaga',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // J. Bakmi / Mie / Kwetiau / Bihun
    if (query.contains('bakmi') ||
        query.contains('mie') ||
        query.contains('noodle') ||
        query.contains('ramen') ||
        query.contains('bihun') ||
        query.contains('kwetiau')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Bakmi Godhog Gurih Spesial',
          price: priceAt(0.55),
          category: 'Menu Utama',
          description: 'Mie kuning berkuah kaldu ayam gurih bertabur telur bebek',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Bakmi Goreng Telur Bebek Manis Gurih',
          price: priceAt(0.65),
          category: 'Menu Utama',
          description: 'Aroma wajan smokey dengan suwiran ayam dan acar segar',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Magelangan / Nasi Goreng Ruwet',
          price: priceAt(0.60),
          category: 'Menu Utama',
          description: 'Campuran nasi dan mie goreng nikmat khas kuliner Jawa',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Pangsit Goreng Renyah Gurih',
          price: math.max(4000, priceAt(0.25)),
          category: 'Camilan',
          description: 'Camilan garing pendamping santap mie',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Teh Nasgitel / Wedang Jahe Panas',
          price: math.max(4000, priceAt(0.18)),
          category: 'Minuman',
          description: 'Teh manis pekat kental khas angkringan / bakmi',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // K. Seafood / Ikan / Lele / Mangut / Udang / Cumi
    if (query.contains('ikan') ||
        query.contains('seafood') ||
        query.contains('lele') ||
        query.contains('mangut') ||
        query.contains('gurame') ||
        query.contains('nila') ||
        query.contains('udang') ||
        query.contains('cumi')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Mangut Lele Asap Kuah Santan Pedas',
          price: priceAt(0.60),
          category: 'Menu Utama',
          description: 'Ikan lele asap wangi kuah santan gurih beraroma kemangi',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Gurame / Nila Bakar Bumbu Madu Gurih',
          price: priceAt(0.85),
          category: 'Menu Utama',
          description: 'Ikan bakar segar dioles bumbu rempah bakar harum',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Udang / Cumi Saus Padang Pedas Manis',
          price: priceAt(0.80),
          category: 'Menu Utama',
          description: 'Seafood segar disiram saus padang kaya bumbu',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Cah Kangkung Terasi Hangat',
          price: math.max(4000, priceAt(0.30)),
          category: 'Pendamping',
          description: 'Kangkung renyah ditumis dengan terasi harum',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Es Kelapa Muda Segar',
          price: math.max(5000, priceAt(0.25)),
          category: 'Minuman',
          description: 'Air kelapa murni dengan serutan daging kelapa muda',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // L. Kopi / Kafe / Coffee / Cafe
    if (query.contains('kopi') ||
        query.contains('coffee') ||
        query.contains('cafe') ||
        query.contains('kafe') ||
        query.contains('espresso')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Kopi Susu Gula Aren Signature',
          price: priceAt(0.40),
          category: 'Kopi & Minuman',
          description: 'Espresso blend berpadu susu segar dan manis legit aren asli',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Manual Brew V60 Single Origin',
          price: priceAt(0.55),
          category: 'Kopi & Minuman',
          description: 'Biji kopi nusantara pilihan dengan citarasa fruity floral',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Americano / Long Black Dingin',
          price: priceAt(0.35),
          category: 'Kopi & Minuman',
          description: 'Kopi hitam murni yang mantap dan menyegarkan',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Croissant / Roti Bakar Cokelat Keju',
          price: priceAt(0.45),
          category: 'Camilan',
          description: 'Camilan manis pendamping waktu ngopi santai',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Matcha Green Tea Latte Dingin',
          price: priceAt(0.50),
          category: 'Kopi & Minuman',
          description: 'Minuman teh hijau jepang berpadu susu lembut',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // M. Angkringan / Nasi Kucing / Wedangan
    if (query.contains('angkringan') ||
        query.contains('kucing') ||
        query.contains('wedang')) {
      return [
        Food(
          id: 'dyn_${r.id}_1',
          restaurantId: r.id,
          name: 'Nasi Kucing Sambal Teri Gurih',
          price: math.max(3000, priceAt(0.25)),
          category: 'Menu Utama',
          description: 'Nasi bungkus daun pisang dengan sambal teri pedas gurih',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_2',
          restaurantId: r.id,
          name: 'Nasi Kucing Orek Tempe Manis',
          price: math.max(3000, priceAt(0.25)),
          category: 'Menu Utama',
          description: 'Nasi hangat dengan tumis tempe kecap legit',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_3',
          restaurantId: r.id,
          name: 'Aneka Sate Usus & Telur Puyuh Bacem',
          price: math.max(3000, priceAt(0.20)),
          category: 'Camilan',
          description: 'Sate khas angkringan yang dibakar saat dipesan',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_4',
          restaurantId: r.id,
          name: 'Tempe Mendoan Hangat & Sambal Kecap',
          price: math.max(3000, priceAt(0.18)),
          category: 'Camilan',
          description: 'Mendoan basah gurih bertabur daun bawang',
          createdAt: DateTime.now(),
        ),
        Food(
          id: 'dyn_${r.id}_5',
          restaurantId: r.id,
          name: 'Wedang Jahe Susu / Kopi Joss',
          price: math.max(4000, priceAt(0.25)),
          category: 'Minuman',
          description: 'Minuman penghangat badan dengan jahe geprek murni',
          createdAt: DateTime.now(),
        ),
      ];
    }

    // ─── 2. PARSING DARI CUISINE CSV JIKA ADA HIDANGAN TERTULIS ───
    final rawCuisine = r.cuisine?.trim() ?? '';
    if (rawCuisine.isNotEmpty) {
      final parts = rawCuisine
          .split(RegExp(r'[;,]|\s*dan\s*|_dan_|\+'))
          .map((e) => e.replaceAll('_', ' ').replaceAll('-', ' ').trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final parsed = <String>[];
      for (final p in parts) {
        final lower = p.toLowerCase();
        if (lower == 'indonesian' ||
            lower == 'javanese' ||
            lower == 'regional' ||
            lower == 'asian' ||
            lower == 'traditional' ||
            lower == 'food' ||
            lower == 'kuliner') {
          continue;
        }
        final title = p.split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
        if (!parsed.contains(title)) parsed.add(title);
      }

      if (parsed.isNotEmpty) {
        for (int i = 0; i < parsed.length; i++) {
          final dish = parsed[i];
          final lower = dish.toLowerCase();
          final String cat;
          final int price;

          if (lower.contains('teh') ||
              lower.contains('kopi') ||
              lower.contains('wedang') ||
              lower.contains('es ') ||
              lower.contains('jus') ||
              lower.contains('drink')) {
            cat = 'Minuman';
            price = math.max(4000, priceAt(0.15));
          } else if (lower.contains('mendoan') ||
              lower.contains('tempe') ||
              lower.contains('tahu') ||
              lower.contains('kerupuk') ||
              lower.contains('camilan') ||
              lower.contains('gorengan')) {
            cat = 'Camilan / Pendamping';
            price = math.max(5000, priceAt(0.30));
          } else {
            cat = 'Menu Utama';
            final frac = parsed.length == 1
                ? 0.70
                : 0.45 + (0.45 * (i / math.max(1, parsed.length - 1)));
            price = priceAt(frac);
          }

          items.add(Food(
            id: 'dyn_${r.id}_$i',
            restaurantId: r.id,
            name: dish,
            price: price,
            category: cat,
            createdAt: DateTime.now(),
          ));
        }

        if (items.length < 3) {
          items.add(Food(
            id: 'dyn_${r.id}_sup1',
            restaurantId: r.id,
            name: 'Menu Spesial Rumah',
            price: priceAt(0.70),
            category: 'Menu Utama',
            createdAt: DateTime.now(),
          ));
          items.add(Food(
            id: 'dyn_${r.id}_sup2',
            restaurantId: r.id,
            name: 'Es Teh Manis / Jeruk Segar',
            price: math.max(4000, priceAt(0.18)),
            category: 'Minuman',
            createdAt: DateTime.now(),
          ));
        }
        return items;
      }
    }

    // ─── 3. DEFAULT RESTORAN / RUMAH MAKAN NUSANTARA ───
    return [
      Food(
        id: 'dyn_${r.id}_1',
        restaurantId: r.id,
        name: 'Nasi Goreng Spesial Telur & Ayam',
        price: priceAt(0.55),
        category: 'Menu Utama',
        description: 'Nasi goreng bumbu tradisional dengan acar dan kerupuk',
        createdAt: DateTime.now(),
      ),
      Food(
        id: 'dyn_${r.id}_2',
        restaurantId: r.id,
        name: 'Ayam Bumbu Bakar / Goreng Kremes',
        price: priceAt(0.70),
        category: 'Menu Utama',
        description: 'Potongan ayam bumbu rempah gurih khas rumah makan',
        createdAt: DateTime.now(),
      ),
      Food(
        id: 'dyn_${r.id}_3',
        restaurantId: r.id,
        name: 'Sayur Asem Segar / Capcay Kuah Hangat',
        price: priceAt(0.35),
        category: 'Pendamping',
        description: 'Sayuran segar pelengkap makan siang yang nikmat',
        createdAt: DateTime.now(),
      ),
      Food(
        id: 'dyn_${r.id}_4',
        restaurantId: r.id,
        name: 'Es Teh Manis / Es Jeruk Peras',
        price: math.max(4000, priceAt(0.18)),
        category: 'Minuman',
        description: 'Minuman dingin penyegar dahaga',
        createdAt: DateTime.now(),
      ),
    ];
  }

  // ─── FAVORITES ───

  Future<List<String>> getFavoriteIds() async {
    if (!_initialized) await initStorage();
    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        final res = await _client
            .from('favorites')
            .select('restaurant_id')
            .eq('user_id', uid);
        final list =
            (res as List).map((e) => e['restaurant_id'].toString()).toList();
        _localFavorites.addAll(list);
        await _persistFavorites();
      } catch (_) {}
    }
    return _localFavorites.toList();
  }

  Future<List<Restaurant>> getFavoriteRestaurants() async {
    final favIds = await getFavoriteIds();
    final allRestos = await getRestaurants();

    // Petakan seluruh restoran baik dari database maupun seed data
    final Map<String, Restaurant> restoMap = {};
    for (final r in kDefaultRestaurants) {
      restoMap[r.id] = r;
      if (r.id.startsWith('resto_')) {
        restoMap[r.id.replaceFirst('resto_', '')] = r;
      }
    }
    for (final r in allRestos) {
      restoMap[r.id] = r;
      if (r.id.startsWith('resto_')) {
        restoMap[r.id.replaceFirst('resto_', '')] = r;
      } else {
        restoMap['resto_${r.id}'] = r;
      }
    }

    final result = <Restaurant>[];
    final validFavIds = <String>{};

    for (final favId in favIds) {
      Restaurant? r = restoMap[favId];
      if (r == null) {
        r = await getRestaurant(favId);
        if (r == null) {
          final altId = favId.startsWith('resto_')
              ? favId.replaceFirst('resto_', '')
              : 'resto_$favId';
          r = await getRestaurant(altId);
        }
      }

      if (r != null) {
        if (!result.any((item) => item.id == r!.id || item.name.toLowerCase() == r.name.toLowerCase())) {
          result.add(r);
        }
        validFavIds.add(favId);
      }
    }

    // Bersihkan ID phantom jika ada agar jumlah favorit selalu akurat dan sinkron
    if (validFavIds.length != _localFavorites.length && validFavIds.isNotEmpty) {
      _localFavorites.clear();
      _localFavorites.addAll(validFavIds);
      await _persistFavorites();
    }

    return result;
  }

  Future<bool> isFavorite(String restaurantId) async {
    if (_localFavorites.contains(restaurantId)) return true;
    final uid = userId;
    if (uid == null) return false;
    try {
      final res = await _client
          .from('favorites')
          .select('restaurant_id')
          .eq('user_id', uid)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();
      if (res != null) {
        _localFavorites.add(restaurantId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> toggleFavorite(String restaurantId) async {
    final isFav = _localFavorites.contains(restaurantId);
    if (isFav) {
      _localFavorites.remove(restaurantId);
    } else {
      _localFavorites.add(restaurantId);
    }
    _persistFavorites();
    _favoritesController.add(Set<String>.from(_localFavorites));
    _profileChangedController.add(null);

    final uid = userId;
    if (uid == null) return;
    try {
      if (isFav) {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('restaurant_id', restaurantId);
      } else {
        await _client.from('favorites').insert({
          'user_id': uid,
          'restaurant_id': restaurantId,
        });
      }
    } catch (_) {}
  }

  // ─── REVIEWS ───

  Future<List<Review>> getReviews(String restaurantId) async {
    List<Review> remote = [];
    final parsedId = int.tryParse(restaurantId);
    try {
      dynamic res;
      try {
        res = await _client
            .from('reviews')
            .select('*')
            .or('restaurant_id.eq.${parsedId ?? -999999},restaurant_id.eq.$restaurantId')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (_) {
        res = await _client
            .from('reviews')
            .select('*')
            .eq('restaurant_id', parsedId ?? restaurantId)
            .order('created_at', ascending: false)
            .limit(50);
      }

      final rawList = res as List;

      // Kumpulkan user_id dari seluruh ulasan untuk sinkronisasi nama, avatar, dan border aktif terkini
      final userIds = rawList
          .map((e) => e['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty && id != 'guest')
          .toSet()
          .cast<String>()
          .toList();

      final Map<String, String> userNames = {};
      final Map<String, String> userAvatars = {};
      final Map<String, String> userBorders = {};
      if (userIds.isNotEmpty) {
        try {
          final profileRes = await _client
              .from('profiles')
              .select('id, display_name, avatar_url, active_border_id')
              .inFilter('id', userIds);
          for (final p in profileRes as List) {
            final uid = p['id']?.toString() ?? '';
            final name = p['display_name']?.toString();
            final av = p['avatar_url']?.toString();
            final border = p['active_border_id']?.toString();
            if (uid.isNotEmpty && name != null && name.isNotEmpty) {
              userNames[uid] = name;
            }
            if (uid.isNotEmpty && av != null && av.isNotEmpty) {
              userAvatars[uid] = av;
            }
            if (uid.isNotEmpty && border != null && border.isNotEmpty) {
              userBorders[uid] = border;
            }
          }
        } catch (_) {}
      }

      // Jika user saat ini ada di ulasan dan punya border aktif lokal, gunakan untuk ulasannya
      final currentUid = userId;
      if (currentUid != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final localBorder = prefs.getString('foodie_active_border_$currentUid');
          if (localBorder != null && localBorder.isNotEmpty) {
            userBorders[currentUid] = localBorder;
          }
        } catch (_) {}
      }

      // Gabungkan nama, avatar, & border aktif terkini ke setiap review
      remote = rawList.map((e) {
        final uid = e['user_id']?.toString() ?? '';
        return Review.fromJson({
          ...e,
          'user_name': e['user_name'] ?? userNames[uid] ?? 'Kurator Rasa',
          'user_avatar': e['user_avatar'] ?? userAvatars[uid],
          'user_active_border': userBorders[uid] ?? e['user_active_border'],
        });
      }).toList();
    } catch (_) {}

    final defaultList = kDefaultReviews[restaurantId] ?? [];
    final localList = _localReviews.where((r) =>
        r.restaurantId == restaurantId ||
        r.restaurantId == 'resto_$restaurantId' ||
        (restaurantId.startsWith('resto_') &&
            r.restaurantId == restaurantId.replaceFirst('resto_', ''))).toList();

    final all = [...localList, ...remote, ...defaultList];
    final seen = <String>{};
    return all.where((r) => seen.add(r.id)).toList();
  }

  Future<Review> addReview({
    required String restaurantId,
    required int rating,
    required String comment,
  }) async {
    final profile = await getProfile();
    final name = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName.trim()
        : (currentUser?.userMetadata?['name'] as String? ?? guestName);
    final avatar = profile?.avatarUrl ??
        (currentUser?.userMetadata?['avatar_url'] as String?);
    final activeBorder = profile?.activeBorderId;

    final resto = await getRestaurant(restaurantId) ??
        kDefaultRestaurants.where((r) =>
            r.id == restaurantId ||
            r.id == 'resto_$restaurantId' ||
            (restaurantId.startsWith('resto_') &&
                r.id == restaurantId.replaceFirst('resto_', ''))).firstOrNull;

    final resolvedRestoName = resto?.name ?? 'Tempat Kuliner';
    final uuid = _generateUuid();
    final uid = userId;

    final rev = Review(
      id: 'rev_local_$uuid',
      userId: uid ?? 'guest',
      restaurantId: restaurantId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      userName: name,
      userAvatar: avatar,
      userActiveBorder: activeBorder,
      restaurantName: resolvedRestoName,
    );

    _localReviews.insert(0, rev);
    _localBonusPoints += 20;
    await _persistReviews();
    await _persistPoints();

    _reviewAddedController.add(rev);
    _reviewsChangedController.add(restaurantId);
    _profileChangedController.add(null);

    if (uid != null && uid != 'guest') {
      await _insertReviewToSupabase(
        uuid: uuid,
        uid: uid,
        restaurantId: restaurantId,
        rating: rating,
        comment: comment,
        userName: name,
        userAvatar: avatar,
        userActiveBorder: activeBorder,
      );
    }

    return rev;
  }

  Future<void> _insertReviewToSupabase({
    required String uuid,
    required String uid,
    required String restaurantId,
    required int rating,
    required String comment,
    String? userName,
    String? userAvatar,
    String? userActiveBorder,
  }) async {
    final parsedId = int.tryParse(restaurantId);
    // 1. Try with user_name, user_avatar, user_active_border, comment + parsed numeric id
    try {
      final payload = <String, dynamic>{
        'client_uuid': uuid,
        'user_id': uid,
        'restaurant_id': parsedId ?? restaurantId,
        'rating': rating,
        'comment': comment,
      };
      if (userName != null && userName.isNotEmpty) payload['user_name'] = userName;
      if (userAvatar != null && userAvatar.isNotEmpty) payload['user_avatar'] = userAvatar;
      if (userActiveBorder != null && userActiveBorder.isNotEmpty) payload['user_active_border'] = userActiveBorder;
      await _client.from('reviews').insert(payload);
      return;
    } catch (_) {}

    // 2. Try with user_name, user_avatar, content + parsed numeric id
    try {
      final payload = <String, dynamic>{
        'client_uuid': uuid,
        'user_id': uid,
        'restaurant_id': parsedId ?? restaurantId,
        'rating': rating,
        'content': comment,
      };
      if (userName != null && userName.isNotEmpty) payload['user_name'] = userName;
      if (userAvatar != null && userAvatar.isNotEmpty) payload['user_avatar'] = userAvatar;
      await _client.from('reviews').insert(payload);
      return;
    } catch (_) {}

    // 3. Fallback without user_name/avatar if schema columns were missing
    try {
      await _client.from('reviews').insert({
        'client_uuid': uuid,
        'user_id': uid,
        'restaurant_id': parsedId ?? restaurantId,
        'rating': rating,
        'comment': comment,
      });
      return;
    } catch (_) {}

    // 4. Try with content + raw restaurantId
    try {
      await _client.from('reviews').insert({
        'user_id': uid,
        'restaurant_id': restaurantId,
        'rating': rating,
        'content': comment,
      });
      return;
    } catch (_) {}
  }

  // ─── CHECKINS ───

  /// Generate UUID v4 secara manual (tanpa package tambahan)
  String _generateUuid() {
    final rng = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  Future<List<Checkin>> getCheckins() async {
    if (!_initialized) await initStorage();
    List<Checkin> remote = [];
    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        dynamic res;
        try {
          res = await _client
              .from('checkins')
              .select('*, restaurants(name)')
              .eq('user_id', uid)
              .order('created_at', ascending: false);
        } catch (_) {
          res = await _client
              .from('checkins')
              .select('*')
              .eq('user_id', uid)
              .order('created_at', ascending: false);
        }
        remote = (res as List).map((e) => Checkin.fromJson(e)).toList();
      } catch (_) {}
    }

    final all = [..._localCheckins, ...remote];
    final seen = <String>{};
    return all.where((c) => seen.add(c.id)).toList();
  }

  Future<Checkin?> performCheckin({
    required String restaurantId,
    required double lat,
    required double lng,
    required bool verified,
  }) async {
    final resto = await getRestaurant(restaurantId);
    final checkin = Checkin(
      id: 'chk_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'guest',
      restaurantId: restaurantId,
      lat: lat,
      lng: lng,
      verified: verified,
      createdAt: DateTime.now(),
      restaurantName: resto?.name ?? 'Restoran Kuliner',
    );

    _localCheckins.insert(0, checkin);
    _localBonusPoints += 50;
    _persistCheckins();
    _persistPoints();

    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        await _client.from('checkins').insert({
          'user_id': uid,
          'restaurant_id': restaurantId,
          'lat': lat,
          'lng': lng,
          'verified': verified,
        });
      } catch (_) {}
    }

    return checkin;
  }

  // ─── SEARCH HISTORY ───

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    if (!_initialized) await initStorage();
    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        final res = await _client
            .from('search_history')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(20);
        final list = List<Map<String, dynamic>>.from(res);
        for (final item in list) {
          final q = item['query'] as String? ?? '';
          if (q.isNotEmpty &&
              !_localSearchHistory.any((l) => l['query'] == q)) {
            _localSearchHistory.add(item);
          }
        }
        await _persistHistory();
        return list;
      } catch (_) {}
    }
    return _localSearchHistory;
  }

  Future<void> saveSearch(String query) async {
    _localSearchHistory.removeWhere((item) => item['query'] == query);
    _localSearchHistory.insert(0, {
      'id': 'sh_${DateTime.now().millisecondsSinceEpoch}',
      'query': query,
      'created_at': DateTime.now().toIso8601String(),
    });
    _persistHistory();

    final uid = userId;
    if (uid == null || uid == 'guest') return;
    try {
      await _client.from('search_history').insert({
        'user_id': uid,
        'query': query,
      });
    } catch (_) {}
  }

  Future<void> removeSearchItem(String query) async {
    _localSearchHistory.removeWhere((item) => item['query'] == query);
    _persistHistory();
    final uid = userId;
    if (uid == null || uid == 'guest') return;
    try {
      await _client
          .from('search_history')
          .delete()
          .eq('user_id', uid)
          .eq('query', query);
    } catch (_) {}
  }

  Future<void> clearSearchHistory() async {
    _localSearchHistory.clear();
    _persistHistory();
    final uid = userId;
    if (uid == null || uid == 'guest') return;
    try {
      await _client.from('search_history').delete().eq('user_id', uid);
    } catch (_) {}
  }

  // ─── USER REVIEWS (ulasan milik user ini) ───

  Future<List<Review>> getUserReviews() async {
    if (!_initialized) await initStorage();
    final uid = userId;

    // Gabungkan ulasan lokal pada perangkat ini & pastikan nama restoran selalu terisi
    final local = <Review>[];
    for (final r in _localReviews) {
      if (uid == null || uid == 'guest' || r.userId == uid || r.userId == 'guest' || r.userId.isEmpty) {
        String? rName = r.restaurantName;
        if (rName == null || rName.isEmpty || rName == r.restaurantId) {
          final found = kDefaultRestaurants.where((x) =>
              x.id == r.restaurantId ||
              x.id == 'resto_${r.restaurantId}' ||
              (r.restaurantId.startsWith('resto_') &&
                  x.id == r.restaurantId.replaceFirst('resto_', ''))).firstOrNull;
          rName = found?.name ?? 'Tempat Kuliner';
        }
        local.add(r.copyWith(restaurantName: rName));
      }
    }

    if (uid != null && uid != 'guest') {
      try {
        dynamic res;
        try {
          res = await _client
              .from('reviews')
              .select('*, restaurants(name)')
              .eq('user_id', uid)
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {
          res = await _client
              .from('reviews')
              .select('*')
              .eq('user_id', uid)
              .order('created_at', ascending: false)
              .limit(50);
        }

        final remote = <Review>[];
        for (final item in (res as List)) {
          final map = Map<String, dynamic>.from(item as Map);
          final rev = Review.fromJson(map);
          String? name = rev.restaurantName;
          if (name == null || name.isEmpty || name == rev.restaurantId) {
            final resto = await getRestaurant(rev.restaurantId) ??
                kDefaultRestaurants.where((x) =>
                    x.id == rev.restaurantId ||
                    x.id == 'resto_${rev.restaurantId}' ||
                    (rev.restaurantId.startsWith('resto_') &&
                        x.id == rev.restaurantId.replaceFirst('resto_', ''))).firstOrNull;
            name = resto?.name ?? 'Tempat Kuliner';
          }
          remote.add(rev.copyWith(restaurantName: name));
        }

        // Sinkronkan ulasan remote ke cache lokal jika belum ada
        for (final r in remote) {
          final exists = _localReviews.any((l) =>
              l.id == r.id ||
              (l.restaurantId == r.restaurantId && l.comment == r.comment));
          if (!exists) {
            _localReviews.add(r);
          }
        }

        // Migrasikan ulasan lokal guest ke akun pengguna di Supabase
        for (final l in local) {
          if (l.userId == 'guest' || l.userId.isEmpty) {
            _insertReviewToSupabase(
              uuid: _generateUuid(),
              uid: uid,
              restaurantId: l.restaurantId,
              rating: l.rating,
              comment: l.comment,
            ).catchError((_) {});
          }
        }

        await _persistReviews();

        final all = [...local, ...remote];
        final seen = <String>{};
        return all.where((r) => seen.add(r.id)).toList();
      } catch (e) {
        debugPrint('getUserReviews error: $e');
      }
    }
    return local;
  }

  // ─── GAME SCORES ───

  Future<int> getTotalGameScore() async {
    int total = 0;
    final uid = userId;
    if (uid != null) {
      try {
        final res = await _client
            .from('game_scores')
            .select('score')
            .eq('user_id', uid);
        for (final row in res as List) {
          total += (row['score'] as int? ?? 0);
        }
      } catch (_) {}
    }
    return total + _localBonusPoints;
  }

  Future<void> saveGameScore(int score) async {
    _localBonusPoints += score;
    _persistPoints();
    final uid = userId;
    if (uid == null) return;
    try {
      await _client.from('game_scores').insert({
        'user_id': uid,
        'score': score,
      });
    } catch (_) {}
  }

  // ─── REDEEM VOUCHER ───

  Future<bool> redeemPoints(int cost) async {
    final profile = await getProfile();
    final points = profile?.points ?? 0;
    if (points < cost) return false;
    _localBonusPoints -= cost;
    _persistPoints();
    return true;
  }

  // ─── FEEDBACK ───

  Future<void> submitFeedback({
    required int rating,
    required String message,
  }) async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _client.from('feedback').insert({
        'user_id': uid,
        'rating': rating,
        'message': message,
      });
    } catch (_) {}
  }

  // ─── COURSE FEEDBACK (MATA KULIAH PEMROGRAMAN APLIKASI MOBILE) ───

  Future<List<CourseFeedback>> getCourseFeedbacks() async {
    try {
      final res = await _client
          .from('course_feedback')
          .select('*, profiles:user_id(display_name, avatar_url)')
          .order('created_at', ascending: false);
      final list = (res as List)
          .map((e) => CourseFeedback.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      debugPrint('getCourseFeedbacks fallback to simple select: $e');
      try {
        final res = await _client
            .from('course_feedback')
            .select()
            .order('created_at', ascending: false);
        return (res as List)
            .map((e) => CourseFeedback.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (err) {
        debugPrint('getCourseFeedbacks fallback to local: $err');
        return _getLocalCachedFeedbacks();
      }
    }
  }

  Future<CourseFeedback?> submitCourseFeedback({
    required String kesan,
    required String saran,
    int rating = 5,
  }) async {
    final uid = userId ?? 'guest_mhs';
    final profile = await getProfile();
    final name = profile?.displayName ??
        currentUser?.userMetadata?['name'] as String? ??
        guestName;
    final avatar = profile?.avatarUrl ??
        currentUser?.userMetadata?['avatar_url'] as String?;

    final Map<String, dynamic> payload = {
      'user_id': uid,
      'user_name': name,
      'user_avatar': avatar,
      'kesan': kesan,
      'saran': saran,
      'rating': rating,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    CourseFeedback? created;
    try {
      final res = await _client
          .from('course_feedback')
          .insert(payload)
          .select()
          .single();
      created = CourseFeedback.fromJson(res);
      _courseFeedbackAddedController.add(created);
    } catch (e) {
      debugPrint('submitCourseFeedback error in supabase: $e');
      created = CourseFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: uid,
        userName: name,
        userAvatar: avatar,
        kesan: kesan,
        saran: saran,
        rating: rating,
        createdAt: DateTime.now(),
      );
      _courseFeedbackAddedController.add(created);
      await _cacheLocalFeedback(created);
    }
    return created;
  }

  Future<List<CourseFeedback>> _getLocalCachedFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = prefs.getStringList('local_course_feedbacks') ?? [];
      strList.removeWhere((s) => s.contains('sample_'));
      return strList
          .map((s) => CourseFeedback.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CourseFeedback?> updateCourseFeedback({
    required String id,
    required String kesan,
    required String saran,
    required int rating,
  }) async {
    final Map<String, dynamic> payload = {
      'kesan': kesan,
      'saran': saran,
      'rating': rating,
    };

    CourseFeedback? updated;
    try {
      final res = await _client
          .from('course_feedback')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      updated = CourseFeedback.fromJson(res);
      _courseFeedbackAddedController.add(updated);
    } catch (e) {
      debugPrint('updateCourseFeedback error in supabase: $e');
    }

    await _updateLocalCachedFeedback(id, kesan, saran, rating);
    return updated;
  }

  Future<bool> deleteCourseFeedback(String id) async {
    bool ok = false;
    try {
      await _client.from('course_feedback').delete().eq('id', id);
      ok = true;
    } catch (e) {
      debugPrint('deleteCourseFeedback error in supabase: $e');
    }
    await _deleteLocalCachedFeedback(id);
    return ok;
  }

  Future<void> _updateLocalCachedFeedback(
      String id, String kesan, String saran, int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getLocalCachedFeedbacks();
      final idx = current.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final old = current[idx];
        current[idx] = CourseFeedback(
          id: old.id,
          userId: old.userId,
          userName: old.userName,
          userAvatar: old.userAvatar,
          kesan: kesan,
          saran: saran,
          rating: rating,
          createdAt: old.createdAt,
        );
        final jsonList = current.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList('local_course_feedbacks', jsonList);
      }
    } catch (_) {}
  }

  Future<void> _deleteLocalCachedFeedback(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getLocalCachedFeedbacks();
      current.removeWhere((e) => e.id == id);
      final jsonList = current.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('local_course_feedbacks', jsonList);
    } catch (_) {}
  }

  Future<void> _cacheLocalFeedback(CourseFeedback fb) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getLocalCachedFeedbacks();
      current.insert(0, fb);
      final jsonList = current.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('local_course_feedbacks', jsonList);
    } catch (_) {}
  }

  // ─── STATS ───

  Future<Map<String, int>> getUserStats() async {
    if (!_initialized) await initStorage();
    final favList = await getFavoriteRestaurants();
    int favCount = favList.length;
    int checkinCount = _localCheckins.length;

    final userRevs = await getUserReviews();
    int reviewCount = userRevs.length;

    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        final checks =
            await _client.from('checkins').select('id').eq('user_id', uid);
        checkinCount = math.max(checkinCount, (checks as List).length);
      } catch (_) {}
    }

    return {
      'favorites': favCount,
      'checkins': checkinCount,
      'reviews': reviewCount,
    };
  }
}
