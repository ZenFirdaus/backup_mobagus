import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/restaurant.dart';
import 'package:flutter_application_1/models/user_ai_profile.dart';
import 'package:flutter_application_1/services/food_ai.dart';
import 'package:flutter_application_1/services/gemini_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockRestaurants = [
    Restaurant(
      id: 'resto_1',
      name: 'Gudeg Yu Djum Wijilan',
      category: 'warung',
      address: 'Jl. Wijilan No. 167, Kraton, Yogyakarta',
      province: 'DIY',
      lat: -7.801,
      lng: 110.365,
      priceMin: 20000,
      priceMax: 45000,
      rating: 4.8,
      createdAt: DateTime.now(),
    ),
    Restaurant(
      id: 'resto_2',
      name: 'Kopi Klothok Pakem',
      category: 'cafe',
      address: 'Jl. Kaliurang KM 16, Pakem, Sleman',
      province: 'DIY',
      lat: -7.654,
      lng: 110.421,
      priceMin: 10000,
      priceMax: 25000,
      rating: 4.7,
      createdAt: DateTime.now(),
    ),
  ];

  late FoodAi fallbackAi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fallbackAi = FoodAi(
      fetch: ({search, maxPrice, sortBy}) async => mockRestaurants,
    );
    await GeminiChatService.instance.init();
    await GeminiChatService.instance.setApiKey('');
    GeminiChatService.instance.reset();
  });

  group('GeminiChatService API Key & State Management', () {
    test('hasKey is false when no key is set', () {
      expect(GeminiChatService.instance.hasKey, isFalse);
      expect(GeminiChatService.instance.apiKey, isNull);
    });

    test('saves and reads custom Gemini API key into SharedPreferences', () async {
      const sampleKey = 'AIzaSyD_DummyKeyForTest12345';
      await GeminiChatService.instance.setApiKey(sampleKey);

      expect(GeminiChatService.instance.hasKey, isTrue);
      expect(GeminiChatService.instance.apiKey, sampleKey);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('foodie_gemini_api_key'), sampleKey);

      // Clearing key
      await GeminiChatService.instance.setApiKey('');
      expect(GeminiChatService.instance.hasKey, isFalse);
      expect(prefs.containsKey('foodie_gemini_api_key'), isFalse);
    });

    test('initializes with defaultApiKey from AI tab settings', () async {
      await GeminiChatService.instance.setApiKey('');
      await GeminiChatService.instance.init(defaultApiKey: 'AIzaSyDefaultFromAiTab123');
      expect(GeminiChatService.instance.hasKey, isTrue);
      expect(GeminiChatService.instance.apiKey, 'AIzaSyDefaultFromAiTab123');
      await GeminiChatService.instance.setApiKey('');
    });

    test('reset clears conversation history', () {
      GeminiChatService.instance.reset();
      expect(GeminiChatService.instance.apiKey, isNull);
    });
  });

  group('GeminiChatService Response Parsing & RAG Grounding', () {
    test('falls back gracefully to FoodAi when API key is not configured', () async {
      final reply = await GeminiChatService.instance.reply(
        input: 'rekomendasi gudeg enak di jogja',
        availableRestaurants: mockRestaurants,
        fallbackAi: fallbackAi,
      );

      expect(reply.text, isNotEmpty);
      expect(reply.cards, isNotEmpty);
      expect(reply.cards.first.name, contains('Gudeg'));
    });

    test('handles fallback when user asks general food question without key', () async {
      final reply = await GeminiChatService.instance.reply(
        input: 'mau makan apa ya siang ini',
        availableRestaurants: mockRestaurants,
        userProfile: const UserAiProfile(
          occupation: 'Mahasiswa',
          favoriteTastes: ['Manis', 'Gurih'],
        ),
        fallbackAi: fallbackAi,
      );

      expect(reply.text, isNotEmpty);
      expect(reply.chips, isNotEmpty);
    });
  });
}
