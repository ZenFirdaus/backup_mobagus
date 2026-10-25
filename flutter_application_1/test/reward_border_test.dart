import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/reward_border_service.dart';

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
  });
}
