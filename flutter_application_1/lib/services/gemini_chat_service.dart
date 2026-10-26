import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/restaurant.dart';
import '../models/user_ai_profile.dart';
import 'food_ai.dart';

/// Layanan AI Chatbot berbasis Large Language Model (LLM) Google Gemini.
/// Menghubungkan chatbot FOODIE AI dengan Gemini 1.5 Flash melalui REST API,
/// dilengkapi dengan grounding data kuliner Yogyakarta/Jateng dari database Supabase,
/// persona pengguna, riwayat percakapan multi-turn, serta graceful fallback ke FoodAi engine.
class GeminiChatService {
  GeminiChatService._();
  static final GeminiChatService instance = GeminiChatService._();

  static const String _kPrefsApiKey = 'foodie_gemini_api_key';
  static const String _kDefaultModel = 'gemini-1.5-flash';

  /// Default API Key Gemini jika ingin langsung diset di dalam kode tanpa dialog UI.
  /// Pengembang dapat memasukkan API Key di sini atau lewat dart-define:
  /// --dart-define=GEMINI_API_KEY=AIzaSy...
  static const String defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  String? _customApiKey;
  bool _initialized = false;

  // Riwayat percakapan sesi multi-turn Gemini
  final List<Map<String, dynamic>> _conversationHistory = [];

  /// Inisialisasi service dan membaca API key dari setelan / SharedPreferences
  Future<void> init({String? defaultApiKey}) async {
    if (defaultApiKey != null && defaultApiKey.trim().isNotEmpty) {
      _customApiKey = defaultApiKey.trim();
    }
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_kPrefsApiKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _customApiKey = savedKey.trim();
      } else if ((_customApiKey == null || _customApiKey!.isEmpty) &&
          GeminiChatService.defaultApiKey.isNotEmpty) {
        _customApiKey = GeminiChatService.defaultApiKey;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('GeminiChatService init error: $e');
    }
  }

  /// Mendapatkan API Key yang aktif saat ini
  String? get apiKey {
    if (_customApiKey != null && _customApiKey!.trim().isNotEmpty) {
      return _customApiKey!.trim();
    }
    if (defaultApiKey.trim().isNotEmpty) {
      return defaultApiKey.trim();
    }
    return null;
  }

  /// Memeriksa apakah Gemini API Key sudah tersedia
  bool get hasKey => apiKey != null && apiKey!.trim().isNotEmpty;

  /// Menyimpan API Key baru ke SharedPreferences
  Future<void> setApiKey(String key) async {
    final clean = key.trim();
    _customApiKey = clean.isEmpty ? null : clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiKey != null) {
        await prefs.setString(_kPrefsApiKey, _customApiKey!);
      } else {
        await prefs.remove(_kPrefsApiKey);
      }
    } catch (e) {
      debugPrint('Gagal menyimpan Gemini API Key: $e');
    }
  }

  /// Reset riwayat percakapan Gemini
  void reset() {
    _conversationHistory.clear();
  }

  /// Menguji koneksi ke Google Gemini API dengan kunci yang diberikan
  Future<bool> testConnection([String? keyToTest]) async {
    final key = keyToTest ?? apiKey;
    if (key == null || key.trim().isEmpty) return false;

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_kDefaultModel:generateContent?key=${key.trim()}',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Halo, uji koneksi kuliner singkat.'}
                  ]
                }
              ],
              'generationConfig': {'maxOutputTokens': 10},
            }),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gemini connection test failed: $e');
      return false;
    }
  }

  /// Menghasilkan balasan cerdas dari Google Gemini LLM.
  /// Jika Gemini tidak tersedia atau gagal, otomatis fallback ke [fallbackAi].
  Future<BotReply> reply({
    required String input,
    required List<Restaurant> availableRestaurants,
    UserAiProfile? userProfile,
    required FoodAi fallbackAi,
    DateTime? now,
  }) async {
    await init();

    // Jika API Key belum diset, gunakan FoodAi engine bawaan secara transparan
    if (!hasKey) {
      return fallbackAi.reply(input, now: now);
    }

    try {
      final systemInstruction = _buildSystemInstruction(
        availableRestaurants: availableRestaurants,
        userProfile: userProfile,
        now: now ?? DateTime.now(),
      );

      final contents = List<Map<String, dynamic>>.from(_conversationHistory);
      contents.add({
        'role': 'user',
        'parts': [
          {'text': input}
        ],
      });

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_kDefaultModel:generateContent?key=${apiKey!.trim()}',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': systemInstruction}
                ]
              },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 1000,
              },
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates.first as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = (parts.first['text'] as String?) ?? '';

            // Simpan riwayat percakapan (user & model)
            _conversationHistory.add({
              'role': 'user',
              'parts': [
                {'text': input}
              ],
            });
            _conversationHistory.add({
              'role': 'model',
              'parts': [
                {'text': rawText}
              ],
            });

            // Batasi riwayat maksimal 10 pertukaran agar tidak meluap
            if (_conversationHistory.length > 20) {
              _conversationHistory.removeRange(
                0,
                _conversationHistory.length - 20,
              );
            }

            return _parseGeminiResponse(rawText, availableRestaurants);
          }
        }
      }

      // Jika response selain 200 (misal quota habis), fallback ke FoodAi
      debugPrint('Gemini API status: ${response.statusCode}, fallback to FoodAi');
      return await fallbackAi.reply(input, now: now);
    } catch (e) {
      debugPrint('Gemini API call failed: $e. Fallback to FoodAi.');
      return await fallbackAi.reply(input, now: now);
    }
  }

  /// Membangun System Instruction kaya konteks untuk Gemini LLM
  String _buildSystemInstruction({
    required List<Restaurant> availableRestaurants,
    UserAiProfile? userProfile,
    required DateTime now,
  }) {
    final buffer = StringBuffer();

    // 1. Identitas & Peran
    buffer.writeln(
      'Kamu adalah FOODIE AI, asisten kuliner pintar, ramah, dan berwawasan luas dari aplikasi FOODIE yang berfokus pada wisata kuliner Daerah Istimewa Yogyakarta (Jogja) dan sekitarnya (Mataraman, Solo, Semarang).',
    );
    buffer.writeln(
      'Gaya bicaramu ramah, hangat, menggunakan Bahasa Indonesia santai namun sopan, sesekali menyisipkan istilah kuliner lokal Jogja secara luwes (seperti angkringan, krecek, gudeg, soto bathok, sego kucing, kopi joss, sambel mercon, dsb.).',
    );
    buffer.writeln(
      'Gunakan format tebal **seperti ini** untuk nama tempat makan, nama makanan, atau angka harga agar teks enak dibaca di tampilan bubble chat aplikasi.',
    );

    // 2. Waktu Saat Ini
    final hour = now.hour;
    final timeStr = hour < 11
        ? 'pagi (waktu sarapan)'
        : hour < 15
            ? 'siang (waktu makan siang / maksi)'
            : hour < 18
                ? 'sore (waktu santai / ngopi)'
                : 'malam (waktu makan malam / kuliner malam)';
    buffer.writeln('Waktu saat ini: $timeStr.');

    // 3. Profil Pengguna (Persona Grounding)
    if (userProfile != null && userProfile.isCompleted) {
      buffer.writeln('\n[PROFIL PENGGUNA SAAT INI]:');
      if (userProfile.occupation != null) {
        buffer.writeln('- Pekerjaan: ${userProfile.occupation}');
      }
      if (userProfile.favoriteTastes.isNotEmpty) {
        buffer.writeln('- Selera Rasa Favorit: ${userProfile.favoriteTastes.join(', ')}');
      }
      if (userProfile.mealBudget != null) {
        buffer.writeln('- Estimasi Budget Sekali Makan: ${userProfile.mealBudget}');
      }
      if (userProfile.preferredPlaces.isNotEmpty) {
        buffer.writeln('- Tipe Tempat Favorit: ${userProfile.preferredPlaces.join(', ')}');
      }
      if (userProfile.dietaryPreference != null) {
        buffer.writeln('- Preferensi Diet: ${userProfile.dietaryPreference}');
      }
      buffer.writeln('Gunakan preferensi pengguna di atas untuk menyelaraskan saran kuliner bila relevan.');
    }

    // 4. Grounding Daftar Restoran Resmi dari Database Aplikasi
    buffer.writeln('\n[DAFTAR TEMPAT KULINER ASLI DI APLIKASI FOODIE]:');
    final takeCount = availableRestaurants.length > 25 ? 25 : availableRestaurants.length;
    for (int i = 0; i < takeCount; i++) {
      final r = availableRestaurants[i];
      buffer.writeln(
        '- ID: "${r.id}" | Nama: "${r.name}" | Kategori: "${r.category}" | Alamat: "${r.address}" | Rating: ${r.rating} | Harga: Rp${r.priceMin}-Rp${r.priceMax}',
      );
    }

    // 5. Aturan Sintaks Rekomendasi Terstruktur
    buffer.writeln('\n[ATURAN PENTING FORMAT OUTPUT]:');
    buffer.writeln(
      '1. Jawab pertanyaan pengguna dengan informatif, berempati, dan cerdas.',
    );
    buffer.writeln(
      '2. Jika pengguna meminta rekomendasi tempat makan atau bertanya tentang kuliner, sebutkan tempat dari daftar di atas yang paling cocok.',
    );
    buffer.writeln(
      '3. Untuk setiap tempat makan yang kamu rekomendasikan dan ada di daftar atas, sertakan tag tersembunyi persis seperti ini di baris baru di akhir pesan:\n[RESTORAN: id_atau_nama_tempat]',
    );
    buffer.writeln(
      '   Maksimal 3 tag [RESTORAN: ...] agar tidak membanjiri layar pengguna.',
    );
    buffer.writeln(
      '4. Di baris paling akhir, berikan 2 hingga 4 tombol opsi balasan cepat menggunakan format:\n[CHIPS: Opsi 1 | Opsi 2 | Opsi 3]',
    );
    buffer.writeln(
      '5. Jangan pernah menjawab hal di luar etika dan jika pengguna bertanya di luar ranah kuliner (seperti koding, politik, kesehatan medis serius), jawab dengan sopan dan ajak kembali santai membicarakan kuliner enak.',
    );

    return buffer.toString();
  }

  /// Mem-parse respons dari Gemini untuk mengekstrak teks bersih,
  /// kartu restoran ([cards]), dan chip balasan cepat ([chips]).
  BotReply _parseGeminiResponse(
    String rawText,
    List<Restaurant> availableRestaurants,
  ) {
    String cleanText = rawText;
    final List<Restaurant> matchedCards = [];
    final List<QuickReply> chips = [];

    // 1. Ekstrak [RESTORAN: ...]
    final restaurantRegex = RegExp(r'\[RESTORAN:\s*([^\]]+)\]', caseSensitive: false);
    final matches = restaurantRegex.allMatches(rawText);
    for (final match in matches) {
      final ref = match.group(1)?.trim() ?? '';
      if (ref.isEmpty) continue;

      // Cari berdasarkan ID atau nama restoran
      final found = availableRestaurants.where((r) {
        if (r.id.toLowerCase() == ref.toLowerCase()) return true;
        if (r.name.toLowerCase() == ref.toLowerCase()) return true;
        if (r.name.toLowerCase().contains(ref.toLowerCase())) return true;
        if (ref.toLowerCase().contains(r.name.toLowerCase())) return true;
        return false;
      }).firstOrNull;

      if (found != null && !matchedCards.any((c) => c.id == found.id)) {
        matchedCards.add(found);
      }
    }
    // Hapus tag [RESTORAN: ...] dari teks yang ditampilkan ke pengguna
    cleanText = cleanText.replaceAll(restaurantRegex, '').trim();

    // 2. Ekstrak [CHIPS: ...]
    final chipsRegex = RegExp(r'\[CHIPS:\s*([^\]]+)\]', caseSensitive: false);
    final chipMatch = chipsRegex.firstMatch(cleanText);
    if (chipMatch != null) {
      final chipContent = chipMatch.group(1)?.trim() ?? '';
      final items = chipContent.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
      for (final item in items) {
        chips.add(QuickReply(item));
      }
      cleanText = cleanText.replaceAll(chipsRegex, '').trim();
    }

    // Fallback chip jika Gemini tidak menyertakan chip
    if (chips.isEmpty) {
      chips.addAll([
        QuickReply('Rekomendasi lain'),
        QuickReply('Yang lebih murah'),
        QuickReply('Kuliner viral Jogja'),
      ]);
    }

    // Jika Gemini tidak menyertakan tag [RESTORAN: ...] tetapi menyebut nama restoran di teks,
    // lakukan deteksi cerdas dari teks yang ditulis Gemini
    if (matchedCards.isEmpty) {
      for (final r in availableRestaurants.take(15)) {
        if (cleanText.toLowerCase().contains(r.name.toLowerCase())) {
          if (!matchedCards.any((c) => c.id == r.id)) {
            matchedCards.add(r);
            if (matchedCards.length >= 2) break;
          }
        }
      }
    }

    return BotReply(
      cleanText,
      cards: matchedCards,
      chips: chips,
    );
  }
}
