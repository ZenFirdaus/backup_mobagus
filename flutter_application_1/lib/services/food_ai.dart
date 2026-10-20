import 'dart:math';

import '../models/restaurant.dart';

/// Cara FoodAi mengambil data. Disambungkan ke SupabaseService di ai_tab.dart,
/// jadi file ini tidak bergantung langsung pada Supabase.
typedef RestaurantFetcher = Future<List<Restaurant>> Function({
  String? search,
  int? maxPrice,
  String? sortBy,
});

/// 25000 -> "Rp25.000".
String foodRp(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

/// "fast_food" -> "Cepat saji", "cafe" -> "Kafe", dst.
String prettyCategory(Object? raw) {
  final k = (raw ?? '').toString().trim().toLowerCase();
  if (k.isEmpty || k == 'null') return 'Kuliner';
  const names = {
    'cafe': 'Kafe',
    'coffee_shop': 'Kedai kopi',
    'fast_food': 'Cepat saji',
    'restaurant': 'Restoran',
    'bakery': 'Toko roti',
    'food_court': 'Food court',
    'ice_cream': 'Es krim',
    'bar': 'Bar',
    'street_food': 'Jajanan kaki lima',
    // --- tambahan ---
    'warung': 'Warung',
    'warung_makan': 'Warung makan',
    'angkringan': 'Angkringan',
    'dessert': 'Dessert',
    'steakhouse': 'Steak',
    'japanese': 'Masakan Jepang',
    'chinese': 'Masakan Tionghoa',
    'korean': 'Masakan Korea',
    'seafood': 'Seafood',
    'noodle': 'Mie',
    'pizzeria': 'Pizzeria',
    'bistro': 'Bistro',
    'buffet': 'Prasmanan',
    'juice_bar': 'Kedai jus',
    'tea_house': 'Kedai teh',
    'canteen': 'Kantin',
    'kantin': 'Kantin',
  };
  final hit = names[k];
  if (hit != null) return hit;
  final spaced = k.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Tombol balasan cepat di bawah jawaban bot.
/// [label] ditampilkan di gelembung pengguna, [send] dikirim ke bot.
class QuickReply {
  QuickReply(this.label, {String? send}) : send = send ?? label;

  final String label;
  final String send;
}

/// Satu balasan bot: teks (boleh **tebal**), kartu tempat, dan chip.
class BotReply {
  const BotReply(this.text, {this.cards = const [], this.chips = const []});

  final String text;
  final List<Restaurant> cards;
  final List<QuickReply> chips;
}

// ---------------------------------------------------------------------------
// Kamus topik. Tambah/ubah di sini sesuai data kuliner di databasemu.
// [terms] = kata yang dicari ke database (dicoba semuanya, hasilnya digabung).
// ---------------------------------------------------------------------------
class _Topic {
  _Topic(this.label, this.match, this.terms);

  final String label;
  final RegExp match;
  final List<String> terms;
}

final List<_Topic> _topics = [
  _Topic('gudeg', RegExp(r'\bgudeg\b'), ['gudeg']),
  _Topic('soto', RegExp(r'\bsoto\b'), ['soto']),
  _Topic('bakmi & mie', RegExp(r'\b(bakmi|bakmie|mie|mi)\b'), ['bakmi', 'mie']),
  _Topic('bakso', RegExp(r'\b(bakso|baso)\b'), ['bakso']),
  _Topic('ayam', RegExp(r'\b(ayam|geprek)\b'), ['ayam', 'geprek']),
  _Topic('sate', RegExp(r'\b(sate|satay)\b'), ['sate']),
  _Topic('nasi', RegExp(r'\b(nasi|sego|rice)\b'), ['nasi']),
  _Topic('seafood', RegExp(r'\b(seafood|ikan|lele|udang|cumi)\b'), [
    'seafood',
    'ikan',
    'lele',
  ]),
  _Topic('makanan pedas', RegExp(r'\b(pedas|pedes|sambal|seblak)\b'), [
    'pedas',
    'sambal',
    'seblak',
  ]),
  _Topic(
    'kopi & nongkrong',
    RegExp(r'\b(kopi|coffee|ngopi|nongkrong|cafe|kafe|wfh|santai)\b'),
    ['coffee', 'kopi', 'cafe'],
  ),
  _Topic(
    'jajanan',
    RegExp(
      r'\b(jajan|jajanan|camilan|cemilan|snack|ngemil|siomay|gorengan|cilok)\b',
    ),
    ['jajan', 'siomay', 'snack'],
  ),
  _Topic('cepat saji', RegExp(r'\b(fast ?food|cepat saji|burger|pizza)\b'), [
    'fast_food',
    'burger',
    'pizza',
  ]),
  _Topic(
    'roti & kue',
    RegExp(r'\b(roti|kue|bakery|donat|dessert|manis|cake)\b'),
    ['roti', 'bakery', 'kue', 'dessert'],
  ),
  _Topic(
    'es & minuman',
    RegExp(r'\b(es|minuman|boba|jus|teh|dingin|segar)\b'),
    ['es', 'jus', 'minuman', 'teh'],
  ),
  _Topic('vegetarian', RegExp(r'\b(vegetarian|vegan|sayur)\b'), [
    'vegetarian',
    'vegan',
    'sayur',
  ]),
  _Topic('restoran', RegExp(r'\b(restoran|resto|restaurant)\b'), [
    'restaurant',
    'resto',
  ]),
  _Topic('sarapan', RegExp(r'\b(sarapan|breakfast|bubur|lontong)\b'), [
    'bubur',
    'lontong',
    'sarapan',
  ]),

  // ------------------------- TAMBAHAN TOPIK -------------------------------
  _Topic(
    'martabak & kue cubit',
    RegExp(r'\b(martabak|terang bulan|kue cubit|pukis|kue pancong)\b'),
    ['martabak', 'terang bulan', 'cubit'],
  ),
  _Topic(
    'angkringan',
    RegExp(
      r'\b(angkringan|wedangan|wedang|hik|nasi kucing|sego kucing|kucingan)\b',
    ),
    ['angkringan', 'wedang', 'kucing'],
  ),
  _Topic(
    'bakpia & oleh-oleh',
    RegExp(r'\b(bakpia|oleh ?oleh|geplak|yangko|mochi|souvenir|buah tangan)\b'),
    ['bakpia', 'oleh', 'yangko'],
  ),
  _Topic(
    'tengkleng & tongseng',
    RegExp(r'\b(tengkleng|tongseng|gulai|kambing|sate kambing|kebab)\b'),
    ['tengkleng', 'tongseng', 'gulai', 'kambing'],
  ),
  _Topic(
    'pecel & rujak',
    RegExp(
      r'\b(pecel|rujak|gado ?gado|lotek|karedok|tahu campur|tahu tek|lontong sayur)\b',
    ),
    ['pecel', 'rujak', 'gado'],
  ),
  _Topic(
    'penyetan & lalapan',
    RegExp(r'\b(penyet|penyetan|lalap|lalapan|pecel lele)\b'),
    ['penyet', 'lalap'],
  ),
  _Topic(
    'sop & berkuah',
    RegExp(r'\b(sop|sup|konro|iga|berkuah|kuah|hangat|anget|hujan)\b'),
    ['sop', 'konro', 'kuah'],
  ),
  _Topic(
    'steak & panggang',
    RegExp(r'\b(steak|bbq|barbeque|grill|panggang|bakaran|iga bakar|ribs?)\b'),
    ['steak', 'grill', 'bbq'],
  ),
  _Topic(
    'masakan asia',
    RegExp(
      r'\b(ramen|sushi|jepang|japanese|korea|korean|bibimbap|dimsum|dim sum|chinese|china|thai|india|asia)\b',
    ),
    ['ramen', 'sushi', 'dimsum', 'korea'],
  ),
  _Topic(
    'pasta & western',
    RegExp(r'\b(pasta|spaghetti|italia|italian|western|sandwich|lasagna)\b'),
    ['pasta', 'italia', 'western'],
  ),
  _Topic('es krim', RegExp(r'\b(es krim|eskrim|ice ?cream|gelato)\b'), [
    'ice_cream',
    'es krim',
    'gelato',
  ]),
  _Topic(
    'makanan sehat',
    RegExp(r'\b(sehat|healthy|diet|salad|clean eating|rendah kalori)\b'),
    ['salad', 'healthy', 'sehat'],
  ),
  _Topic(
    'kuliner khas & legendaris',
    RegExp(
      r'\b(khas|tradisional|legendaris|lawas|jadul|klasik|autentik|asli|ikonik|turun temurun)\b',
    ),
    ['gudeg', 'soto', 'sate', 'bakmi'],
  ),
  _Topic(
    'makan bareng keluarga',
    RegExp(
      r'\b(keluarga|arisan|rombongan|ramean|ramai ramai|reuni|acara|syukuran|ulang tahun)\b',
    ),
    ['restaurant', 'food_court'],
  ),
  _Topic(
    'suasana romantis',
    RegExp(r'\b(romantis|kencan|candle ?light|dinner date|anniversary)\b'),
    ['restaurant', 'cafe'],
  ),
  _Topic(
    'makan larut malam',
    RegExp(
      r'\b(tengah malam|begadang|lembur|24 jam|dini hari|midnight|larut malam)\b',
    ),
    ['angkringan', 'nasi', 'bakmi'],
  ),
];

const Set<String> _stop = {
  'yang',
  'dan',
  'di',
  'ke',
  'dari',
  'untuk',
  'enak',
  'cari',
  'carikan',
  'mau',
  'ingin',
  'dong',
  'budget',
  'harga',
  'dibawah',
  'bawah',
  'paling',
  'tempat',
  'makan',
  'rekomendasi',
  'rekomendasikan',
  'dekat',
  'murah',
  'rb',
  'ribu',
  'rebu',
  'juta',
  'aku',
  'saya',
  'pengen',
  'pengin',
  'pingin',
  'lagi',
  'nih',
  'deh',
  'sih',
  'aja',
  'saja',
  'tolong',
  'bisa',
  'kasih',
  'kasi',
  'tau',
  'tahu',
  'ada',
  'apa',
  'yg',
  'sama',
  'buat',
  'dengan',
  'atau',
  'lain',
  'lainnya',
  'banget',
  'bgt',
  'ya',
  'yuk',
  'coba',
  'cobain',
  'minta',
  'mohon',
  'tampilkan',
  'lihat',
  'liat',
  'sekitar',
  'sini',
  'disini',
  'daerah',
  'area',
  'kuliner',
  'warung',
  'maks',
  'max',
  'maksimal',
  'under',
  'kurang',
  'lebih',
  'kisaran',
  'harganya',
  'rupiah',
  'kamu',
  'kak',
  'min',
  'minimal',
  'sampai',
  'hari',
  'ini',
  'itu',
  'donk',
  'gak',
  'nggak',
  'tidak',
  'bukan',
  'laper',
  'lapar',
  'haus',
  'kelaparan',
  'mager',
  'berapa',
  'dimana',
  'mana',
  'gimana',
  // --- tambahan: kata saran / minta rekomendasi ---
  'enaknya',
  'enakan',
  'saran',
  'sarannya',
  'rekomen',
  'rekomendasinya',
  'ide',
  'usul',
  'masukan',
  'referensi',
  'tips',
  'menurut',
  'menurutmu',
  'bagusnya',
  'baiknya',
  'sebaiknya',
  'mending',
  'cocoknya',
  'cocok',
  'bingung',
  'galau',
  'pusing',
  'ragu',
  'labil',
  'sesuatu',
  'kemana',
  // --- tambahan: kata "terbaik" ---
  'terbaik',
  'terenak',
  'terfavorit',
  'favorit',
  'populer',
  'terpopuler',
  'laris',
  'terlaris',
  'hits',
  'viral',
  'best',
  'top',
  'juara',
  'andalan',
  // --- tambahan: kata umum ---
  'pilihan',
  'pilih',
  'milih',
  'sekarang',
  'nanti',
  'besok',
  'siang',
  'malam',
  'pagi',
  'sore',
  'sudah',
  'udah',
  'belum',
  'pesan',
  'pesen',
  'order',
  'makanan',
  'jam',
  'dulu',
  'menu',
  // --- tambahan: bahasa budget tipis ---
  'anak',
  'kos',
  'kost',
  'tipis',
  'mepet',
  'terbatas',
  'pas',
  'pasan',
  'seadanya',
  'minim',
  'sedikit',
  'tanggal',
  'tua',
  'bokek',
  'cekak',
  'kering',
  'dompet',
  'kantong',
  'kere',
  'mahasiswa',
  'pelajar',
  'meriah',
  'ramah',
  'ngirit',
  'miskin',
  'uang',
  'saku',
  // --- tambahan: bahasa budget longgar ---
  'longgar',
  'sultan',
  'mewah',
  'traktir',
  'traktiran',
  'ditraktir',
  'masalah',
  'spesial',
  'istimewa',
  'mahalan',
  'mahal',
  'bayar',
  'dining',
  'dine',
  'fine',
  'aman',
  'besar',
};

final _reReset = RegExp(
  r'\b(mulai ulang|ulang dari awal|reset|percakapan baru|hapus (chat|semua))\b',
);
final _reThanks = RegExp(
  r'\b(terima ?kasih|makasih|makasi|thanks|thank you|thx|trims|suwun|nuhun)\b',
);
final _reBye = RegExp(
  r'\b(dadah|bye|sampai jumpa|sampai nanti|dah dulu|udahan)\b',
);
final _reWho = RegExp(
  r'\b(siapa (kamu|namamu|kau|nama kamu)|kamu siapa|kamu itu apa|kamu (bot|ai|manusia))\b',
);
final _reHelp = RegExp(
  r'\b(bantuan|help|bisa apa|fitur|cara pakai|cara kerja|gimana cara|panduan|tutorial)\b',
);
final _reGreet = RegExp(
  r'^(halo+|hai+|hi+|hey+|hello|helo|pagi|siang|sore|malam|selamat (pagi|siang|sore|malam)|assalamualaikum|salam|permisi|tes|test)\b',
);
final _reSurprise = RegExp(
  r'\b(kejutan|surprise|acak|random|terserah|bebas|pilihin|pilihkan|apa aja|apa saja|bingung|gak tau|ga tau|nggak tau|ngga tau|tidak tahu|tentuin|tentukan)\b',
);
final _reRaise = RegExp(
  r'\b(naik(kan|in)? (budget|harga)|budget (naik|lebih)|tambah(in)? budget|lebih mahal|agak mahal|yang (premium|mewah|lebih bagus)|upgrade)\b',
);
final _reDislike = RegExp(
  r'\b((gak|ga|nggak|ngga|tidak|bukan) (cocok|suka|mau|itu|sreg|pas)|kurang (cocok|suka|sreg|pas)|bosen|bosan|ganti|beda jenis|jenis lain|makanan lain)\b',
);
final _reCheaper = RegExp(
  r'\b(lebih murah|lebih hemat|yang murah(an)?|kemahalan|terlalu mahal|mahal banget)\b',
);
final _reMoreStrong = RegExp(
  r'\b(yang lain|yg lain|lainnya|selain (itu|ini)|berikutnya|next|lanjut|opsi lain|pilihan lain|ada lagi|tampilkan lagi|lihat lagi)\b',
);
final _reLagi = RegExp(r'\blagi\b');
final _reInfo = RegExp(
  r'\b(jam buka(nya)?|buka (jam|nggak|ga|gak)|tutup|alamat(nya)?|lokasi(nya)?|jarak(nya)?|terdekat|rute|maps?|telepon|telp|nomor|reservasi|booking)\b',
);
final _reAck = RegExp(
  r'^(ok|oke|okay|okey|siap|sip|sipp|mantap|baik|boleh|noted|yoi|yap|ya|iya|oh|ohh|wah|keren|pinter|pintar|bagus|hebat)\b',
);
final _reCheapest = RegExp(
  r'\b(termurah|paling murah|paling hemat|murah banget|serba murah)\b',
);
final _reCheapWord = RegExp(r'\b(murah|hemat|irit)\b');

// ---------------------------------------------------------------------------
// TAMBAHAN KOSAKATA (v2)
// ---------------------------------------------------------------------------

/// Minta saran terbuka tanpa menyebut jenis makanan, mis.
/// "enaknya makan apa ya", "bingung nih mau makan apa, ada saran ga?",
/// "makan apa hari ini", "laper nih", "apa ya yang enak".
/// Hanya dipakai kalau pesan TIDAK menyebut topik makanan (lihat _route).
final List<RegExp> _adviceRes = [
  RegExp(
    r'\b(enak(nya|an)? (makan|apa|dimakan|dipesan|dipesen|dicoba|dimana))\b',
  ),
  RegExp(r'\bmakan (apa|apaan)\b'),
  RegExp(
    r'\b(mau|pengen|pengin|pingin|lagi|bakal|jadi|nanti|ntar|ini|besok) (makan|beli|pesan|pesen|order|jajan|nyari|cari|ngemil|ngopi) (apa|apaan)\b',
  ),
  RegExp(
    r'\b(ada|minta|kasih|kasi|butuh|perlu|boleh|bisa|tolong) (saran|sarannya|rekomendasi|rekomen|ide|usul|masukan|referensi|tips)\b',
  ),
  RegExp(
    r'\b(saran|sarannya|rekomen|rekomendasinya|ide|usul|referensi) (dong|donk|deh|ya|yuk|nih|plis|please|pls|dulu)\b',
  ),
  RegExp(r'\bmenurut ?(mu|kamu|lu|loe|elu|anda|kakak)\b'),
  RegExp(
    r'\b(bagusnya|baiknya|sebaiknya|mending|cocoknya) (makan|apa|beli|pesan|jajan|kemana|ke mana|dimana)\b',
  ),
  RegExp(r'\bapa (ya )?(yang )?(enak|bagus|oke|mantap|recommended|rekomen)\b'),
  RegExp(r'\b(yang|yg) (enak|bagus|oke|mantap) (apa|dimana|di mana|ya|nih)\b'),
  RegExp(
    r'\b(bingung|galau|pusing|ragu|labil|kebingungan)( nih| banget| bgt| deh| sih)* (mau |pilih |milih |buat |untuk |soal |mikir )?(makan|apa|pilih|milih|menu|pesan|jajan)\b',
  ),
  RegExp(
    r'\b(gak|ga|nggak|ngga|tidak|belum) (tau|tahu|kepikiran|punya ide) (mau |harus |lagi )?(makan|apa|pesan|pilih|menu)\b',
  ),
  RegExp(
    r'\b(lapar|laper|keroncongan|kelaparan|ngidam|lagi pengen|lagi pengin|lagi pingin|pengen sesuatu|pengin sesuatu)\b',
  ),
];

bool _isAdvice(String t) {
  final c = t
      .replaceAll(RegExp(r'[?!.,;:]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return _adviceRes.any((r) => r.hasMatch(c));
}

/// "yang terbaik", "paling enak", "favorit", "rating tertinggi", "wajib coba".
final _reBest = RegExp(
  r'\b(terbaik|terenak|terfavorit|terpopuler|terlaris|terbagus|ternikmat|paling (enak|bagus|top|populer|laris|favorit|recommended|rekomen|mantap|nikmat|juara)|rating (tertinggi|bagus|terbaik|tinggi)|bintang (5|lima)|favorit|populer|laris|hits|viral|juara|andalan|best|top|must ?try|wajib (coba|cicip|dicoba)|paling direkomendasikan)\b',
);

/// Minta diacak/dipilihkan (tanpa kata "bingung"/"gak tau", yang kini
/// dianggap minta saran, bukan acak).
final _reSurpriseStrong = RegExp(
  r'\b(kejutan|surprise|acak|random|terserah|bebas|pilihin|pilihkan|apa aja|apa saja|apa pun|apapun|tentuin|tentukan|undi|dadu|gacha|lempar koin|suit)\b',
);

final _reGreetExtra = RegExp(
  r'^(sugeng (enjing|siang|sonten|dalu)|kulo nuwun|punten|hallo+|halo+ kak|hai+ kak|hei+|hey+ kak|woi|oi|bro|sis|kak|assalamu ?alaikum|wa ?alaikum ?salam|salam kenal|selamat datang|good (morning|afternoon|evening)|morning|woy)\b',
);
final _reThanksExtra = RegExp(
  r'\b(matur nuwun|maturnuwun|tengkyu|thank ?u|thanks? (ya|banget|a lot)|tq|tks|terima kasih banyak|makasih banyak|makasih ya|mksh|makasi ya|thankyou)\b',
);
final _reByeExtra = RegExp(
  r'\b(sampai ketemu|sampai besok|sampai bertemu|pamit|cabut dulu|out dulu|gtg|good ?night|selamat tinggal|sampun|monggo|bye bye|babay|baibai|see you)\b',
);
final _reWhoExtra = RegExp(
  r'\b(namamu|nama kamu|nama lu|kamu (itu )?(robot|chatbot|asisten)|siapa yang (bikin|buat|membuat)|dibuat (oleh|sama)|kamu (dari|berasal)|kamu (pakai|pake) (apa|ai|gpt)|ini (bot|ai|chatbot) (ya|apa))\b',
);
final _reHelpExtra = RegExp(
  r'\b(bisa ngapain|bisa apa aja|apa aja yang bisa|ngapain aja|fungsimu|fungsi kamu|kegunaan|cara (nyari|mencari|cari|pakai|pake|pakainya|kerjanya|kerja)|gimana (cara )?(pakai|pake|kerjanya|kerja|nyarinya)|menu bantuan|apa saja yang bisa|bisa bantu apa)\b',
);
final _reDislikeExtra = RegExp(
  r'\b(skip|batal|ga jadi|gak jadi|nggak jadi|ngga jadi|tidak jadi|ga selera|gak selera|nggak selera|ngga selera|tidak selera|kurang menarik|kurang enak|kurang oke|kurang bagus|jelek|ogah|bukan itu|bukan yang itu|nope|nggak deh|gak deh|ga deh|ngga deh)\b',
);
final _reRaiseExtra = RegExp(
  r'\b(budget (ku |gue |gw |saya |aku )?(longgar|banyak|aman|bebas|besar|lebih)|(gak|ga|nggak|ngga|tidak) (masalah|apa apa|apa-apa|usah mikir) (mahal|harga|budget)|harga (bukan|ga|gak|nggak) (masalah|penting)|bebas harga|duit (banyak|aman)|uang (banyak|aman)|sultan|mewah|fine dining|yang mahalan|agak mahal|bayar mahal|istimewa|traktiran|ditraktir|traktir)\b',
);
final _reCheapExtra = RegExp(
  r'\b(budget (ku |gue |gw |saya |aku )?(tipis|mepet|terbatas|pas pasan|pas-pasan|minim|seadanya|sedikit)|uang (saku )?(tipis|mepet|pas pasan|pas-pasan|terbatas|seadanya)|dompet (tipis|kering)|kantong (tipis|kering)|anak kos|anak kost|ngirit|nge ?irit|tanggal tua|bokek|cekak|miskin|murah meriah|ramah kantong|hemat dong|mahasiswa|pelajar|kere)\b',
);

class _Query {
  const _Query({
    this.topics = const [],
    this.rawWords = const [],
    this.maxPrice,
    this.minPrice,
  });

  final List<_Topic> topics;
  final List<String> rawWords;
  final int? maxPrice;
  final int? minPrice;

  _Query copyWith({int? maxPrice, int? minPrice, bool clearMax = false}) {
    return _Query(
      topics: topics,
      rawWords: rawWords,
      maxPrice: clearMax ? null : (maxPrice ?? this.maxPrice),
      minPrice: minPrice ?? this.minPrice,
    );
  }
}

class _Price {
  const _Price(this.max, this.min);

  final int? max;
  final int? min;
}

/// FOODIE AI: mesin percakapan berbasis aturan (tanpa LLM).
///
/// Yang dilakukan:
/// - mengingat konteks ("yang lain", "lebih murah", "naikkan budget")
/// - membaca budget dengan benar ("25rb", "di bawah 30 ribu", "diatas 40k")
/// - bertanya balik kalau permintaan terlalu umum
/// - kalau tidak ada hasil, menawarkan jalan keluar (bukan buntu)
/// - jawaban bervariasi dan sadar waktu (pagi/siang/sore/malam)
/// - (v2) menjawab permintaan saran terbuka ("enaknya makan apa ya") dan
///   permintaan "yang terbaik" dengan rekomendasi berdasarkan rating
class FoodAi {
  FoodAi({required this.fetch, Random? random}) : _rng = random ?? Random();

  final RestaurantFetcher fetch;
  final Random _rng;

  static const num _unknown = double.maxFinite;

  // --- konteks percakapan ---
  _Query? _last;
  List<Restaurant> _pool = [];
  List<Restaurant> _lastPage = [];
  final Set<String> _shown = {};
  int? _needMax;
  int _unclear = 0;
  final Map<String, int> _lastPhrase = {};

  // =========================================================================
  // API publik
  // =========================================================================

  BotReply welcome({DateTime? now, bool again = false}) {
    final part = _dayPart(now ?? DateTime.now());
    final hello = again
        ? 'Siap, kita mulai dari awal! ✨'
        : 'Selamat $part! Aku FOODIE AI 👋';
    return BotReply(
      '$hello\n${_mealHint(part)}\n\n'
      'Ceritakan selera atau budget-mu, mis. "gudeg budget 25rb" atau '
      '"tempat ngopi buat nongkrong". Aku carikan dari daftar kuliner di '
      'aplikasi ini.',
      chips: _starterChips(part),
    );
  }

  void reset() {
    _last = null;
    _pool = [];
    _lastPage = [];
    _shown.clear();
    _needMax = null;
    _unclear = 0;
  }

  Future<BotReply> reply(String input, {DateTime? now}) async {
    final when = now ?? DateTime.now();
    final t = _norm(input);
    if (t.isEmpty) return _clarify(when);
    try {
      return await _route(t, when);
    } catch (_) {
      return BotReply(
        'Maaf, aku lagi kesulitan mengambil data kuliner. Coba lagi sebentar ya 🙏',
        chips: [QuickReply('Coba lagi', send: input)],
      );
    }
  }

  // =========================================================================
  // Routing intent
  // =========================================================================

  Future<BotReply> _route(String t, DateTime now) async {
    final words = t.split(' ').length;
    final hasCtx = _last != null && _pool.isNotEmpty;
    final hasTopic = _topics.any((x) => x.match.hasMatch(t));

    if (_reReset.hasMatch(t)) {
      reset();
      return welcome(now: now, again: true);
    }
    if (_reThanks.hasMatch(t)) return _thanks();
    if (_reThanksExtra.hasMatch(t)) return _thanks();
    if (_reBye.hasMatch(t)) return _bye();
    if (_reByeExtra.hasMatch(t)) return _bye();
    if (_reWho.hasMatch(t)) return _who();
    if (_reWhoExtra.hasMatch(t)) return _who();
    if (_reHelp.hasMatch(t)) return _help(now);
    if (!hasTopic && _reHelpExtra.hasMatch(t)) return _help(now);

    // --- tambahan v2: saran terbuka & "yang terbaik" ---
    // Dicek sebelum sapaan supaya "siang, enaknya makan apa ya?" tidak
    // dianggap sapaan biasa.
    final advice = !hasTopic && _isAdvice(t);
    if (_reSurpriseStrong.hasMatch(t)) return _surprise();
    if (advice) return _advice(t, now);
    if (!hasTopic && _reBest.hasMatch(t)) return _advice(t, now, best: true);

    if (words <= 4 && _reGreet.hasMatch(t) && !hasTopic) return _greet(now);
    if (words <= 4 && _reGreetExtra.hasMatch(t) && !hasTopic) {
      return _greet(now);
    }
    if (_reSurprise.hasMatch(t)) return _surprise();
    if (_reRaise.hasMatch(t)) return _raise(now);
    if (_reRaiseExtra.hasMatch(t) && hasCtx) return _raise(now);
    if (_reDislike.hasMatch(t)) return _dislike(now);
    if (!hasTopic && _reDislikeExtra.hasMatch(t)) return _dislike(now);
    if (_reCheaper.hasMatch(t) && hasCtx) return _cheaper(now);
    if (_reCheapExtra.hasMatch(t)) {
      return (hasCtx && !hasTopic) ? _cheaper(now) : _search('murah $t', now);
    }
    if (!hasTopic &&
        (_reMoreStrong.hasMatch(t) || (words <= 3 && _reLagi.hasMatch(t)))) {
      return _more(now);
    }
    if (!hasTopic && _reInfo.hasMatch(t)) return _info(now);
    if (words <= 3 && _reAck.hasMatch(t)) return _ack(now);
    return _search(t, now);
  }

  // =========================================================================
  // Saran terbuka (v2)
  // =========================================================================

  /// Topik yang cocok untuk waktu makan saat ini.
  _Topic _timeTopic(String part) {
    const byPart = {
      'pagi': 'sarapan',
      'siang': 'nasi',
      'sore': 'kopi & nongkrong',
      'malam': 'sate',
    };
    final label = byPart[part] ?? 'nasi';
    return _topics.firstWhere(
      (x) => x.label == label,
      orElse: () => _topics.first,
    );
  }

  /// Menjawab "enaknya makan apa ya", "bingung nih mau makan apa, ada saran
  /// ga?", "yang terbaik". Memilih tempat berdasarkan waktu makan, lalu
  /// mengurutkan dengan rating. Budget dibaca dari pesan atau percakapan
  /// sebelumnya.
  Future<BotReply> _advice(String t, DateTime now, {bool best = false}) async {
    final part = _dayPart(now);
    final price = _parsePrice(t);
    final maxP = price.max ?? _last?.maxPrice;
    final cheap = _reCheapWord.hasMatch(t) || _reCheapExtra.hasMatch(t);

    // 1) coba sesuai waktu makan; 2) kalau hasilnya sedikit, ambil semua.
    var q = _Query(
      topics: best ? const [] : [_timeTopic(part)],
      maxPrice: maxP,
      minPrice: price.min,
    );
    var res = await _gather(q, cheapest: cheap);
    if (res.length < 2 && q.topics.isNotEmpty) {
      q = _Query(maxPrice: maxP, minPrice: price.min);
      res = await _gather(q, cheapest: cheap);
    }

    if (res.isEmpty) {
      if (maxP == null && price.min == null) {
        return BotReply(
          'Hmm, daftar kulinernya belum bisa kuambil saat ini. Coba lagi sebentar ya 🙏',
          chips: [QuickReply('Coba lagi', send: t)],
        );
      }
      return _noResult(q);
    }
    if (!cheap) res.sort((a, b) => b.rating.compareTo(a.rating));

    final bud = maxP == null ? '' : ' (budget maks **${foodRp(maxP)}**)';
    final String lead;
    if (best) {
      lead = _say('best', [
        'Ini yang rating-nya paling tinggi di daftar kami$bud ⭐:',
        'Kalau cari yang paling juara$bud, ini dia ⭐:',
        'Berdasarkan rating$bud, ini yang paling top:',
      ]);
    } else if (cheap) {
      lead = _say('adviceCheap', [
        'Santai, ada kok yang ramah di kantong 😄 Ini yang paling hemat:',
        'Tenang, kantong aman! Ini opsi paling hemat$bud:',
      ]);
    } else {
      lead = _say('advice', [
        'Tenang, aku bantu pilihin! ${_mealHint(part)} Ini yang menurutku layak dicoba$bud:',
        'Gampang! ${_mealHint(part)} Coba lihat ini$bud:',
        'Oke, serahkan padaku 😄 ${_mealHint(part)} Ini rekomendasiku$bud:',
      ]);
    }
    return _present(q, res, lead: lead, cheapest: cheap);
  }

  // =========================================================================
  // Pencarian
  // =========================================================================

  Future<BotReply> _search(String t, DateTime now) async {
    final price = _parsePrice(t);
    final topics = _topics.where((x) => x.match.hasMatch(t)).take(2).toList();

    var rest = t;
    for (final x in topics) {
      rest = rest.replaceAll(x.match, ' ');
    }
    final raw = topics.isEmpty ? _rawWords(rest) : <String>[];

    final cheapest =
        _reCheapest.hasMatch(t) ||
        (_reCheapWord.hasMatch(t) && price.max == null);

    final q = _Query(
      topics: topics,
      rawWords: raw,
      maxPrice: price.max,
      minPrice: price.min,
    );

    final vague =
        topics.isEmpty &&
        raw.isEmpty &&
        price.max == null &&
        price.min == null &&
        !cheapest;
    if (vague) return _clarify(now);

    _unclear = 0;
    final res = await _gather(q, cheapest: cheapest);
    // v2: "soto terbaik", "kopi paling enak" -> urutkan dengan rating.
    if (_reBest.hasMatch(t) && !cheapest) {
      res.sort((a, b) => b.rating.compareTo(a.rating));
    }
    final out = await _present(q, res, cheapest: cheapest);

    // Pengguna menanyakan jam buka/alamat: jujur bahwa datanya tidak ada di sini.
    if (_reInfo.hasMatch(t) && out.cards.isNotEmpty) {
      return BotReply(
        '${out.text}\n\nSoal jam buka dan alamat, cek halaman detail tiap tempat ya.',
        cards: out.cards,
        chips: out.chips,
      );
    }
    return out;
  }

  Future<List<Restaurant>> _gather(_Query q, {bool cheapest = false}) async {
    final terms = <String>[for (final x in q.topics) ...x.terms, ...q.rawWords];

    final List<List<Restaurant>> batches;
    if (terms.isEmpty) {
      batches = [
        await fetch(
          maxPrice: q.maxPrice,
          sortBy: (cheapest || q.maxPrice != null) ? 'termurah' : null,
        ),
      ];
    } else {
      batches = await Future.wait(
        terms.take(6).map((term) => fetch(search: term, maxPrice: q.maxPrice)),
      );
    }

    final seen = <String>{};
    final out = <Restaurant>[];
    for (final b in batches) {
      for (final r in b) {
        if (seen.add(_key(r)) && _inRange(r, q)) out.add(r);
      }
    }
    if (cheapest) {
      out.sort((a, b) => _price(a).compareTo(_price(b)));
    }
    return out;
  }

  Future<BotReply> _present(
    _Query q,
    List<Restaurant> res, {
    bool cheapest = false,
    String? lead,
    bool keepSeen = false,
  }) async {
    _needMax = null;
    if (res.isEmpty) return _noResult(q);

    if (!keepSeen) _shown.clear();
    final fresh = res.where((r) => !_shown.contains(_key(r))).toList();
    final source = fresh.isNotEmpty ? fresh : res;
    final page = source.take(3).toList();

    _last = q;
    _pool = res;
    _lastPage = page;
    _shown.addAll(page.map(_key));
    final left = res.where((r) => !_shown.contains(_key(r))).length;

    final desc = _describe(q, cheapest: cheapest);
    final String open;
    if (lead != null) {
      open = lead;
    } else if (page.length == 1) {
      open = _say('open1', [
        'Ketemu satu yang pas untuk $desc:',
        'Untuk $desc, ini satu-satunya yang cocok saat ini:',
        'Hmm, baru ada satu untuk $desc. Ini dia:',
      ]);
    } else {
      open = _say('open', [
        'Nah, untuk $desc ini yang menurutku layak dicoba:',
        'Dapat! Untuk $desc, coba lihat ini:',
        'Oke, sudah kucek untuk $desc. Ini pilihannya:',
        'Siap! Buat $desc, ini beberapa opsi yang cocok:',
      ]);
    }

    String? tip;
    if (page.length >= 2) {
      final sorted = [...page]..sort((a, b) => _price(a).compareTo(_price(b)));
      final cheap = sorted.first;
      if (_price(cheap) != _unknown && _price(cheap) != _price(sorted.last)) {
        tip = _say('tip', [
          'Paling hemat: **${cheap.name}** (${_priceText(cheap)}).',
          'Kalau mau yang ramah di kantong, **${cheap.name}** paling murah — ${_priceText(cheap)}.',
        ]);
      }
    }

    final String follow;
    if (left > 0) {
      follow = _say('left', [
        'Masih ada $left pilihan lain kalau mau lihat.',
        'Ada $left opsi lagi yang belum kutampilkan.',
      ]);
    } else {
      follow = _say('follow', [
        'Kalau belum cocok, bilang aja — bisa kupersempit lewat budget atau jenis makanan.',
        'Ada preferensi lain? Misalnya budget atau suasana yang kamu mau.',
        'Mau kuubah kriterianya? Tinggal bilang.',
      ]);
    }

    final minP = page.map(_price).reduce((a, b) => a < b ? a : b);
    final hasCheaper = res.any((r) => _price(r) < minP);

    final chips = <QuickReply>[
      if (left > 0) QuickReply('Yang lain'),
      if (hasCheaper) QuickReply('Lebih murah'),
      if (q.maxPrice != null) QuickReply('Naikkan budget'),
      QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      QuickReply('Mulai ulang'),
    ];

    final tipLine = tip == null ? '' : '\n$tip';
    return BotReply(
      '$open$tipLine\n\n$follow',
      cards: page,
      chips: chips.take(4).toList(),
    );
  }

  Future<BotReply> _noResult(_Query q) async {
    _last = null;
    _pool = [];
    _lastPage = [];
    _shown.clear();
    final desc = _describe(q);

    // Ada budget? Cari yang paling mendekati tanpa batas budget.
    if (q.maxPrice != null) {
      final broad = await _gather(q.copyWith(clearMax: true));
      final priced = broad.where((r) => _price(r) != _unknown).toList()
        ..sort((a, b) => _price(a).compareTo(_price(b)));
      if (priced.isNotEmpty) {
        final best = priced.first;
        _last = q;
        _pool = priced;
        _lastPage = [best];
        _shown.add(_key(best));
        _needMax = _price(best).ceil();
        return BotReply(
          'Untuk $desc belum ada yang pas. Yang paling dekat dengan budgetmu: '
          '**${best.name}** — ${_priceText(best)}.\n\n'
          'Mau kunaikkan budgetnya sedikit?',
          cards: [best],
          chips: [
            QuickReply('Naikkan budget'),
            QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
            QuickReply('Mulai ulang'),
          ],
        );
      }
    }

    return BotReply(
      _say('none', [
        'Hmm, aku belum menemukan $desc di daftar kami 🤔. Mungkin namanya beda, atau memang belum ada.',
        'Belum ketemu $desc nih. Coba kata lain, atau pilih salah satu di bawah?',
        'Wah, $desc belum ada di daftar. Mau coba jenis lain?',
      ]),
      chips: _starterChips().take(4).toList(),
    );
  }

  // =========================================================================
  // Aksi lanjutan (butuh konteks)
  // =========================================================================

  BotReply _more(DateTime now) {
    final q = _last;
    if (q == null || _pool.isEmpty) {
      return _clarify(
        now,
        lead: 'Belum ada pencarian yang bisa kulanjutkan. Mau cari apa dulu?',
      );
    }
    final unseen = _pool.where((r) => !_shown.contains(_key(r))).toList();
    if (unseen.isEmpty) {
      final desc = _describe(q);
      if (q.maxPrice != null) {
        return BotReply(
          'Itu semua yang cocok untuk $desc. Mau kunaikkan budgetnya sedikit?',
          chips: [
            QuickReply('Naikkan budget'),
            QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
            QuickReply('Mulai ulang'),
          ],
        );
      }
      return BotReply(
        'Itu semua yang kutemukan untuk $desc. Mau coba jenis lain?',
        chips: _starterChips().take(4).toList(),
      );
    }

    final page = unseen.take(3).toList();
    _shown.addAll(page.map(_key));
    _lastPage = page;
    final left = unseen.length - page.length;

    final open = _say('more', [
      'Ini opsi lainnya:',
      'Oke, masih ada nih:',
      'Boleh, coba yang ini:',
      'Lanjut! Ini beberapa lagi:',
    ]);
    final tail = left > 0
        ? _say('moreLeft', [
            'Masih ada $left lagi kalau belum cocok.',
            'Sisa $left opsi lagi.',
          ])
        : _say('moreEnd', [
            'Itu semua yang cocok untuk saat ini.',
            'Segitu dulu pilihan yang kutemukan.',
          ]);

    final minP = page.map(_price).reduce((a, b) => a < b ? a : b);
    final chips = <QuickReply>[
      if (left > 0) QuickReply('Yang lain'),
      if (_pool.any((r) => _price(r) < minP)) QuickReply('Lebih murah'),
      QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      QuickReply('Mulai ulang'),
    ];
    return BotReply(
      '$open\n\n$tail',
      cards: page,
      chips: chips.take(4).toList(),
    );
  }

  BotReply _cheaper(DateTime now) {
    final q = _last;
    if (q == null) return _clarify(now);

    final num ref = _lastPage.isEmpty
        ? _unknown
        : _lastPage.map(_price).reduce((a, b) => a < b ? a : b);
    final cheaper = _pool.where((r) => _price(r) < ref).toList()
      ..sort((a, b) => _price(a).compareTo(_price(b)));

    if (cheaper.isEmpty) {
      return BotReply(
        _say('cheapest', [
          'Yang tadi sudah termasuk paling murah untuk ${_describe(q)} 👍',
          'Untuk ${_describe(q)}, harga segitu sudah paling rendah yang kutemukan.',
        ]),
        chips: [
          QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
          ..._starterChips().take(2),
          QuickReply('Mulai ulang'),
        ],
      );
    }

    final page = cheaper.take(3).toList();
    _pool = cheaper;
    _shown
      ..clear()
      ..addAll(page.map(_key));
    _lastPage = page;
    _last = q.copyWith(maxPrice: _price(page.last).ceil());
    final left = cheaper.length - page.length;

    final chips = <QuickReply>[
      if (left > 0) QuickReply('Yang lain'),
      QuickReply('Naikkan budget'),
      QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      QuickReply('Mulai ulang'),
    ];
    return BotReply(
      _say('cheaper', [
        'Oke, ini yang lebih ramah di kantong:',
        'Siap, kuturunkan harganya. Coba ini:',
        'Boleh banget, ini opsi yang lebih hemat:',
      ]),
      cards: page,
      chips: chips.take(4).toList(),
    );
  }

  Future<BotReply> _raise(DateTime now) async {
    final q = _last;
    if (q == null) {
      return _clarify(
        now,
        lead: 'Budget-nya mau dinaikkan jadi berapa? Sebut aja nominalnya, mis. "gudeg 40rb".',
      );
    }
    final base = q.maxPrice ?? 20000;
    var next = _roundUp5k(base * 1.5);
    final need = _needMax;
    if (need != null && next < need) next = _roundUp5k(need);

    final nq = q.copyWith(maxPrice: next);
    final res = await _gather(nq);
    return _present(
      nq,
      res,
      keepSeen: true,
      lead: 'Oke, budget kunaikkan jadi **${foodRp(next)}**. Ini opsinya:',
    );
  }

  Future<BotReply> _surprise() async {
    final cap = _last?.maxPrice;
    var list = await fetch(maxPrice: cap);
    if (list.isEmpty && cap != null) list = await fetch();
    if (list.isEmpty) {
      return BotReply(
        'Hmm, daftar kulinernya lagi kosong. Coba lagi sebentar ya.',
        chips: _starterChips().take(3).toList(),
      );
    }

    final unseen = list.where((r) => !_shown.contains(_key(r))).toList();
    final source = unseen.isNotEmpty ? unseen : list;
    final pick = source[_rng.nextInt(source.length)];

    _last = _Query(maxPrice: cap);
    _pool = list;
    _lastPage = [pick];
    _shown.add(_key(pick));

    final line = '${prettyCategory(pick.category)} • ${_priceText(pick)}';
    final text = _say('surprise', [
      'Kalau aku yang pilih… **${pick.name}**! 🎯\n$line',
      'Pilihan acakku: **${pick.name}**.\n$line\nDicoba dulu, siapa tahu cocok!',
      'Gas ke **${pick.name}**! Anggap aja ini takdir kuliner 😄\n$line',
    ]);
    return BotReply(
      text,
      cards: [pick],
      chips: [
        QuickReply('🎲 Kasih kejutan lagi', send: 'kasih kejutan lagi'),
        QuickReply('☕ Ngopi & nongkrong', send: 'ngopi nongkrong'),
        QuickReply('💸 Budget 25rb', send: 'budget 25rb'),
        QuickReply('Mulai ulang'),
      ],
    );
  }

  // =========================================================================
  // Obrolan ringan
  // =========================================================================

  BotReply _clarify(DateTime now, {String? lead}) {
    _unclear++;
    final part = _dayPart(now);
    final base =
        lead ??
        _say('clarify', [
          'Boleh tahu lagi pengin yang mana? Sebutkan jenis makanan atau budget-mu, atau pilih salah satu di bawah.',
          'Biar tepat sasaran: ${_mealHint(part)} Mau cari yang seperti apa?',
          'Aku butuh sedikit petunjuk nih 😄 — jenis makanan, budget, atau suasana yang kamu mau?',
        ]);
    if (_unclear >= 2) {
      return BotReply(
        '$base\n\nKalau masih bingung, serahkan saja padaku 🎲',
        chips: [
          QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
          ..._starterChips(part).take(3),
        ],
      );
    }
    return BotReply(base, chips: _starterChips(part));
  }

  BotReply _greet(DateTime now) {
    final part = _dayPart(now);
    return BotReply(
      _say('greet', [
        'Halo juga! 👋 ${_mealHint(part)} Mau cari apa?',
        'Hai! Selamat $part 😊 ${_mealHint(part)}',
        'Halo! Aku siap bantu cari kuliner. ${_mealHint(part)}',
      ]),
      chips: _starterChips(part),
    );
  }

  BotReply _thanks() {
    return BotReply(
      _say('thanks', [
        'Sama-sama! 😊 Kalau mau cari tempat lain, tinggal bilang ya.',
        'Senang bisa membantu! Selamat menikmati 🍽️',
        'Siap! Semoga cocok di lidah. Ada lagi yang mau dicari?',
      ]),
      chips: [
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
        QuickReply('Mulai ulang'),
      ],
    );
  }

  BotReply _bye() {
    return BotReply(
      _say('bye', [
        'Sampai jumpa! Selamat makan 🍽️',
        'Dah! Kalau lapar lagi, panggil aku ya 👋',
      ]),
    );
  }

  BotReply _who() {
    return BotReply(
      'Aku FOODIE AI, asisten yang membantu memilih kuliner DIY & Jawa Tengah '
      'dari daftar di aplikasi ini. Aku mencari berdasarkan jenis makanan dan '
      'budget. Info seperti jam buka real-time dan ulasan belum bisa kubaca, '
      'ya.',
      chips: _starterChips().take(4).toList(),
    );
  }

  BotReply _help(DateTime now) {
    return BotReply(
      'Aku bisa bantu:\n'
      '• Cari makanan: "soto", "gudeg", "kopi"\n'
      '• Pakai budget: "bakmi di bawah 30rb"\n'
      '• Lanjutkan: "yang lain", "lebih murah", "naikkan budget"\n'
      '• Bingung? Tanya "enaknya makan apa ya?" atau "yang terbaik"\n'
      '• Mau diacak? Ketik "kasih kejutan"\n\n'
      'Catatan: aku mencari dari data menu dan harga di aplikasi, jadi belum bisa cek jam buka real-time.',
      chips: _starterChips(_dayPart(now)).take(4).toList(),
    );
  }

  BotReply _info(DateTime now) {
    return BotReply(
      'Jam buka, alamat, dan rute lengkap ada di halaman detail tiap tempat '
      '(tab Explore). Aku bantu menyaring dari jenis makanan dan budget dulu '
      'ya — mau cari apa?',
      chips: _starterChips(_dayPart(now)).take(4).toList(),
    );
  }

  BotReply _ack(DateTime now) {
    return BotReply(
      _say('ack', [
        'Siap! Ada lagi yang mau dicari?',
        'Oke 👍 Mau kucarikan yang lain?',
        'Sip! Tinggal bilang kalau butuh rekomendasi lagi.',
      ]),
      chips: _starterChips(_dayPart(now)).take(4).toList(),
    );
  }

  BotReply _dislike(DateTime now) {
    final hasCtx = _last != null && _pool.isNotEmpty;
    return BotReply(
      _say('dislike', [
        'Oke, bukan yang itu ya. Mau kuubah di bagian mana?',
        'Noted! Bagian mana yang kurang pas — harga, atau jenis makanannya?',
        'Siap, kita cari arah lain. Pilih salah satu, atau ceritakan maunya.',
      ]),
      chips: [
        if (hasCtx) QuickReply('Lebih murah'),
        ..._starterChips(_dayPart(now)).take(hasCtx ? 3 : 4),
      ],
    );
  }

  // =========================================================================
  // Helper
  // =========================================================================

  String _key(Restaurant r) => '${r.name}|${r.category}';

  /// Harga terendah; 0 / tidak ada dianggap "belum tercatat".
  num _price(Restaurant r) {
    final p = r.priceMin;
    return p > 0 ? p : _unknown;
  }

  String _priceText(Restaurant r) {
    final p = r.priceMin;
    return p > 0 ? 'mulai ${foodRp(p)}' : 'harga belum tercatat';
  }

  bool _inRange(Restaurant r, _Query q) {
    final p = r.priceMin;
    if (p <= 0) return true; // harga tidak diketahui: jangan dibuang
    final mx = q.maxPrice;
    final mn = q.minPrice;
    if (mx != null && p > mx) return false;
    if (mn != null && p < mn) return false;
    return true;
  }

  int _roundUp5k(num v) => (v / 5000).ceil() * 5000;

  String _describe(_Query q, {bool cheapest = false}) {
    String? topic;
    if (q.topics.isNotEmpty) {
      final names = q.topics.map((x) => x.label).join(' / ');
      topic = '**$names**';
    } else if (q.rawWords.isNotEmpty) {
      final raw = q.rawWords.join(' ');
      topic = '**$raw**';
    }
    if (cheapest) {
      topic = topic == null
          ? 'pilihan **paling hemat**'
          : '$topic yang **paling hemat**';
    }

    String? price;
    final mx = q.maxPrice;
    final mn = q.minPrice;
    if (mx != null && mn != null) {
      price = 'budget **${foodRp(mn)} – ${foodRp(mx)}**';
    } else if (mx != null) {
      price = 'budget maks **${foodRp(mx)}**';
    } else if (mn != null) {
      price = 'harga di atas **${foodRp(mn)}**';
    }

    if (topic != null && price != null) return '$topic dengan $price';
    return topic ?? price ?? 'seleramu';
  }

  /// Pilih satu kalimat acak, hindari mengulang yang sama dua kali berturut-turut.
  String _say(String key, List<String> options) {
    if (options.length == 1) return options.first;
    var i = _rng.nextInt(options.length);
    if (i == _lastPhrase[key]) i = (i + 1) % options.length;
    _lastPhrase[key] = i;
    return options[i];
  }

  String _dayPart(DateTime now) {
    final h = now.hour;
    if (h >= 4 && h < 11) return 'pagi';
    if (h >= 11 && h < 15) return 'siang';
    if (h >= 15 && h < 18) return 'sore';
    return 'malam';
  }

  String _mealHint(String part) {
    switch (part) {
      case 'pagi':
        return 'Cocok buat sarapan nih 🍳';
      case 'siang':
        return 'Pas banget buat makan siang 🍛';
      case 'sore':
        return 'Waktunya ngemil atau ngopi sore ☕';
      default:
        return 'Mau makan malam atau cari yang hangat-hangat? 🌙';
    }
  }

  List<QuickReply> _starterChips([String? part]) {
    final meal = part == 'pagi'
        ? QuickReply('🥣 Sarapan', send: 'sarapan')
        : QuickReply('🍚 Makan berat', send: 'makan nasi');
    return [
      meal,
      QuickReply('☕ Ngopi & nongkrong', send: 'ngopi nongkrong'),
      QuickReply('🥟 Jajan', send: 'jajan'),
      QuickReply('💸 Budget 25rb', send: 'budget 25rb'),
      QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
    ];
  }

  String _norm(String s) {
    var t = s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    // 25.000 -> 25000
    for (var i = 0; i < 3; i++) {
      t = t.replaceAllMapped(
        RegExp(r'(\d)\.(\d{3})(?!\d)'),
        (m) => '${m[1]}${m[2]}',
      );
    }
    return t;
  }

  List<String> _rawWords(String s) {
    return s
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stop.contains(w))
        .take(2)
        .toList();
  }

  /// Membaca budget: "25rb", "25 ribu", "30k", "25000", "di bawah 30rb",
  /// "diatas 40k". Angka tanpa satuan seperti "2 orang" diabaikan.
  _Price _parsePrice(String s) {
    final ctx = RegExp(
      r'\b(budget|harga|duit|uang|dana|bayar|maks|max|maksimal|dibawah|di bawah|kurang dari|under|sampai|paling mahal)\b',
    ).hasMatch(s);

    int? maxV;
    int? minV;
    final numRe = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(rb|ribu|ribuan|rebu|k|jt|juta)?(?![a-z])',
    );
    final blocked = RegExp(
      r'^\s*(orang|org|porsi|pax|km|meter|m\b|jam|menit|hari|kali|biji|buah|bintang)',
    );

    for (final m in numRe.allMatches(s)) {
      final n = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (n == null) continue;
      if (blocked.hasMatch(s.substring(m.end))) continue;

      final unit = m.group(2);
      double value;
      if (unit == 'jt' || unit == 'juta') {
        value = n * 1000000;
      } else if (unit != null) {
        value = n * 1000;
      } else if (n >= 1000) {
        value = n;
      } else if (ctx && n >= 5 && n <= 500) {
        value = n * 1000;
      } else {
        continue;
      }

      final from = m.start - 18 < 0 ? 0 : m.start - 18;
      final before = s.substring(from, m.start);
      final isMin = RegExp(r'(di ?atas|minimal|min\b|lebih dari|>|mulai dari)')
          .hasMatch(before);
      if (isMin) {
        minV ??= value.round();
      } else {
        maxV ??= value.round();
      }
    }
    return _Price(maxV, minV);
  }
}
