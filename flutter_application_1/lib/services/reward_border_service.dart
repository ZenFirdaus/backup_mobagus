import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reward_border.dart';
import '../models/point_transaction.dart';
import 'blockchain_service.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

class RewardBorderService {
  RewardBorderService._() {
    _initStorage();
  }
  static final instance = RewardBorderService._();

  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  Stream<void> get onRewardsChanged => _changeController.stream;
  Stream<void> get onChange => _changeController.stream;

  List<RewardBorder> _cachedBorders = [];
  Set<String> _localOwnedBorderIds = {};
  String? _localActiveBorderId;
  int _localPoints = 100;
  bool _initialized = false;
  String? _lastLoadedUserId;

  SupabaseClient? get _safeClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _getEffectiveUserId() {
    try {
      final supaUid = _safeClient?.auth.currentUser?.id;
      if (supaUid != null && supaUid.isNotEmpty) return supaUid;
    } catch (_) {}
    try {
      final demoUid = SupabaseService.instance.userId;
      if (demoUid != null && demoUid.isNotEmpty) return demoUid;
    } catch (_) {}
    return 'guest';
  }

  Future<void> _initStorage([bool force = false]) async {
    final uid = _getEffectiveUserId();
    if (_initialized && _lastLoadedUserId == uid && !force) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _localPoints = prefs.getInt('foodie_points_$uid') ??
          prefs.getInt('foodie_points_global') ??
          100;

      final allLocalBorders = <String>{};
      final userList = prefs.getStringList('foodie_owned_borders_$uid');
      if (userList != null) allLocalBorders.addAll(userList);
      final globalList = prefs.getStringList('foodie_owned_borders_global');
      if (globalList != null) allLocalBorders.addAll(globalList);
      final guestList = prefs.getStringList('foodie_owned_borders_guest');
      if (guestList != null) allLocalBorders.addAll(guestList);
      final localUserList = prefs.getStringList('foodie_owned_borders_local_user');
      if (localUserList != null) allLocalBorders.addAll(localUserList);

      // Ambil dari Hive NoSQL
      final hiveBorders = HiveService.instance.getOwnedBorderIds(uid);
      allLocalBorders.addAll(hiveBorders);

      // Ambil dari Supabase User Metadata (Cloud)
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.userMetadata?['foodie_owned_borders'] is List) {
        final cloudList = (currentUser!.userMetadata!['foodie_owned_borders'] as List);
        allLocalBorders.addAll(cloudList.map((e) => e.toString()));
      }

      _localOwnedBorderIds = allLocalBorders;
      _localActiveBorderId = prefs.getString('foodie_active_border_$uid') ??
          prefs.getString('foodie_active_border_global') ??
          HiveService.instance.getActiveBorderId(uid) ??
          currentUser?.userMetadata?['foodie_active_border_id']?.toString();

      _lastLoadedUserId = uid;
      _initialized = true;
    } catch (_) {}
  }

  /// Mengambil daftar 20 produk border (Supabase Cloud + Fallback Lokal)
  Future<List<RewardBorder>> getBorders() async {
    if (_cachedBorders.isNotEmpty) return _cachedBorders;

    try {
      final client = _safeClient;
      if (client != null) {
        final res = await client
            .from('reward_borders')
            .select()
            .eq('is_active', true)
            .order('price_points', ascending: true);

        if (res.isNotEmpty) {
          _cachedBorders = (res as List).map((item) => RewardBorder.fromJson(item)).toList();
          return _cachedBorders;
        }
      }
    } catch (e) {
      debugPrint('Fetch reward_borders from Supabase error, use default: $e');
    }

    _cachedBorders = RewardBorder.defaultBorders;
    return _cachedBorders;
  }

  /// Mengambil saldo poin pengguna secara real-time
  Future<int> getUserPoints() async {
    await _initStorage();
    final client = _safeClient;
    final uid = client?.auth.currentUser?.id;

    if (client != null && uid != null) {
      try {
        // Cek tabel user_points
        final res = await client
            .from('user_points')
            .select('balance')
            .eq('user_id', uid)
            .maybeSingle();

        if (res != null && res['balance'] != null) {
          final pts = (res['balance'] as num).toInt();
          _localPoints = pts;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('foodie_points_$uid', pts);
          return pts;
        }

        // Fallback ke tabel profiles
        final profRes = await client
            .from('profiles')
            .select('points')
            .eq('id', uid)
            .maybeSingle();

        if (profRes != null && profRes['points'] != null) {
          final pts = (profRes['points'] as num).toInt();
          _localPoints = pts;
          return pts;
        }
      } catch (e) {
        debugPrint('Fetch user points error: $e');
      }
    }

    return _localPoints;
  }

  /// Mengambil daftar ID border yang dimiliki pengguna (Multi-Layer Resilient: Prefs, Hive, Cloud Metadata, user_rewards)
  Future<Set<String>> getOwnedBorderIds() async {
    await _initStorage();
    final client = _safeClient;
    final uid = _getEffectiveUserId();

    // 1. Ambil dari cloud Supabase jika ada koneksi
    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client
            .from('user_rewards')
            .select('border_id, is_active')
            .eq('user_id', uid);

        for (final row in (res as List)) {
          final bid = row['border_id']?.toString();
          if (bid != null && bid.isNotEmpty) {
            _localOwnedBorderIds.add(bid);
            if (row['is_active'] == true && _localActiveBorderId == null) {
              _localActiveBorderId = bid;
            }
          }
        }
      } catch (e) {
        debugPrint('Fetch user_rewards error: $e');
      }

      // Ambil juga dari user_metadata Supabase
      try {
        final meta = client.auth.currentUser?.userMetadata;
        if (meta != null && meta['foodie_owned_borders'] is List) {
          final cloudList = (meta['foodie_owned_borders'] as List);
          _localOwnedBorderIds.addAll(cloudList.map((e) => e.toString()));
        }
        if (meta != null && meta['foodie_active_border_id'] != null && _localActiveBorderId == null) {
          _localActiveBorderId = meta['foodie_active_border_id'].toString();
        }
      } catch (_) {}
    }

    // 2. Ambil dari Hive NoSQL
    final hiveBorders = HiveService.instance.getOwnedBorderIds(uid);
    _localOwnedBorderIds.addAll(hiveBorders);

    // 3. Simpan balik seluruh koleksi gabungan ke penyimpanan lokal agar tahan logout
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _localOwnedBorderIds.toList();
      await prefs.setStringList('foodie_owned_borders_$uid', list);
      await prefs.setStringList('foodie_owned_borders_global', list);
      await HiveService.instance.saveOwnedBorderIds(_localOwnedBorderIds, uid);
      if (_localActiveBorderId != null) {
        await prefs.setString('foodie_active_border_$uid', _localActiveBorderId!);
        await prefs.setString('foodie_active_border_global', _localActiveBorderId!);
        await HiveService.instance.saveActiveBorderId(_localActiveBorderId, uid);
      }
    } catch (_) {}

    return _localOwnedBorderIds;
  }

  /// Mengambil ID border aktif yang sedang dipasang pengguna
  Future<String?> getActiveBorderId() async {
    await _initStorage();
    final client = _safeClient;
    final uid = _getEffectiveUserId();

    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client
            .from('profiles')
            .select('active_border_id')
            .eq('id', uid)
            .maybeSingle();

        if (res != null && res['active_border_id'] != null) {
          _localActiveBorderId = res['active_border_id'].toString();
          return _localActiveBorderId;
        }
      } catch (_) {}
    }

    return _localActiveBorderId;
  }

  /// Pembelian / Penukaran Border Profil dengan Poin
  /// (Dapat menukar lebih dari 1 border, semua tersimpan permanen di Koleksi)
  Future<Map<String, dynamic>> purchaseBorder(String borderId) async {
    await _initStorage(true);
    final client = _safeClient;
    final uid = _getEffectiveUserId();
    final borders = await getBorders();
    final border = borders.firstWhere(
      (b) => b.id == borderId,
      orElse: () => RewardBorder.defaultBorders.first,
    );

    // Cek apakah sudah ada di koleksi
    final owned = await getOwnedBorderIds();
    if (owned.contains(borderId)) {
      return {
        'success': false,
        'message': 'Border "${border.name}" sudah ada di koleksi Anda dan dapat langsung digunakan secara gratis!',
      };
    }

    // Cek kecukupan saldo poin
    final currentPoints = await getUserPoints();
    if (currentPoints < border.pricePoints) {
      return {
        'success': false,
        'message': 'Saldo Poin Rasa tidak mencukupi (${border.pricePoints} Poin Rasa dibutuhkan, Anda memiliki $currentPoints Poin Rasa)',
      };
    }

    final idempotencyKey = 'buy_${borderId}_${uid}_${DateTime.now().millisecondsSinceEpoch}';
    String? redemptionId;

    // 1. Eksekusi Supabase RPC Atomik jika terhubung
    bool rpcSuccess = false;
    if (client != null && client.auth.currentUser != null) {
      try {
        final rpcRes = await client.rpc('purchase_border_reward', params: {
          'p_border_id': borderId,
          'p_idempotency_key': idempotencyKey,
        });

        if (rpcRes is Map) {
          if (rpcRes['success'] == true) {
            rpcSuccess = true;
            redemptionId = rpcRes['redemption_id']?.toString();
            if (rpcRes['balance'] != null) {
              _localPoints = (rpcRes['balance'] as num).toInt();
            } else {
              _localPoints -= border.pricePoints;
            }
          } else {
            return {
              'success': false,
              'message': rpcRes['message']?.toString() ?? 'Pembelian ditolak oleh server',
            };
          }
        }
      } catch (e) {
        debugPrint('purchase_border_reward RPC call failed, fallback local: $e');
      }
    }

    // 2. Pemrosesan Poin & Penyimpanan Koleksi
    if (!rpcSuccess) {
      _localPoints = (_localPoints - border.pricePoints).clamp(0, 9999999);
      if (client != null && client.auth.currentUser != null) {
        try {
          await client.from('profiles').update({'points': _localPoints}).eq('id', uid);
          await client.from('user_rewards').upsert({
            'user_id': uid,
            'border_id': borderId,
            'is_active': false,
          });
        } catch (_) {}
      }
    }

    // Tambahkan ke koleksi (mendukung kepemilikan banyak border sekaligus)
    _localOwnedBorderIds.add(borderId);

    // Persist ke semua layer: SharedPreferences (user & global) & Hive NoSQL
    final prefs = await SharedPreferences.getInstance();
    final ownedList = _localOwnedBorderIds.toList();
    await prefs.setStringList('foodie_owned_borders_$uid', ownedList);
    await prefs.setStringList('foodie_owned_borders_global', ownedList);
    await prefs.setInt('foodie_points_$uid', _localPoints);
    await prefs.setInt('foodie_points_global', _localPoints);
    await HiveService.instance.saveOwnedBorderIds(_localOwnedBorderIds, uid);

    // Sinkronkan ke Supabase Cloud User Metadata
    if (client != null && client.auth.currentUser != null) {
      try {
        final existingMeta = client.auth.currentUser!.userMetadata ?? {};
        await client.auth.updateUser(
          UserAttributes(
            data: {
              ...existingMeta,
              'foodie_owned_borders': ownedList,
            },
          ),
        );
      } catch (_) {}
    }

    // 3. Catat bukti transaksi ke EVM Sepolia Blockchain Testnet
    try {
      final bTx = await BlockchainService.instance.recordBorderMintProof(
        borderId: borderId,
        pointsSpent: border.pricePoints,
        idempotencyKey: idempotencyKey,
        redemptionId: redemptionId,
      );
      debugPrint('Recorded Sepolia Blockchain TX: ${bTx.txHash}');
    } catch (e) {
      debugPrint('Blockchain recording error: $e');
    }

    // 4. Catat mutasi pengurangan poin secara lokal
    try {
      final pTx = PointTransaction(
        id: 'tx_buy_${DateTime.now().millisecondsSinceEpoch}',
        userId: uid,
        amount: -border.pricePoints,
        transactionType: 'border_purchase',
        referenceId: borderId,
        idempotencyKey: idempotencyKey,
        metadata: {'border_name': border.name},
        createdAt: DateTime.now(),
      );
      await _saveLocalPointTx(uid, pTx);
    } catch (e) {
      debugPrint('Record point tx error: $e');
    }

    // 5. Beritahu seluruh komponen aplikasi
    SupabaseService.instance.notifyProfileChanged();
    _changeController.add(null);

    return {
      'success': true,
      'message': 'Berhasil menukar ${border.name}! Border telah tersimpan di Koleksi dan siap digunakan secara gratis.',
      'border': border,
      'balance': _localPoints,
    };
  }

  /// Pasang Border Aktif pada Profil (100% GRATIS untuk semua border di koleksi)
  Future<bool> equipBorder(String borderId) async {
    await _initStorage();
    final client = _safeClient;
    final uid = _getEffectiveUserId();

    _localOwnedBorderIds.add(borderId);
    _localActiveBorderId = borderId;

    final prefs = await SharedPreferences.getInstance();
    final ownedList = _localOwnedBorderIds.toList();
    await prefs.setString('foodie_active_border_$uid', borderId);
    await prefs.setString('foodie_active_border_global', borderId);
    await prefs.setStringList('foodie_owned_borders_$uid', ownedList);
    await prefs.setStringList('foodie_owned_borders_global', ownedList);
    await HiveService.instance.saveActiveBorderId(borderId, uid);
    await HiveService.instance.saveOwnedBorderIds(_localOwnedBorderIds, uid);

    if (client != null && client.auth.currentUser != null) {
      try {
        await client.rpc('equip_user_border', params: {'p_border_id': borderId});
      } catch (_) {
        try {
          await client.from('profiles').update({'active_border_id': borderId}).eq('id', uid);
          await client.from('user_rewards').update({'is_active': false}).eq('user_id', uid);
          await client.from('user_rewards').update({'is_active': true}).eq('user_id', uid).eq('border_id', borderId);
        } catch (_) {}
      }

      try {
        final meta = client.auth.currentUser!.userMetadata ?? {};
        await client.auth.updateUser(
          UserAttributes(
            data: {
              ...meta,
              'foodie_active_border_id': borderId,
              'foodie_owned_borders': ownedList,
            },
          ),
        );
      } catch (_) {}
    }

    SupabaseService.instance.notifyProfileChanged();
    _changeController.add(null);
    return true;
  }

  /// Lepas Border Aktif (GRATIS)
  Future<bool> unequipBorder() async {
    await _initStorage();
    final client = _safeClient;
    final uid = _getEffectiveUserId();

    _localActiveBorderId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foodie_active_border_$uid');
    await prefs.remove('foodie_active_border_global');
    await HiveService.instance.saveActiveBorderId(null, uid);

    if (client != null && client.auth.currentUser != null) {
      try {
        await client.rpc('equip_user_border', params: {'p_border_id': null});
      } catch (_) {
        try {
          await client.from('profiles').update({'active_border_id': null}).eq('id', uid);
          await client.from('user_rewards').update({'is_active': false}).eq('user_id', uid);
        } catch (_) {}
      }

      try {
        final meta = client.auth.currentUser!.userMetadata ?? {};
        await client.auth.updateUser(
          UserAttributes(
            data: {
              ...meta,
              'foodie_active_border_id': null,
            },
          ),
        );
      } catch (_) {}
    }

    SupabaseService.instance.notifyProfileChanged();
    _changeController.add(null);
    return true;
  }

  /// Validasi Skor Mini Game di Server & Pemberian Poin
  Future<int> awardGamePoints({
    required String gameType,
    required int score,
    String? sessionToken,
    Map<String, dynamic>? metadata,
  }) async {
    await _initStorage();
    final client = _safeClient;
    final uid = client?.auth.currentUser?.id;
    final idempotencyKey = 'game_${gameType}_${DateTime.now().millisecondsSinceEpoch}';

    int awarded = score;
    // Validasi batas wajar server
    if (gameType == 'kulinerdle') {
      awarded = score.clamp(0, 160);
    } else if (gameType == 'detective') {
      awarded = score.clamp(0, 350);
    } else {
      awarded = score.clamp(0, 200);
    }

    if (awarded <= 0) return 0;

    bool rpcSuccess = false;
    if (client != null && uid != null) {
      try {
        final res = await client.rpc('validate_and_award_game_points', params: {
          'p_game_type': gameType,
          'p_score': awarded,
          'p_session_token': sessionToken ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
          'p_idempotency_key': idempotencyKey,
        });

        if (res is Map && res['success'] == true) {
          rpcSuccess = true;
          if (res['balance'] != null) {
            _localPoints = (res['balance'] as num).toInt();
          }
        }
      } catch (e) {
        debugPrint('validate_and_award_game_points RPC error, use local fallback: $e');
      }
    }

    if (!rpcSuccess) {
      _localPoints += awarded;
      await SupabaseService.instance.saveGameScore(awarded);
    }

    final prefs = await SharedPreferences.getInstance();
    final key = uid ?? 'local_user';
    await prefs.setInt('foodie_points_$key', _localPoints);

    SupabaseService.instance.notifyProfileChanged();
    _changeController.add(null);
    return awarded;
  }

  /// Mengambil mutasi poin dari penyimpanan lokal
  Future<List<PointTransaction>> _getLocalPointTxs(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        'foodie_point_txs_$uid',
        if (uid != 'local_user') 'foodie_point_txs_local_user',
      ];
      final Map<String, PointTransaction> map = {};
      for (final k in keys) {
        final list = prefs.getStringList(k) ?? [];
        for (final raw in list) {
          try {
            final tx = PointTransaction.fromJson(jsonDecode(raw) as Map<String, dynamic>);
            map[tx.id] = tx;
          } catch (_) {}
        }
      }
      return map.values.toList();
    } catch (e) {
      debugPrint('Read local point txs error: $e');
      return [];
    }
  }

  /// Menyimpan mutasi poin ke penyimpanan lokal
  Future<void> _saveLocalPointTx(String uid, PointTransaction tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'foodie_point_txs_$uid';
      final existing = await _getLocalPointTxs(uid);
      existing.removeWhere((item) => item.id == tx.id || item.idempotencyKey == tx.idempotencyKey);
      existing.insert(0, tx);
      await prefs.setStringList(
        key,
        existing.map((item) => jsonEncode(item.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('Save local point tx error: $e');
    }
  }

  /// Mengambil riwayat mutasi poin pengguna (gabungan lokal, Supabase, dan auto-recovery)
  Future<List<PointTransaction>> getPointTransactions() async {
    final client = _safeClient;
    final uid = client?.auth.currentUser?.id ?? _getEffectiveUserId();
    final Map<String, PointTransaction> map = {};

    // 1. Ambil dari lokal SharedPreferences
    final localList = await _getLocalPointTxs(uid);
    for (final tx in localList) {
      map[tx.id] = tx;
    }

    // 2. Ambil dari Supabase jika ada koneksi
    if (client != null && client.auth.currentUser != null) {
      try {
        final res = await client
            .from('point_transactions')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(30);

        for (final item in (res as List)) {
          final tx = PointTransaction.fromJson(item as Map<String, dynamic>);
          map[tx.id] = tx;
          await _saveLocalPointTx(uid, tx);
        }
      } catch (e) {
        debugPrint('Fetch point_transactions error: $e');
      }
    }

    // 3. Auto-recovery: Pastikan setiap border yang sudah dimiliki pengguna tercatat di riwayat poin
    try {
      final borders = await getBorders();
      final prefs = await SharedPreferences.getInstance();
      final owned = <String>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith('foodie_owned_borders_')) {
          final list = prefs.getStringList(key);
          if (list != null) owned.addAll(list);
        }
      }

      for (final bid in owned) {
        final hasBorderTx = map.values.any((tx) =>
            tx.transactionType == 'border_purchase' &&
            (tx.referenceId == bid || tx.metadata['border_name'] == bid));
        if (!hasBorderTx) {
          final borderObj = borders.where((b) => b.id == bid).firstOrNull;
          final borderName = borderObj?.name ?? bid.replaceAll('border_', '').replaceAll('_', ' ');
          final price = borderObj?.pricePoints ?? 200;
          final autoTx = PointTransaction(
            id: 'tx_buy_auto_$bid',
            userId: uid,
            amount: -price,
            transactionType: 'border_purchase',
            referenceId: bid,
            idempotencyKey: 'recovery_ptx_$bid',
            metadata: {'border_name': borderName},
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          );
          map[autoTx.id] = autoTx;
          await _saveLocalPointTx(uid, autoTx);
        }
      }
    } catch (e) {
      debugPrint('Auto-recovery point tx error: $e');
    }

    // Bersihkan entri dummy 'Bonus Kurator' jika ada di cache
    map.remove('tx_welcome');

    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
