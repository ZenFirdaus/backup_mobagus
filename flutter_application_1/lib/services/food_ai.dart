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
    'bebek': 'Bebek & Unggas',
    'padang': 'Masakan Padang',
    'mie_pedas': 'Mie Pedas Kekinian',
    'seblak': 'Seblak & Baso Aci',
    'rawon': 'Rawon & Daging Sapi',
    'pempek': 'Pempek & Palembang',
    'ayce': 'All You Can Eat',
    'healthy': 'Makanan Sehat',
    'tradisional': 'Kuliner Tradisional',
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
  _Topic('gudeg', RegExp(r'\b(gudeg|krecek|nangka muda)\b'), [
    'gudeg',
    'krecek',
  ]),
  _Topic('soto', RegExp(r'\b(soto|sroto|coto|saoto|tauto)\b'), ['soto']),
  _Topic(
    'bakmi & mie',
    RegExp(r'\b(bakmi|bakmie|mie|mi|bakmi jawa|mie lethek|mie ongklok)\b'),
    ['bakmi', 'mie'],
  ),
  _Topic('bakso', RegExp(r'\b(bakso|baso|pentol|bakso urat|bakso bakar)\b'), [
    'bakso',
  ]),
  _Topic(
    'ayam',
    RegExp(
      r'\b(ayam|geprek|ayam bakar|ayam goreng|kalasan|kremes|ayam penyet)\b',
    ),
    ['ayam', 'geprek'],
  ),
  _Topic(
    'bebek & unggas',
    RegExp(
      r'\b(bebek|menthok|entok|puyuh|burung dara|bebek goreng|bebek madura|bebek sinjay|bebek bakar)\b',
    ),
    ['bebek', 'menthok', 'puyuh'],
  ),
  _Topic(
    'sate',
    RegExp(
      r'\b(sate|satay|sate klatak|klathak|taichan|sate kambing|sate ayam|sate buntel)\b',
    ),
    ['sate'],
  ),
  _Topic(
    'nasi',
    RegExp(
      r'\b(nasi|sego|rice|nasgor|nasi goreng|nasi liwet|nasi uduk|nasi kuning|nasi rames|nasi campur|nasi bakar|nasi berkat)\b',
    ),
    ['nasi', 'sego'],
  ),
  _Topic(
    'masakan padang',
    RegExp(
      r'\b(padang|nasi padang|rendang|gulai tunjang|dendeng|ayam pop|kapau|minang|balado)\b',
    ),
    ['padang', 'rendang', 'gulai', 'dendeng'],
  ),
  _Topic(
    'seafood',
    RegExp(
      r'\b(seafood|ikan|lele|udang|cumi|kepiting|gurame|nila|bawal|cakalang|kerang|pecel lele|ikan bakar)\b',
    ),
    ['seafood', 'ikan', 'lele', 'udang'],
  ),
  _Topic(
    'makanan pedas & mercon',
    RegExp(
      r'\b(pedas|pedes|sambal|sambel|oseng mercon|mercon|rica|jebew|nampol|pedas mampus)\b',
    ),
    ['pedas', 'sambal', 'mercon'],
  ),
  _Topic(
    'mie pedas & kekinian',
    RegExp(
      r'\b(mie gacoan|gacoan|wizzmie|mie level|mie pedas|mie pedes|mie jebew|mie setan|mie iblis|mie nyemek)\b',
    ),
    ['gacoan', 'mie', 'pedas'],
  ),
  _Topic(
    'seblak & baso aci',
    RegExp(
      r'\b(seblak|baso aci|boci|cuanki|cilok kuah|makaroni basah|makaroni pedas)\b',
    ),
    ['seblak', 'cuanki', 'bakso'],
  ),
  _Topic(
    'rawon, iga & daging',
    RegExp(
      r'\b(rawon|empal|empal gentong|sei sapi|sei|daging sapi|beef|bistik|sop buntut|iga sapi|iga penyet|selat solo)\b',
    ),
    ['rawon', 'sapi', 'iga', 'empal'],
  ),
  _Topic(
    'pempek',
    RegExp(
      r'\b(pempek|empek|mpek|kapal selam|lenjer|adaan|cuko|tekwan|model)\b',
    ),
    ['pempek', 'tekwan'],
  ),
  _Topic(
    'kopi & nongkrong',
    RegExp(
      r'\b(kopi|coffee|ngopi|nongkrong|cafe|kafe|wfh|santai|wfc|colokan|nongki|espresso|latte|cappuccino|manual brew)\b',
    ),
    ['coffee', 'kopi', 'cafe'],
  ),
  _Topic(
    'jajanan & camilan',
    RegExp(
      r'\b(jajan|jajanan|camilan|cemilan|snack|ngemil|siomay|batagor|gorengan|cilok|cireng|mendoan|geblek|tahu gejrot|pisang goreng|tahu bakso)\b',
    ),
    ['jajan', 'siomay', 'snack', 'gorengan'],
  ),
  _Topic(
    'cepat saji',
    RegExp(
      r'\b(fast ?food|cepat saji|burger|pizza|hotdog|kentang goreng|french fries)\b',
    ),
    ['fast_food', 'burger', 'pizza'],
  ),
  _Topic(
    'roti, pastry & kue',
    RegExp(
      r'\b(roti|kue|bakery|donat|dessert|manis|cake|pastry|croissant|croffle|toast|roti bakar)\b',
    ),
    ['roti', 'bakery', 'kue', 'dessert'],
  ),
  _Topic(
    'es & minuman segar',
    RegExp(
      r'\b(es|minuman|boba|jus|teh|teh poci|es teh|dingin|segar|seger|cendol|dawet|es campur|es teler|es kelapa|smoothie|matcha|thai tea)\b',
    ),
    ['es', 'jus', 'minuman', 'teh', 'boba'],
  ),
  _Topic(
    'all you can eat & buffet',
    RegExp(
      r'\b(all you can eat|ayce|buffet|prasmanan|shabu|shabu shabu|sukiyaki|suki|steamboat|hotpot|korean bbq|kbbq)\b',
    ),
    ['buffet', 'shabu', 'grill', 'bbq'],
  ),
  _Topic(
    'vegetarian & sayur',
    RegExp(r'\b(vegetarian|vegan|sayur|lalapan|capcay|urap|tumis)\b'),
    ['vegetarian', 'vegan', 'sayur'],
  ),
  _Topic(
    'restoran',
    RegExp(
      r'\b(restoran|resto|restaurant|rumah makan|warung makan|bistro|eatery)\b',
    ),
    ['restaurant', 'resto'],
  ),
  _Topic(
    'sarapan',
    RegExp(
      r'\b(sarapan|breakfast|bubur|bubur ayam|buryam|lontong|lontong sayur|lontong opor|sego berkat)\b',
    ),
    ['bubur', 'lontong', 'sarapan'],
  ),
  _Topic(
    'martabak & kue cubit',
    RegExp(
      r'\b(martabak|terang bulan|kue cubit|pukis|kue pancong|pancong|lekker|crepes)\b',
    ),
    ['martabak', 'terang bulan', 'cubit'],
  ),
  _Topic(
    'angkringan',
    RegExp(
      r'\b(angkringan|wedangan|wedang|hik|nasi kucing|sego kucing|kucingan|wedang jahe|wedang ronde|kopi joss|bajigur|wedang uwuh)\b',
    ),
    ['angkringan', 'wedang', 'kucing'],
  ),
  _Topic(
    'bakpia & oleh-oleh',
    RegExp(
      r'\b(bakpia|oleh ?oleh|geplak|yangko|mochi|souvenir|buah tangan|pia|enting)\b',
    ),
    ['bakpia', 'oleh', 'yangko'],
  ),
  _Topic(
    'tengkleng & tongseng',
    RegExp(
      r'\b(tengkleng|tongseng|gulai|kambing|sate kambing|krengsengan|kikil)\b',
    ),
    ['tengkleng', 'tongseng', 'gulai', 'kambing'],
  ),
  _Topic(
    'pecel & rujak',
    RegExp(
      r'\b(pecel|rujak|gado ?gado|lotek|karedok|tahu campur|tahu tek|tahu telur|lontong sayur)\b',
    ),
    ['pecel', 'rujak', 'gado'],
  ),
  _Topic(
    'penyetan & lalapan',
    RegExp(r'\b(penyet|penyetan|lalap|lalapan|pecel lele|sambal lalap)\b'),
    ['penyet', 'lalap'],
  ),
  _Topic(
    'sop & berkuah',
    RegExp(
      r'\b(sop|sup|konro|iga|berkuah|kuah|hangat|anget|hujan|timlo|sayur asem|kaldu)\b',
    ),
    ['sop', 'konro', 'kuah'],
  ),
  _Topic(
    'steak & panggang',
    RegExp(
      r'\b(steak|bbq|barbeque|grill|panggang|bakaran|iga bakar|ribs?|bistik)\b',
    ),
    ['steak', 'grill', 'bbq'],
  ),
  _Topic(
    'masakan asia',
    RegExp(
      r'\b(ramen|sushi|jepang|japanese|korea|korean|bibimbap|dimsum|dim sum|chinese|china|thai|india|asia|bento|katsu|udon|tomyam)\b',
    ),
    ['ramen', 'sushi', 'dimsum', 'korea'],
  ),
  _Topic(
    'pasta & western',
    RegExp(
      r'\b(pasta|spaghetti|italia|italian|western|sandwich|lasagna|mac and cheese)\b',
    ),
    ['pasta', 'italia', 'western'],
  ),
  _Topic(
    'es krim',
    RegExp(r'\b(es krim|eskrim|ice ?cream|gelato|sundae|froyo)\b'),
    ['ice_cream', 'es krim', 'gelato'],
  ),
  _Topic(
    'makanan sehat',
    RegExp(
      r'\b(sehat|healthy|diet|salad|clean eating|rendah kalori|low calorie|tanpa minyak|jus detoks)\b',
    ),
    ['salad', 'healthy', 'sehat'],
  ),
  _Topic(
    'kuliner khas & legendaris',
    RegExp(
      r'\b(khas|tradisional|legendaris|lawas|jadul|klasik|autentik|asli|ikonik|turun temurun|khas jogja|khas solo)\b',
    ),
    ['gudeg', 'soto', 'sate', 'bakmi'],
  ),
  _Topic(
    'makan bareng keluarga',
    RegExp(
      r'\b(keluarga|arisan|rombongan|ramean|ramai ramai|reuni|acara|syukuran|ulang tahun|ramah anak|playground|kids friendly)\b',
    ),
    ['restaurant', 'food_court'],
  ),
  _Topic(
    'suasana alam & estetik',
    RegExp(
      r'\b(view bagus|pemandangan|alam|sawah|gunung|rooftop|sunset|instagramable|estetik|aesthetic|foto foto|outdoor|sejuk|syahdu|adem)\b',
    ),
    ['cafe', 'restaurant'],
  ),
  _Topic(
    'suasana romantis',
    RegExp(
      r'\b(romantis|kencan|candle ?light|dinner date|anniversary|tempat date|nge ?date)\b',
    ),
    ['restaurant', 'cafe'],
  ),
  _Topic(
    'makan larut malam',
    RegExp(
      r'\b(tengah malam|begadang|lembur|24 jam|dini hari|midnight|larut malam|kuliner malam|ronda)\b',
    ),
    ['angkringan', 'nasi', 'bakmi'],
  ),
  _Topic(
    'halal & muslim friendly',
    RegExp(
      r'\b(halal|no pork|tanpa babi|non pork|aman muslim|muslim friendly)\b',
    ),
    ['ayam', 'sapi', 'nasi', 'soto'],
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
  // --- tambahan v3: slang daerah, panggilan, & filler ---
  'tenan',
  'poll',
  'pol',
  'lur',
  'mas',
  'mbak',
  'boss',
  'bos',
  'cuy',
  'gan',
  'rek',
  'bro',
  'sis',
  'mimin',
  'kek',
  'gini',
  'gitu',
  'macam',
  'kayak',
  'koyo',
  'sing',
  'iku',
  'iki',
  'piye',
  'opo',
  'ning',
  'neng',
  'karo',
  'kui',
  'punya',
  'bikin',
  'bikinin',
  'golek',
  'nyari',
  'hunting',
  'santai',
  'cozy',
  'pewe',
  'pw',
  'asik',
  'parah',
  'gaskeun',
  'kuy',
  'skuy',
  'santuy',
  'time',
  'nongki',
  'kongkow',
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
  r'\b(bantuan|help|bisa apa|fitur|cara pakai|cara kerja|gimana cara (pakai|pake|kerja|kerjanya)|panduan|tutorial)\b',
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
  r'\b((gak|ga|nggak|ngga|tidak|bukan) (cocok|suka|mau|itu|sreg|pas)|kurang (cocok|suka|sreg|pas)|bosen|bosan|ganti (makanan|menu|opsi|pilihan|tempat|resto|jenis)|beda jenis|jenis lain|makanan lain)\b',
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
  // Tambahan v3 (bahasa daerah Jawa & slang populer):
  RegExp(
    r'\b(luwe|keluwen|weteng luwe|ngelak|ngorong|mangan opo|madhang opo|medhang opo|golek mangan|golek maem|nyari maem)\b',
  ),
  RegExp(
    r'\b(rekomendasi kuliner|rekomendasi makanan|kuliner enak|kuliner hits|makanan viral|tempat makan enak|kuliner mantap|hunting kuliner)\b',
  ),
  RegExp(
    r'\b(pengen ngunyah|pengen nyemil|pengen makan|butuh asupan|butuh amunisi|craving|bm makan|food craving)\b',
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
  r'^(sugeng (enjing|siang|sonten|dalu)|kulo nuwun|sampun|monggo|punten|hallo+|halo+ kak|hai+ kak|hei+|hey+ kak|woi|oi|bro|sis|kak|assalamu ?alaikum|wa ?alaikum ?salam|salam kenal|selamat datang|good (morning|afternoon|evening)|morning|woy)\b',
);
final _reThanksExtra = RegExp(
  r'\b(matur nuwun|maturnuwun|suwun sanget|tengkyu|thank ?u|thanks? (ya|banget|a lot)|tq|tks|terima kasih banyak|makasih banyak|makasih ya|mksh|makasi ya|thankyou)\b',
);
final _reByeExtra = RegExp(
  r'\b(sampai ketemu|sampai besok|sampai bertemu|pamit|cabut dulu|out dulu|gtg|good ?night|selamat tinggal|sampun|monggo|bye bye|babay|baibai|see you|tidur dulu)\b',
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
  r'\b(budget (ku |gue |gw |saya |aku )?(tipis|mepet|terbatas|pas pasan|pas-pasan|minim|seadanya|sedikit)|uang (saku )?(tipis|mepet|pas pasan|pas-pasan|terbatas|seadanya)|dompet (tipis|kering)|kantong (tipis|kering)|anak kos|anak kost|ngirit|nge ?irit|tanggal tua|bokek|cekak|miskin|murah meriah|ramah kantong|hemat dong|mahasiswa|pelajar|kere|murmer)\b',
);

// ---------------------------------------------------------------------------
// REGEX DETEKSI DI LUAR RANAH KULINER (OUT-OF-DOMAIN ERROR HANDLING)
// ---------------------------------------------------------------------------

/// 1. Teknologi, Pemrograman, IT, Hardware, Gadget
final _reTechOutOfDomain = RegExp(
  r'\b(koding|coding|pemrograman|programmer|javascript|python|flutter|dart|golang|html|css|php|sql|database|github|syntax|compiler|framework|software|komputer|laptop|pc|processor|ram|vga|gpu|intel|amd|windows|linux|macos|android studio|vs code|handphone|smartphone|gadget|iphone|xiaomi|samsung|baterai bocor|blue screen|wifi lemot|router|ip address|hacker|script|source code)\b',
  caseSensitive: false,
);

/// 2. Politik, Pemerintahan, Hukum, Pejabat Negara
final _rePoliticsOutOfDomain = RegExp(
  r'\b(presiden|wapres|wakil presiden|menteri|kementerian|dpr|mpr|dpd|pilpres|pemilu|pilkada|partai politik|pdi|gerindra|golkar|jokowi|prabowo|gibran|anies|ganjar|gubernur|walikota|bupati|undang ?undang|pasal hukum|pidana|perdata|korupsi|kpk|demo|demonstrasi|kebijakan pemerintah|apbn|bumn|sengketa)\b',
  caseSensitive: false,
);

/// 3. Sains, Matematika, Akademik, Sekolah, Teori
final _reAcademicOutOfDomain = RegExp(
  r'\b(rumus|matematika|kalkulus|aljabar|trigonometri|fisika|kimia|biologi|gravitasi|kecepatan cahaya|tata surya|planet|galaksi|revolusi industri|perang dunia|pr sekolah|tugas sekolah|skripsi|makalah|penemu benua|siapa penemu|teori relativitas|fotosintesis|tabel periodik|integral|diferensial|hitung luas|hitung volume)\b',
  caseSensitive: false,
);

/// 4. Otomotif, Mesin, Kendaraan
final _reAutomotiveOutOfDomain = RegExp(
  r'\b(ganti oli|oli mesin|bengkel motor|bengkel mobil|tambal ban|ban bocor|knalpot|kampas rem|radiator|karburator|injeksi|tune up|servis motor|servis mobil|motor mogok|mobil mogok|sparepart|spion|velg|speedometer|transmisi|kopling|avanza|innova|honda beat|vario|nmax|pcx)\b',
  caseSensitive: false,
);

/// 5. Percintaan, Asmara, Curhat, Zodiak
final _reRomanceOutOfDomain = RegExp(
  r'\b(balikan sama mantan|mantan pacar|mantan|selingkuh|diselingkuhi|patah hati|putus cinta|cara nembak|nembak gebetan|tips pacaran|zodiak|horoskop|ramalan bintang|aries|taurus|gemini|cancer|leo|virgo|libra|scorpio|sagitarius|capricorn|aquarius|pisces|jodohku|siapa jodoh|puisi cinta|kata gombal|gombalan)\b',
  caseSensitive: false,
);

/// 6. Finansial, Saham, Crypto, Pinjaman Online
final _reFinanceOutOfDomain = RegExp(
  r'\b(saham|ihsg|crypto|cryptocurrency|bitcoin|btc|ethereum|eth|trading|forex|pinjol|pinjaman online|reksadana|pasar modal|dividen|bursa efek|investasi emas|paylater|bunga pinjaman|kredit rumah|kpr|kartu kredit)\b',
  caseSensitive: false,
);

/// 7. Kesehatan Medis Umum, Penyakit Berat, Obat Farmasi
final _reMedicalOutOfDomain = RegExp(
  r'\b(penyakit jantung|gejala diabetes|stroke|kanker|tumor|obat flu|paracetamol|amoxicillin|antibiotik|dosis obat|resep dokter|operasi usus|luka bakar|luka bernanah|infeksi saluran|rumah sakit|dokter spesialis|tensi darah|kolesterol tinggi|asam urat parah)\b',
  caseSensitive: false,
);

/// 8. Olahraga & Hiburan / Gaming Non-Kuliner
final _reEntertainmentOutOfDomain = RegExp(
  r'\b(skor bola|hasil pertandingan|liga inggris|premier league|liga champion|champions league|la liga|serie a|piala dunia|world cup|timnas indonesia|mobile legends|mlbb|free fire|pubg|valorant|dota|cheat game|chord lagu|kunci gitar|lirik lagu|link nonton|anime sub indo)\b',
  caseSensitive: false,
);

/// 9. Tugas Generatif Teks Umum / General AI
final _reGeneralAiOutOfDomain = RegExp(
  r'\b(terjemahkan|terjemahin|translate|buatkan puisi|bikin puisi|bikin cerpen|cerita dongeng|rangkum artikel|ringkas teks|siapa pencipta alam|apa arti hidup|siapa penemu|dimana letak negara|ibukota negara)\b',
  caseSensitive: false,
);

/// Mendeteksi teks acak / keyboard mash / spam huruf nir-makna
bool _isGibberish(String s) {
  final clean = s.trim().toLowerCase();
  if (clean.isEmpty) return false;

  // Hanya karakter simbol tanpa huruf / angka
  if (RegExp(r'^[^a-zA-Z0-9\s]+$').hasMatch(clean)) return true;

  // Repetisi huruf sama berturut-turut 4x atau lebih (mis. "aaaaaaa", "zzzzz")
  if (RegExp(r'([a-zA-Z])\1{3,}').hasMatch(clean)) return true;

  // Rangkaian 5 konsonan berturut-turut tanpa vokal (mis. "dfghjk", "zxcvb")
  if (RegExp(r'\b[bcdfghjklmnpqrstvwxyz]{5,}\b').hasMatch(clean)) return true;

  // Pola keyboard mash populer
  const mashes = [
    'asdf',
    'qwerty',
    'zxcv',
    'hjkl',
    'qazwsx',
    'poiuy',
    'mnbvc',
    'lkjhg',
    'fdsa',
    'ytrewq',
    'trewq',
    'gfdsa',
  ];
  if (mashes.any((k) => clean.contains(k)) && clean.length >= 6) {
    return true;
  }

  return false;
}

/// Menentukan apakah input mengandung indikator kuliner, makanan, minuman, kafe,
/// rasa, atau waktu makan yang sah.
bool _hasCulinaryIntent(String t) {
  // 1. Cocok dengan topik kuliner
  if (_topics.any((x) => x.match.hasMatch(t))) return true;

  // 2. Cocok dengan ekspresi saran / rasa lapar terbuka
  if (_isAdvice(t)) return true;

  // 3. Kata kunci seputar makanan, minuman, tempat, dan rasa
  final foodKeywords = RegExp(
    r'\b(makan|makanan|minum|minuman|kuliner|jajan|jajanan|cemilan|camilan|ngemil|sarapan|maksi|lunch|dinner|supper|santap|cicip|ngopi|warung|resto|restoran|kafe|cafe|kedai|angkringan|lesehan|food ?court|bistro|dapur|menu|porsi|lapar|laper|luwe|ngelak|haus|kenyang|wareg|ngidam|craving|enak|lezat|nikmat|pedas|pedes|manis|asin|gurih|segar|seger|hangat|anget|dingin|boba|kopi|nasi|mie|bakso|soto|ayam|bebek|sate|gudeg|seafood|ikan|steak|burger|pizza|roti|kue|es|jus|teh)\b',
    caseSensitive: false,
  );
  if (foodKeywords.hasMatch(t)) return true;

  return false;
}

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
        ? 'Siap, kita mulai dari awal!'
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

    // --- Error handling out-of-domain (di luar ranah kuliner) ---
    if (!hasTopic && !_hasCulinaryIntent(t)) {
      final outReply = _handleOutOfDomain(t, now);
      if (outReply != null) return outReply;
    }

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

    // Proteksi tambahan: jika kata yang dicari murni non-kuliner tanpa intensi atau harga
    if (topics.isEmpty &&
        !_hasCulinaryIntent(t) &&
        price.max == null &&
        price.min == null &&
        !cheapest) {
      return _outOfScopeGeneralError(now);
    }

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
          'Kalau mau yang ramah di kantong, **${cheap.name}** paling murah (${_priceText(cheap)}).',
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
        'Kalau belum cocok, bilang saja. Bisa kupersempit lewat budget atau jenis makanan.',
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
          '**${best.name}** (${_priceText(best)}).\n\n'
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
          'Aku butuh sedikit petunjuk nih 😄: jenis makanan, budget, atau suasana yang kamu mau?',
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
      '(tab Explore). Aku bantu menyaring dari jenis makanan dan budget dulu, '
      'mau cari apa?',
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
        'Noted! Bagian mana yang kurang pas, harga atau jenis makanannya?',
        'Siap, kita cari arah lain. Pilih salah satu, atau ceritakan maunya.',
      ]),
      chips: [
        if (hasCtx) QuickReply('Lebih murah'),
        ..._starterChips(_dayPart(now)).take(hasCtx ? 3 : 4),
      ],
    );
  }

  // =========================================================================
  // Error Handling: Permintaan / Pertanyaan di Luar Ranah Kuliner
  // =========================================================================

  BotReply? _handleOutOfDomain(String t, DateTime now) {
    if (_isGibberish(t)) return _gibberishError(now);
    if (_reTechOutOfDomain.hasMatch(t)) return _techError(now);
    if (_rePoliticsOutOfDomain.hasMatch(t)) return _politicsError(now);
    if (_reAcademicOutOfDomain.hasMatch(t)) return _academicError(now);
    if (_reAutomotiveOutOfDomain.hasMatch(t)) return _automotiveError(now);
    if (_reRomanceOutOfDomain.hasMatch(t)) return _romanceError(now);
    if (_reFinanceOutOfDomain.hasMatch(t)) return _financeError(now);
    if (_reMedicalOutOfDomain.hasMatch(t)) return _medicalError(now);
    if (_reEntertainmentOutOfDomain.hasMatch(t)) {
      return _entertainmentError(now);
    }
    if (_reGeneralAiOutOfDomain.hasMatch(t)) return _generalAiError(now);

    // Pertanyaan umum yang sama sekali tidak berhubungan dengan kuliner
    final isGeneralNonFoodQuestion = RegExp(
      r'^(siapa|apa|kenapa|mengapa|bagaimana|gimana|berapa|dimana|kapan)\b',
    ).hasMatch(t);

    if (isGeneralNonFoodQuestion) {
      return _outOfScopeGeneralError(now);
    }

    return null;
  }

  BotReply _techError(DateTime now) {
    final text = _say('errTech', [
      'Waduh, kalau soal pemrograman, koding, atau teknologi di luar keahlianku nih! 💻👨‍💻\n\n'
          'Sebagai **FOODIE AI**, spesialisasiku adalah mencarikan kuliner lezat, kafe kece, dan tempat makan asik di DIY & Jawa Tengah.\n\n'
          'Tapi kalau lagi pusing ngoding atau nugas IT, ngopi santai atau makan camilan manis biasanya ampuh banget buat booster fokus ☕🍰. Mau kucarikan kafe buat nugas atau tempat ngemil?',
      'Wah, urusan coding atau hardware komputer di luar ranahku! 🤖\n\n'
          'FOODIE AI hadir khusus buat urusan perut: rekomendasi tempat makan, kafe nyaman ber-WiFi, dan kuliner mantap di Jogja & Jateng.\n\n'
          'Biar kepalamu tetap segar, mending cari asupan enak dulu yuk! Mau kucarikan kopi atau makanan?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('☕ Kafe buat nugas & WFC', send: 'kafe buat nugas wfc'),
        QuickReply('🥐 Kopi & camilan', send: 'kopi dan camilan'),
        QuickReply('🍚 Makan kenyang', send: 'makan nasi'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _politicsError(DateTime now) {
    final text = _say('errPolitics', [
      'Wah, kalau urusan politik, pemerintahan, atau isu pemilu bukan ranahku nih! 🏛️🗳️\n\n'
          'Sebagai **FOODIE AI**, aku fokus 100% pada dunia kuliner lezat, tempat nongkrong, dan rekomendasi resto terbaik di DIY & Jawa Tengah.\n\n'
          'Daripada pusing mikirin politik, mending kita isi perut dengan yang lezat-lezat yuk! Lagi pengin makan apa hari ini?',
      'Waduh, aku asisten kuliner, jadi tidak membahas topik politik atau isu birokrasi ya! 🍽️\n\n'
          'Kalau soal soto enak, gudeg legendaris, atau tempat ngopi asik, serahkan padaku! Mau kucarikan kuliner mantap?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🍲 Soto berkuah hangat', send: 'soto'),
        QuickReply('🍛 Nasi padang mantap', send: 'nasi padang'),
        QuickReply('🍗 Ayam geprek pedas', send: 'ayam geprek'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _academicError(DateTime now) {
    final text = _say('errAcademic', [
      'Aduh, kalau rumus matematika, fisika, atau tugas sekolah di luar jangkauanku nih! 📐🔬\n\n'
          'Aku asisten kuliner yang siap memandu lidahmu ke tempat makan paling nikmat dan ramah kantong di Jogja & sekitarnya.\n\n'
          'Belajar keras pastinya butuh asupan energi kan? Mau kucarikan makanan enak penambah stamina?',
      'Wah, urusan sains dan hitung-hitungan rumus akademis bukan keahlianku! 📚\n\n'
          'Keahlianku adalah menyesuaikan budget kuliner biar kamu bisa makan enak tanpa bikin kantong bolong. Mau rekomendasi makanan apa?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🍜 Bakmi & mie kenyang', send: 'bakmi mie'),
        QuickReply('🥣 Sarapan & bubur', send: 'sarapan bubur'),
        QuickReply('☕ Kopi penyemangat', send: 'kopi nongkrong'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _automotiveError(DateTime now) {
    final text = _say('errAuto', [
      'Waduh, kalau urusan mesin kendaraan, bengkel, atau otomotif aku kurang paham nih! 🚗🔧\n\n'
          'Sebagai **FOODIE AI**, tugasku adalah memandu urusan perut dan selera kulinermu di wilayah DIY & Jawa Tengah.\n\n'
          'Kalau motormu butuh bensin, perutmu juga butuh asupan lezat kan? Yuk cari kuliner mantap di sekitar sini!',
      'Urusan sparepart dan servis mesin di luar keahlianku! 🛵\n\n'
          'Tapi kalau perutmu yang butuh "diservis" dengan hidangan enak, serahkan padaku! Mau makan apa?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🍗 Ayam & bebek gurih', send: 'ayam bebek'),
        QuickReply('🍲 Sop & kuah hangat', send: 'sop berkuah'),
        QuickReply('🍚 Angkringan & sego kucing', send: 'angkringan'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _romanceError(DateTime now) {
    final text = _say('errRomance', [
      'Wah, kalau urusan asmara, zodiak, atau tips percintaan di luar keahlianku nih! 💔❤️\n\n'
          'Sebagai **FOODIE AI**, keahlian utamaku adalah mencarikan kuliner lezat di DIY & Jawa Tengah.\n\n'
          'Tapi konon makanan enak bisa langsung naikin mood lho! Atau kalau kamu butuh tempat romantis buat nge-date bareng si dia, aku siap carikan ✨',
      'Urusan hati memang rumit, tapi urusan perut jangan sampai telat! 🍽️\n\n'
          'Mau kuliner manis pelipur lara, atau tempat makan estetik dengan suasana romantis? Bilang aja!',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('✨ Tempat date romantis', send: 'suasana romantis'),
        QuickReply('🍨 Gelato & dessert manis', send: 'es krim gelato'),
        QuickReply('☕ Kafe syahdu & tenang', send: 'kafe santai'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _financeError(DateTime now) {
    final text = _say('errFinance', [
      'Kalau soal investasi saham, crypto, trading, atau urusan pinjaman di luar ranahku nih! 📈🪙\n\n'
          'Tapi kalau urusan "investasi perut" yang hemat, lezat, dan ramah kantong di DIY & Jawa Tengah, serahkan padaku!\n\n'
          'Sebut saja budget makanmu (misal *di bawah 20rb* atau *budget gocap*), nanti kucarikan tempat yang paling pas 💸',
      'Wah, aku bukan penasihat keuangan atau broker crypto nih! 💰\n\n'
          'Tapi aku jago banget mencarikan makanan murah meriah yang pas di kantong mahasiswa maupun sultan. Mau cari makan dengan budget berapa?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('💸 Hemat di bawah 20rb', send: 'budget 20rb'),
        QuickReply('☕ Angkringan murah meriah', send: 'angkringan murah'),
        QuickReply('🍚 Warung makan kenyang', send: 'warung makan'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _medicalError(DateTime now) {
    final text = _say('errMedical', [
      'Untuk keluhan penyakit, dosis obat, atau masalah medis umum, sangat disarankan berkonsultasi langsung dengan dokter atau tenaga medis profesional ya! 🩺💊\n\n'
          'Sebagai **FOODIE AI**, tugasku adalah merekomendasikan kuliner di DIY & Jawa Tengah.\n\n'
          'Kalau kamu sedang mencari makanan sehat, sup hangat, atau jus segar penambah daya tahan tubuh, aku siap bantu carikan!',
      'Aku bukan dokter, jadi tidak bisa mendiagnosis penyakit atau meresepkan obat ya! 🏥\n\n'
          'Namun kalau tubuhmu butuh asupan berkuah hangat atau makanan bernutrisi penambah tenaga, aku punya banyak pilihannya.',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🥗 Makanan sehat & salad', send: 'makanan sehat'),
        QuickReply('🍲 Sop & kuah hangat', send: 'sop berkuah'),
        QuickReply('🧃 Jus buah segar', send: 'jus segar'),
        QuickReply('🥣 Bubur hangat', send: 'bubur sarapan'),
      ],
    );
  }

  BotReply _entertainmentError(DateTime now) {
    final text = _say('errEnt', [
      'Waduh, kalau skor pertandingan olahraga, game, atau hiburan umum aku belum update nih! 🎮⚽\n\n'
          'Sebagai **FOODIE AI**, aku ahlinya kuliner dan kafe di Jogja & Jateng.\n\n'
          'Tapi kalau kamu butuh camilan enak atau minuman segar buat nemenin nobar atau mabar game, aku punya banyak rekomendasi mantap!',
      'Urusan gaming atau liga bola di luar keahlianku! 🏆\n\n'
          'Tapi kalau camilan kriuk, pizza, atau kopi susu buat nemenin push rank, serahkan padaku! Mau kucarikan?',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🥟 Camilan & gorengan', send: 'jajan camilan'),
        QuickReply('🍕 Pizza & cepat saji', send: 'cepat saji'),
        QuickReply('☕ Kopi kekinian', send: 'kopi nongkrong'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _generalAiError(DateTime now) {
    final text = _say('errGeneralAi', [
      'Maaf ya, aku tidak dirancang untuk tugas umum seperti penerjemahan bahasa atau penulisan kreatif non-kuliner. 🍽️\n\n'
          'Aku adalah **FOODIE AI**, asisten khusus kuliner DIY & Jawa Tengah! Aku bisa bantu cari tempat makan enak, kafe nongkrong, makanan khas, hingga menu yang pas dengan budgetmu.\n\n'
          'Yuk ceritakan, kamu lagi pengin makan apa hari ini?',
      'Sebagai asisten khusus kuliner, ruang lingkupku terfokus pada makanan, minuman, dan tempat makan di wilayah DIY & Jateng! 🍜\n\n'
          'Coba tanyakan seputar rekomendasi kuliner, budget makan, atau suasana tempat makan yang kamu cari ya.',
    ]);
    return BotReply(
      text,
      chips: [
        QuickReply('🍚 Rekomendasi makan siang', send: 'makan siang'),
        QuickReply('☕ Tempat nongkrong santai', send: 'ngopi nongkrong'),
        QuickReply('💸 Kuliner hemat kantong', send: 'budget 25rb'),
        QuickReply('🎲 Kasih kejutan', send: 'kasih kejutan'),
      ],
    );
  }

  BotReply _gibberishError(DateTime now) {
    final text = _say('errGibberish', [
      'Waduh, ketikanmu seperti acak atau kurang jelas nih! 😅\n\n'
          'Yuk ceritakan kamu lagi pengin kuliner seperti apa? Kamu bisa sebut jenis makanan (mis. *soto*, *kopi*, *geprek*), budget, atau langsung pilih salah satu opsi di bawah:',
      'Hmm, sepertinya ada salah ketik nih 🤔. Pesanmu belum bisa kupahami.\n\n'
          'Biar gampang, kamu mau cari makanan apa hari ini? Atau pilih menu cepat berikut:',
    ]);
    return BotReply(text, chips: _starterChips(_dayPart(now)));
  }

  BotReply _outOfScopeGeneralError(DateTime now) {
    final text = _say('errOutOfScope', [
      'Hmm, pertanyaanmu sepertinya di luar ranah kuliner nih! 🍽️\n\n'
          'Sebagai **FOODIE AI**, lingkup keahlianku adalah seputar dunia makanan, minuman, kafe, dan restoran di DIY & Jawa Tengah. Aku belum bisa menjawab topik umum di luar kuliner.\n\n'
          'Coba tanyakan seputar makanan favoritmu, budget makan, atau suasana tempat yang kamu inginkan ya!',
      'Wah, maaf ya! Pertanyaan tersebut di luar topik kulinarku. 🥣\n\n'
          'FOODIE AI didedikasikan untuk membantu pecinta kuliner menemukan tempat makan terbaik di DIY & Jawa Tengah. Mau kucarikan rekomendasi kuliner lezat?',
    ]);
    return BotReply(text, chips: _starterChips(_dayPart(now)));
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
        : (part == 'siang'
              ? QuickReply('🍚 Makan siang', send: 'makan siang')
              : QuickReply('🍛 Makan malam', send: 'makan malam'));
    return [
      meal,
      QuickReply('☕ Ngopi & nongkrong', send: 'ngopi nongkrong'),
      QuickReply('🥟 Jajan & camilan', send: 'jajan camilan'),
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

  /// Membaca budget dengan dukungan:
  /// - Format angka standar: "25rb", "25 ribu", "30k", "25000", "di bawah 30rb", "diatas 40k"
  /// - Rentang harga: "15-25rb", "10k - 20k", "antara 20 sampai 35 ribu"
  /// - Slang mata uang Indonesia: "ceban", "gocap", "noban", "seceng", "cepek", "pego", dll.
  _Price _parsePrice(String s) {
    // 1. Cek rentang harga terlebih dahulu
    final rangeRe = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:rb|ribu|k)?\s*(?:-|–|sampai|sd|s/d|hingga)\s*(\d+(?:[.,]\d+)?)\s*(rb|ribu|ribuan|rebu|k|jt|juta)?(?![a-z])',
      caseSensitive: false,
    );
    final rangeM = rangeRe.firstMatch(s);
    if (rangeM != null) {
      final n1 = double.tryParse(rangeM.group(1)!.replaceAll(',', '.'));
      final n2 = double.tryParse(rangeM.group(2)!.replaceAll(',', '.'));
      final unit = rangeM.group(3)?.toLowerCase();
      if (n1 != null && n2 != null) {
        double v1 = n1;
        double v2 = n2;
        if (unit == 'jt' || unit == 'juta') {
          if (v1 < 1000) v1 *= 1000000;
          if (v2 < 1000) v2 *= 1000000;
        } else {
          if (v1 < 1000) v1 *= 1000;
          if (v2 < 1000) v2 *= 1000;
        }
        final minVal = v1 < v2 ? v1 : v2;
        final maxVal = v1 < v2 ? v2 : v1;
        return _Price(maxVal.round(), minVal.round());
      }
    }

    int? maxV;
    int? minV;

    // 2. Cek slang mata uang Indonesia (ceban, gocap, dsb)
    const slangMap = {
      'seceng': 1000,
      'noceng': 2000,
      'goceng': 5000,
      'ceban': 10000,
      'noban': 20000,
      'gocap': 50000,
      'cepek': 100000,
      'pego': 150000,
      'nocun': 200000,
      'gocun': 500000,
      'sejeti': 1000000,
      'jeti': 1000000,
    };

    for (final entry in slangMap.entries) {
      final re = RegExp('\\b${entry.key}\\b', caseSensitive: false);
      final m = re.firstMatch(s);
      if (m != null) {
        final from = m.start - 18 < 0 ? 0 : m.start - 18;
        final before = s.substring(from, m.start);
        final isMin = RegExp(
          r'(di ?atas|minimal|min\b|lebih dari|>|mulai dari)',
        ).hasMatch(before);
        if (isMin) {
          minV ??= entry.value;
        } else {
          maxV ??= entry.value;
        }
      }
    }

    // 3. Pola numerik umum
    final ctx = RegExp(
      r'\b(budget|harga|duit|uang|dana|bayar|maks|max|maksimal|dibawah|di bawah|kurang dari|under|sampai|paling mahal)\b',
    ).hasMatch(s);

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

      final unit = m.group(2)?.toLowerCase();
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
