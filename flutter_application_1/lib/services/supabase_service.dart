import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
    _initStorage();
    _initRealtime();
  }
  static final instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isGuest => currentUser == null;

  String guestName = 'Tamu Mataraman';

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

  void _initRealtime() {
    try {
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

  Future<void> _initStorage() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = userId ?? 'guest';

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
        _localSearchHistory.clear();
        for (final item in historyRaw) {
          try {
            _localSearchHistory.add(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {}
        }
      }

      // Load checkins
      final checkinsRaw = prefs.getStringList('foodie_chk_$uid');
      if (checkinsRaw != null) {
        _localCheckins.clear();
        for (final item in checkinsRaw) {
          try {
            _localCheckins.add(Checkin.fromJson(jsonDecode(item) as Map<String, dynamic>));
          } catch (_) {}
        }
      }

      // Load reviews
      final reviewsRaw = prefs.getStringList('foodie_rev_$uid');
      if (reviewsRaw != null) {
        _localReviews.clear();
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
    guestName = 'Tamu Mataraman';
    _initialized = false;
    await _client.auth.signOut();
  }

  // ─── PROFILES ───

  Future<Profile?> getProfile() async {
    final uid = userId;
    if (uid != null) {
      try {
        final res = await _client
            .from('profiles')
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (res != null) {
          final p = Profile.fromJson(res);
          return Profile(
            id: p.id,
            displayName: p.displayName,
            avatarUrl: p.avatarUrl,
            points: p.points + _localBonusPoints,
            createdAt: p.createdAt,
          );
        }
      } catch (_) {}
    }

    final name = currentUser?.userMetadata?['name'] as String? ?? guestName;
    return Profile(
      id: uid ?? 'guest_user',
      displayName: name,
      points: 100 + _localBonusPoints + (_localCheckins.length * 50),
      createdAt: DateTime.now(),
    );
  }

  Future<void> upsertProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final uid = userId;
    if (uid == null) {
      guestName = displayName;
      return;
    }
    try {
      final payload = <String, dynamic>{
        'id': uid,
        'display_name': displayName,
      };
      if (avatarUrl != null) {
        payload['avatar_url'] = avatarUrl;
      }
      await _client.from('profiles').upsert(payload, onConflict: 'id');
    } catch (_) {}
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
      final res = await _client.from('categories').select('name');
      final list = (res as List).map((e) => e['name'] as String).toList();
      if (list.isNotEmpty) return list;
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
    final uid = userId;
    if (uid != null) {
      try {
        final res = await _client
            .from('favorites')
            .select('restaurant_id')
            .eq('user_id', uid);
        final list =
            (res as List).map((e) => e['restaurant_id'].toString()).toList();
        _localFavorites.addAll(list);
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
      final res = await _client
          .from('reviews')
          .select('*, profiles(display_name)')
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false)
          .limit(20);
      remote = (res as List).map((e) => Review.fromJson(e)).toList();
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
    final rev = Review(
      id: 'rev_local_${DateTime.now().millisecondsSinceEpoch}',
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
    if (uid != null) {
      try {
        await _client.from('reviews').insert({
          'user_id': uid,
          'restaurant_id': restaurantId,
          'rating': rating,
          'comment': comment,
        });
      } catch (_) {}
    }

    return rev;
  }

  // ─── CHECKINS ───

  Future<List<Checkin>> getCheckins() async {
    List<Checkin> remote = [];
    final uid = userId;
    if (uid != null) {
      try {
        final res = await _client
            .from('checkins')
            .select('*, restaurants(name)')
            .eq('user_id', uid)
            .order('created_at', ascending: false);
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
    if (uid != null) {
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
    final uid = userId;
    if (uid != null) {
      try {
        final res = await _client
            .from('search_history')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(20);
        return List<Map<String, dynamic>>.from(res);
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
    if (uid == null) return;
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
    if (uid == null) return;
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
    if (uid == null) return;
    try {
      await _client.from('search_history').delete().eq('user_id', uid);
    } catch (_) {}
  }

  // ─── USER REVIEWS (ulasan milik user ini) ───

  Future<List<Review>> getUserReviews() async {
    final uid = userId;
    // Gabungkan ulasan lokal milik user ini
    final local = _localReviews
        .where((r) => r.userId == (uid ?? 'guest'))
        .toList();

    if (uid != null) {
      try {
        final res = await _client
            .from('reviews')
            .select('*, restaurants(name)')
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(30);
        final remote =
            (res as List).map((e) => Review.fromJson(e)).toList();
        final all = [...local, ...remote];
        final seen = <String>{};
        return all.where((r) => seen.add(r.id)).toList();
      } catch (_) {}
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
    int favCount = _localFavorites.length;
    int checkinCount = _localCheckins.length;
    int reviewCount = _localReviews.length;

    final uid = userId;
    if (uid != null) {
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
