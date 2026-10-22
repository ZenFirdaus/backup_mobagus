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

  RealtimeChannel? _reviewsChannel;
  RealtimeChannel? _favoritesChannel;
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
          _reviewsChannel = null;
          _favoritesChannel = null;
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
            _localReviews.add(Review.fromJson(jsonDecode(item) as Map<String, dynamic>));
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
        query = query.ilike('category', '%$category%');
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
      filtered = filtered
          .where((r) =>
              r.category.toLowerCase().contains(category.toLowerCase()))
          .toList();
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
    try {
      // 1. Coba ambil dari tabel categories
      final res = await _client.from('categories').select();
      if (res.isNotEmpty) {
        final list = res.map((m) {
          return (m['name'] ?? m['slug'] ?? m['category'] ?? '').toString();
        }).where((s) => s.isNotEmpty).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    try {
      // 2. Ambil kategori unik langsung dari data restaurants yang ada di Supabase
      final res = await _client.from('restaurants').select('category');
      if (res.isNotEmpty) {
        final set = <String>{};
        for (final row in res) {
          final cat = (row['category'] as String?)?.trim();
          if (cat != null && cat.isNotEmpty) {
            set.add(cat);
          }
        }
        if (set.isNotEmpty) {
          final sorted = set.toList()..sort();
          return sorted;
        }
      }
    } catch (_) {}

    return kDefaultCategories;
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
    return allRestos.where((r) => favIds.contains(r.id)).toList();
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
    try {
      // Ambil reviews tanpa join (karena foreign key profiles mungkin tidak ada)
      final res = await _client
          .from('reviews')
          .select('*')
          .eq('restaurant_id', int.tryParse(restaurantId) ?? restaurantId)
          .order('created_at', ascending: false)
          .limit(50);

      final rawList = res as List;

      // Kumpulkan semua user_id unik dari reviews yang masuk
      final userIds = rawList
          .map((e) => e['user_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet()
          .cast<String>()
          .toList();

      // Ambil nama display dari tabel profiles secara terpisah
      final Map<String, String> userNames = {};
      if (userIds.isNotEmpty) {
        try {
          final profileRes = await _client
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', userIds);
          for (final p in profileRes as List) {
            final uid = p['id']?.toString() ?? '';
            final name = p['display_name']?.toString();
            if (uid.isNotEmpty && name != null && name.isNotEmpty) {
              userNames[uid] = name;
            }
          }
        } catch (_) {}
      }

      // Gabungkan nama ke setiap review
      remote = rawList.map((e) {
        final uid = e['user_id']?.toString() ?? '';
        return Review.fromJson({
          ...e,
          'user_name': userNames[uid] ?? e['user_name'],
        });
      }).toList();
    } catch (_) {}

    final defaultList = kDefaultReviews[restaurantId] ?? [];
    final localList =
        _localReviews.where((r) => r.restaurantId == restaurantId).toList();

    final all = [...localList, ...remote, ...defaultList];
    final seen = <String>{};
    return all.where((r) => seen.add(r.id)).toList();
  }

  Future<Review> addReview({
    required String restaurantId,
    required int rating,
    required String comment,
  }) async {
    final name = currentUser?.userMetadata?['name'] as String? ?? guestName;
    final resto = await getRestaurant(restaurantId);
    final uuid = _generateUuid();
    final rev = Review(
      id: 'rev_local_$uuid',
      userId: userId ?? 'guest',
      restaurantId: restaurantId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      userName: name,
      restaurantName: resto?.name,
    );
    _localReviews.insert(0, rev);
    _localBonusPoints += 20;
    _persistReviews();
    _persistPoints();

    _reviewAddedController.add(rev);
    _reviewsChangedController.add(restaurantId);
    _profileChangedController.add(null);

    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        await _client.from('reviews').insert({
          'client_uuid': uuid,
          'user_id': uid,
          'restaurant_id': int.tryParse(restaurantId) ?? restaurantId,
          'rating': rating,
          'comment': comment,
        });
      } catch (e1) {
        try {
          // Fallback bila kolom teks di Supabase adalah 'content'
          await _client.from('reviews').insert({
            'client_uuid': uuid,
            'user_id': uid,
            'restaurant_id': int.tryParse(restaurantId) ?? restaurantId,
            'rating': rating,
            'content': comment,
          });
        } catch (e2) {
          try {
            // Fallback bila kolom client_uuid tidak ada
            await _client.from('reviews').insert({
              'user_id': uid,
              'restaurant_id': int.tryParse(restaurantId) ?? restaurantId,
              'rating': rating,
              'content': comment,
            });
          } catch (e3) {
            debugPrint('Reviews insert to Supabase: $e3');
          }
        }
      }
    }

    return rev;
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
    // Gabungkan ulasan lokal milik user ini
    final local = _localReviews
        .where((r) => r.userId == (uid ?? 'guest'))
        .toList();

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
          if (rev.restaurantName == null || rev.restaurantName!.isEmpty) {
            final resto = await getRestaurant(rev.restaurantId);
            remote.add(Review(
              id: rev.id,
              userId: rev.userId,
              restaurantId: rev.restaurantId,
              rating: rev.rating,
              comment: rev.comment,
              createdAt: rev.createdAt,
              userName: rev.userName,
              restaurantName: resto?.name,
            ));
          } else {
            remote.add(rev);
          }
        }

        for (final r in remote) {
          final exists = _localReviews.any((l) =>
              l.id == r.id ||
              (l.restaurantId == r.restaurantId &&
                  l.userId == r.userId &&
                  l.comment == r.comment));
          if (!exists) {
            _localReviews.add(r);
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

  // ─── STATS ───

  Future<Map<String, int>> getUserStats() async {
    if (!_initialized) await initStorage();
    int favCount = _localFavorites.length;
    int checkinCount = _localCheckins.length;
    int reviewCount = _localReviews.length;

    final uid = userId;
    if (uid != null && uid != 'guest') {
      try {
        final favs = await _client
            .from('favorites')
            .select('restaurant_id')
            .eq('user_id', uid);
        final checks =
            await _client.from('checkins').select('id').eq('user_id', uid);
        final revs =
            await _client.from('reviews').select('id').eq('user_id', uid);
        favCount = math.max(favCount, (favs as List).length);
        checkinCount = math.max(checkinCount, (checks as List).length);
        reviewCount = math.max(reviewCount, (revs as List).length);
      } catch (_) {}
    }

    return {
      'favorites': favCount,
      'checkins': checkinCount,
      'reviews': reviewCount,
    };
  }
}
