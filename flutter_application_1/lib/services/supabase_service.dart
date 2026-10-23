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

class SupabaseService {
  SupabaseService._() {
    initStorage();
    _initRealtime();
    _initAuthListener();
  }
  static final instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  String? _demoUserId;
  void setDemoUser(String? id) => _demoUserId = id;
  String? get userId => currentUser?.id ?? _demoUserId;
  String curatorName = 'Dimas Dananjaya';
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
      _authSub?.cancel();
      _authSub = _client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          await initStorage(force: true);
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

      // Selalu cek backup ulasan perangkat & ulasan tamu agar tidak hilang saat logout/login
      final globalRaw = prefs.getStringList('foodie_all_device_reviews');
      if (globalRaw != null) {
        for (final item in globalRaw) {
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
      // Simpan juga ke global key perangkat agar tetap ada setelah logout
      await prefs.setStringList('foodie_all_device_reviews', list);
    } catch (_) {}
  }

  Future<void> signOut() async {
    _reviewsChannel?.unsubscribe();
    _favoritesChannel?.unsubscribe();
    _reviewsChannel = null;
    _favoritesChannel = null;
    _localFavorites.clear();
    _localCheckins.clear();
    _localReviews.clear();
    _localSearchHistory.clear();
    _localBonusPoints = 0;
    _demoUserId = null;
    curatorName = 'Dimas Dananjaya';
    _initialized = false;
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  // ─── PROFILES ───

  Future<Profile?> getProfile() async {
    final uid = userId;
    final keyUid = uid ?? 'guest';
    String? localName;
    String? localAvatar;
    bool isAvatarDeleted = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      localName = prefs.getString('foodie_name_$keyUid') ??
          prefs.getString('foodie_current_display_name') ??
          prefs.getString('foodie_last_user_name');
      localAvatar = prefs.getString('foodie_avatar_$keyUid');
      isAvatarDeleted = prefs.getBool('foodie_avatar_deleted_$keyUid') ?? false;
    } catch (_) {}

    final metaAvatar = isAvatarDeleted
        ? null
        : (currentUser?.userMetadata?['avatar_url'] as String?);

    if (uid != null) {
      try {
        final res = await _client
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

          // PRIORITASKAN localName jika pengguna telah mengedit namanya di perangkat
          final effectiveName = (localName != null && localName.trim().isNotEmpty)
              ? localName.trim()
              : p.displayName.trim().isNotEmpty
                  ? p.displayName.trim()
                  : (currentUser?.userMetadata?['name'] as String? ?? curatorName);

          return Profile(
            id: p.id,
            displayName: effectiveName,
            avatarUrl: effectiveAvatar,
            points: p.points + _localBonusPoints,
            createdAt: p.createdAt,
          );
        }
      } catch (e) {
        debugPrint('Supabase getProfile error: $e');
      }
    }

    final effectiveName = (localName != null && localName.trim().isNotEmpty)
        ? localName.trim()
        : (currentUser?.userMetadata?['name'] as String? ?? curatorName);

    final effectiveAvatar = isAvatarDeleted
        ? null
        : (localAvatar != null && localAvatar.isNotEmpty)
            ? localAvatar
            : metaAvatar;

    return Profile(
      id: uid ?? 'curator_user',
      displayName: effectiveName,
      avatarUrl: effectiveAvatar,
      points: 100 + _localBonusPoints + (_localCheckins.length * 50),
      createdAt: DateTime.now(),
    );
  }

  Future<void> upsertProfile({
    required String displayName,
    String? avatarUrl,
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

  Future<List<Food>> getFoods(String restaurantId) async {
    try {
      final res = await _client
          .from('foods')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('price', ascending: true);
      final list = (res as List).map((e) => Food.fromJson(e)).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return kDefaultFoods[restaurantId] ?? [];
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

      // Kumpulkan user_id jika ada ulasan lama yang belum memiliki user_name
      final userIds = rawList
          .where((e) => e['user_name'] == null || (e['user_name'] as String).isEmpty)
          .map((e) => e['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .cast<String>()
          .toList();

      final Map<String, String> userNames = {};
      final Map<String, String> userAvatars = {};
      if (userIds.isNotEmpty) {
        try {
          final profileRes = await _client
              .from('profiles')
              .select('id, display_name, avatar_url')
              .inFilter('id', userIds);
          for (final p in profileRes as List) {
            final uid = p['id']?.toString() ?? '';
            final name = p['display_name']?.toString();
            final av = p['avatar_url']?.toString();
            if (uid.isNotEmpty && name != null && name.isNotEmpty) {
              userNames[uid] = name;
            }
            if (uid.isNotEmpty && av != null && av.isNotEmpty) {
              userAvatars[uid] = av;
            }
          }
        } catch (_) {}
      }

      // Gabungkan nama & avatar ke setiap review
      remote = rawList.map((e) {
        final uid = e['user_id']?.toString() ?? '';
        return Review.fromJson({
          ...e,
          'user_name': e['user_name'] ?? userNames[uid] ?? 'Kurator Rasa',
          'user_avatar': e['user_avatar'] ?? userAvatars[uid],
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
  }) async {
    final parsedId = int.tryParse(restaurantId);
    // 1. Try with user_name, user_avatar, comment + parsed numeric id
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
