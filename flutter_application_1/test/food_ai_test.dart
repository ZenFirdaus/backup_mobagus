import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/restaurant.dart';
import 'package:flutter_application_1/services/food_ai.dart';

void main() {
  group('FoodAi Advanced & Error Handling Test', () {
    final mockRestaurants = [
      Restaurant(
        id: '1',
        name: 'Gudeg Yu Djum',
        category: 'warung',
        address: 'Jl. Wijilan No. 167',
        province: 'DIY',
        lat: -7.801,
        lng: 110.365,
        priceMin: 20000,
        priceMax: 45000,
        rating: 4.8,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '2',
        name: 'Kopi Klothok Pakem',
        category: 'cafe',
        address: 'Jl. Kaliurang KM 16',
        province: 'DIY',
        lat: -7.654,
        lng: 110.421,
        priceMin: 10000,
        priceMax: 25000,
        rating: 4.7,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '3',
        name: 'Bebek Sinjay Jogja',
        category: 'bebek',
        address: 'Jl. Kaliurang KM 5',
        province: 'DIY',
        lat: -7.755,
        lng: 110.381,
        priceMin: 35000,
        priceMax: 50000,
        rating: 4.6,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '4',
        name: 'RM Padang Sederhana',
        category: 'padang',
        address: 'Jl. Sudirman',
        province: 'DIY',
        lat: -7.783,
        lng: 110.372,
        priceMin: 25000,
        priceMax: 60000,
        rating: 4.7,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '5',
        name: 'Mie Gacoan Kotabaru',
        category: 'mie_pedas',
        address: 'Kotabaru',
        province: 'DIY',
        lat: -7.787,
        lng: 110.370,
        priceMin: 12000,
        priceMax: 25000,
        rating: 4.6,
        createdAt: DateTime.now(),
      ),
      Restaurant(
        id: '6',
        name: 'Angkringan KR Lik Man',
        category: 'angkringan',
        address: 'Jl. Mangkubumi',
        province: 'DIY',
        lat: -7.791,
        lng: 110.366,
        priceMin: 5000,
        priceMax: 20000,
        rating: 4.5,
        createdAt: DateTime.now(),
      ),
    ];

    Future<List<Restaurant>> mockFetch({
      String? search,
      int? maxPrice,
      String? sortBy,
    }) async {
      var list = List<Restaurant>.from(mockRestaurants);
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        list = list
            .where((r) =>
                r.name.toLowerCase().contains(q) ||
                r.category.toLowerCase().contains(q))
            .toList();
      }
      if (maxPrice != null) {
        list = list.where((r) => r.priceMin <= maxPrice).toList();
      }
      if (sortBy == 'termurah') {
        list.sort((a, b) => a.priceMin.compareTo(b.priceMin));
      }
      return list;
    }

    late FoodAi ai;

    setUp(() {
      ai = FoodAi(fetch: mockFetch);
    });

    test('1. Error handling: Pertanyaan koding/teknologi di luar ranah kuliner', () async {
      final reply = await ai.reply('gimana cara koding flutter dan bikin app?');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('pemrograman') ||
            reply.text.contains('koding') ||
            reply.text.contains('hardware'),
        isTrue,
      );
      expect(reply.chips.isNotEmpty, isTrue);
    });

    test('2. Error handling: Pertanyaan politik & pemilu di luar ranah kuliner', () async {
      final reply = await ai.reply('siapa presiden indonesia sekarang?');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('politik') ||
            reply.text.contains('pemerintahan'),
        isTrue,
      );
    });

    test('3. Error handling: Pertanyaan akademik, matematika & sains', () async {
      final reply = await ai.reply('rumus fisika gaya gravitasi newton');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('rumus') ||
            reply.text.contains('matematika') ||
            reply.text.contains('sains'),
        isTrue,
      );
    });

    test('4. Error handling: Otomotif & mesin', () async {
      final reply = await ai.reply('bengkel motor buat ganti oli honda beat');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('mesin') ||
            reply.text.contains('otomotif') ||
            reply.text.contains('bengkel'),
        isTrue,
      );
    });

    test('5. Error handling: Percintaan & zodiak', () async {
      final reply = await ai.reply('cara balikan sama mantan pacar yang selingkuh');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('asmara') ||
            reply.text.contains('percintaan') ||
            reply.text.contains('hati'),
        isTrue,
      );
    });

    test('6. Error handling: Finansial, saham & crypto', () async {
      final reply = await ai.reply('rekomendasi investasi saham dan harga bitcoin');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('investasi') ||
            reply.text.contains('crypto') ||
            reply.text.contains('keuangan'),
        isTrue,
      );
    });

    test('7. Error handling: Medis & resep obat', () async {
      final reply = await ai.reply('dosis obat paracetamol dan penyakit jantung');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('penyakit') ||
            reply.text.contains('dokter') ||
            reply.text.contains('medis'),
        isTrue,
      );
    });

    test('8. Error handling: Olahraga & game', () async {
      final reply = await ai.reply('skor bola liga champions tadi malam');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('olahraga') ||
            reply.text.contains('game') ||
            reply.text.contains('liga'),
        isTrue,
      );
    });

    test('9. Error handling: Tugas AI umum non-kuliner', () async {
      final reply = await ai.reply('terjemahkan teks ini ke dalam bahasa inggris');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('tidak dirancang') ||
            reply.text.contains('penerjemahan') ||
            reply.text.contains('khusus kuliner'),
        isTrue,
      );
    });

    test('10. Error handling: Gibberish & ketikan acak', () async {
      final reply = await ai.reply('asdfghjklqwerty');
      expect(reply.cards, isEmpty);
      expect(
        reply.text.contains('acak') ||
            reply.text.contains('salah ketik') ||
            reply.text.contains('kurang jelas'),
        isTrue,
      );
    });

    test('11. Kecerdasan Kontekstual: Gabungan kata non-kuliner + makanan tetap dijawab kuliner', () async {
      // User menyebut koding, tapi tujuannya mencari tempat ngopi!
      final reply = await ai.reply('habis pusing koding flutter pengen ngopi santai di kafe');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Klothok'));
    });

    test('12. Kosakata baru: Bebek & Unggas', () async {
      final reply = await ai.reply('bebek goreng sinjay');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Bebek Sinjay'));
    });

    test('13. Kosakata baru: Masakan Padang', () async {
      final reply = await ai.reply('nasi padang rendang');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Padang'));
    });

    test('14. Kosakata baru: Mie pedas kekinian', () async {
      final reply = await ai.reply('mie gacoan pedas');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Gacoan'));
    });

    test('15. Bahasa daerah Jawa: Luwe & Sego kucing', () async {
      final reply = await ai.reply('wetengku luwe golek sego kucing angkringan');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Angkringan'));
    });

    test('16. Parser harga slang: ceban & gocap', () async {
      final reply1 = await ai.reply('kopi budget ceban');
      expect(reply1.cards.isNotEmpty, isTrue);
      expect(reply1.cards.first.priceMin <= 10000, isTrue);

      final reply2 = await ai.reply('bebek budget gocap');
      expect(reply2.cards.isNotEmpty, isTrue);
      expect(reply2.cards.first.priceMin <= 50000, isTrue);
    });

    test('17. Parser rentang harga: 15-25rb', () async {
      final reply = await ai.reply('gudeg budget 15-25rb');
      expect(reply.cards.isNotEmpty, isTrue);
      expect(reply.cards.first.name, contains('Gudeg'));
    });
  });
}
