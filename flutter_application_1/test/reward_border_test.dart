import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/reward_border_service.dart';
import 'package:flutter_application_1/models/course_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'foodie_points_guest': 5000,
      'foodie_points_global': 5000,
    });
  });

  group('Toko Border - Koleksi Permanen & Penggunaan Gratis', () {
    test('Setiap border yang ditukar tersimpan di koleksi & user dapat menukar lebih dari 1 border', () async {
      final service = RewardBorderService.instance;

      // 1. Cek saldo awal
      final initialPoints = await service.getUserPoints();
      expect(initialPoints, greaterThanOrEqualTo(5000));

      // 2. Tukar border pertama: border_batik_keraton (harga 350 poin)
      final purchase1 = await service.purchaseBorder('border_batik_keraton');
      expect(purchase1['success'], isTrue, reason: 'Penukaran border pertama harus berhasil');

      var owned = await service.getOwnedBorderIds();
      expect(owned.contains('border_batik_keraton'), isTrue,
          reason: 'Border 1 harus tersimpan di koleksi');

      // 3. Tukar border kedua: border_wayang_kulit (harga 800 poin)
      final purchase2 = await service.purchaseBorder('border_wayang_kulit');
      expect(purchase2['success'], isTrue, reason: 'Penukaran border kedua harus berhasil');

      owned = await service.getOwnedBorderIds();
      expect(owned.contains('border_batik_keraton'), isTrue,
          reason: 'Border 1 harus TETAP ada di koleksi');
      expect(owned.contains('border_wayang_kulit'), isTrue,
          reason: 'Border 2 harus bertambah di koleksi');
      expect(owned.length, greaterThanOrEqualTo(2),
          reason: 'Koleksi harus menampung lebih dari 1 border');

      // 4. Tukar border ketiga: border_keraton_gold (harga 1500 poin)
      final purchase3 = await service.purchaseBorder('border_keraton_gold');
      expect(purchase3['success'], isTrue, reason: 'Penukaran border ketiga harus berhasil');

      owned = await service.getOwnedBorderIds();
      expect(owned.contains('border_batik_keraton'), isTrue);
      expect(owned.contains('border_wayang_kulit'), isTrue);
      expect(owned.contains('border_keraton_gold'), isTrue);
      expect(owned.length, greaterThanOrEqualTo(3));
    });

    test('User dapat menggunakan/mengganti border di koleksi secara GRATIS (tanpa biaya poin)', () async {
      final service = RewardBorderService.instance;

      // Pastikan border sudah ada di koleksi
      await service.purchaseBorder('border_batik_keraton');
      await service.purchaseBorder('border_wayang_kulit');

      final pointsBeforeEquip = await service.getUserPoints();

      // Pasang border 1
      await service.equipBorder('border_batik_keraton');
      var activeBorder = await service.getActiveBorderId();
      expect(activeBorder, equals('border_batik_keraton'));

      var pointsAfterEquip1 = await service.getUserPoints();
      expect(pointsAfterEquip1, equals(pointsBeforeEquip),
          reason: 'Memasang border dari koleksi tidak boleh memotong poin (GRATIS)');

      // Ganti ke border 2
      await service.equipBorder('border_wayang_kulit');
      activeBorder = await service.getActiveBorderId();
      expect(activeBorder, equals('border_wayang_kulit'));

      var pointsAfterEquip2 = await service.getUserPoints();
      expect(pointsAfterEquip2, equals(pointsBeforeEquip),
          reason: 'Mengganti border dari koleksi tidak boleh memotong poin (GRATIS)');

      // Lepas border (unequip)
      await service.unequipBorder();
      activeBorder = await service.getActiveBorderId();
      expect(activeBorder, isNull);

      var pointsAfterUnequip = await service.getUserPoints();
      expect(pointsAfterUnequip, equals(pointsBeforeEquip),
          reason: 'Melepas border tidak boleh mengubah poin');
    });

    test('Tidak dapat menukar border yang sudah dimiliki di koleksi', () async {
      final service = RewardBorderService.instance;

      // Beli border
      await service.purchaseBorder('border_heritage_silver');

      // Coba beli lagi border yang sama
      final repeatPurchase = await service.purchaseBorder('border_heritage_silver');
      expect(repeatPurchase['success'], isFalse,
          reason: 'Border yang sudah ada di koleksi tidak boleh dibeli ulang');
      expect(repeatPurchase['message'], contains('koleksi'));
    });

    test('Pesan penolakan menggunakan nama Poin Rasa jika saldo tidak cukup', () async {
      final service = RewardBorderService.instance;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('foodie_points_guest', 50);
      await prefs.setInt('foodie_points_global', 50);

      final purchase = await service.purchaseBorder('border_batik_parang');
      expect(purchase['success'], isFalse);
      expect(purchase['message'], contains('Poin Rasa'));
    });

    test('CourseFeedback mengurai border aktif dari user_avatar dengan benar agar terlihat oleh user lain', () {
      // 1. Kasus dengan foto profil internet + tag border
      final jsonWithUrl = {
        'id': '101',
        'user_id': 'user_abc',
        'user_name': 'Budi',
        'user_avatar': 'https://pasbipbzosiifdkqlxtl.supabase.co/storage/v1/object/public/avatars/user_abc/profile.jpg#border=border_keraton_gold',
        'kesan': 'Mantap sekali',
        'saran': 'Lanjutkan',
        'rating': 5,
        'created_at': '2026-10-26T10:00:00Z',
      };
      final fb1 = CourseFeedback.fromJson(jsonWithUrl);
      expect(fb1.userActiveBorder, equals('border_keraton_gold'));
      expect(fb1.userAvatar, equals('https://pasbipbzosiifdkqlxtl.supabase.co/storage/v1/object/public/avatars/user_abc/profile.jpg'));

      // 2. Kasus tanpa foto profil (hanya inisial) + tag border
      final jsonWithoutUrl = {
        'id': '102',
        'user_id': 'user_xyz',
        'user_name': 'Siti',
        'user_avatar': '#border=border_wayang_kulit',
        'kesan': 'Bagus',
        'saran': 'Oke',
        'rating': 4,
        'created_at': '2026-10-26T10:05:00Z',
      };
      final fb2 = CourseFeedback.fromJson(jsonWithoutUrl);
      expect(fb2.userActiveBorder, equals('border_wayang_kulit'));
      expect(fb2.userAvatar, isNull);

      // 3. Kasus kolom native user_active_border tetap diprioritaskan jika ada
      final jsonNative = {
        'id': '103',
        'user_id': 'user_123',
        'user_name': 'Agus',
        'user_avatar': 'https://example.com/avatar.jpg',
        'user_active_border': 'border_garuda_bronze',
        'kesan': 'Keren',
        'saran': 'Mantul',
        'rating': 5,
        'created_at': '2026-10-26T10:10:00Z',
      };
      final fb3 = CourseFeedback.fromJson(jsonNative);
      expect(fb3.userActiveBorder, equals('border_garuda_bronze'));
      expect(fb3.userAvatar, equals('https://example.com/avatar.jpg'));
    });
  });
}
