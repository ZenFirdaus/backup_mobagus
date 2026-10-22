import '../models/food.dart';
import '../models/restaurant.dart';
import 'format.dart';

/// "cafe" -> "Cafe", "fast_food" -> "Fast food".
String niceCategory(String raw) {
  final s = raw.trim().replaceAll('_', ' ');
  if (s.isEmpty) return 'Lainnya';
  return s[0].toUpperCase() + s.substring(1);
}

String _title(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .map(
      (w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
    )
    .join(' ');

// ===========================================================================
// CABANG
// ===========================================================================

/// Hasil membaca nama restoran: nama dasar (brand), label cabang, dan apakah
/// namanya memuat kata "cabang/branch/outlet".
class BranchInfo {
  const BranchInfo(this.brand, this.label, this.hasKeyword);

  final String brand;
  final String? label;
  final bool hasKeyword;
}

final _kwRe = RegExp(
  r'\b(cabang|branch|cab\.?|outlet|gerai)\b[\s:.\-]*(.*)$',
  caseSensitive: false,
);
final _parenRe = RegExp(r'\s*\(([^)]+)\)\s*$');
final _dashRe = RegExp(r'\s+[-–—]\s+(.+)$');

BranchInfo branchOf(Restaurant r) {
  final name = r.name.trim();
  var brand = name;
  String? label;
  var keyword = false;

  final kw = _kwRe.firstMatch(name);
  if (kw != null && kw.start > 0) {
    brand = name.substring(0, kw.start);
    label = kw.group(2);
    keyword = true;
  } else {
    final paren = _parenRe.firstMatch(name);
    if (paren != null && paren.start > 0) {
      brand = name.substring(0, paren.start);
      label = paren.group(1);
    } else {
      final dash = _dashRe.firstMatch(name);
      if (dash != null && dash.start > 0) {
        brand = name.substring(0, dash.start);
        label = dash.group(1);
      }
    }
  }

  brand = brand.replaceAll(RegExp(r'[\s\-–—,:]+$'), '').trim();
  if (brand.isEmpty) brand = name;
  final l = label?.trim();
  return BranchInfo(brand, (l == null || l.isEmpty) ? null : l, keyword);
}

String brandName(Restaurant r) => branchOf(r).brand;

/// Kunci untuk mencocokkan cabang dari brand yang sama.
String brandKey(Restaurant r) {
  final k = branchOf(r).brand
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return k.isEmpty ? r.name.toLowerCase() : k;
}

/// Jumlah restoran per brand pada daftar yang sedang dimuat.
Map<String, int> brandCounts(List<Restaurant> list) {
  final m = <String, int>{};
  for (final r in list) {
    final k = brandKey(r);
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

/// Cabang kalau namanya memuat kata cabang, atau ada restoran lain dengan
/// brand yang sama (minimal 4 karakter supaya nama generik tidak ikut).
bool isBranchOf(Restaurant r, Map<String, int> counts) {
  if (branchOf(r).hasKeyword) return true;
  final k = brandKey(r);
  return k.length >= 4 && (counts[k] ?? 0) > 1;
}

/// Wilayah singkat dari alamat: bagian terakhir setelah koma, atau jalannya.
String areaLabel(Restaurant r) {
  final parts = r.address
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length >= 2) return _title(parts.last);
  if (parts.isNotEmpty) return _title(parts.first);
  return r.province.isEmpty ? 'Lokasi lain' : _title(r.province);
}

/// Label cabang untuk ditampilkan: dari nama kalau ada, kalau tidak dari alamat.
String branchLabel(Restaurant r) {
  final l = branchOf(r).label;
  if (l != null && l.isNotEmpty) return _title(l);
  return areaLabel(r);
}

// ===========================================================================
// DESKRIPSI OTOMATIS
// ===========================================================================

String _kind(String category) {
  final c = category.toLowerCase();
  if (c.contains('cafe') || c.contains('coffee') || c.contains('kopi')) {
    return 'kafe';
  }
  if (c.contains('fast')) return 'gerai makanan cepat saji';
  if (c.contains('bakery') || c.contains('roti')) return 'toko roti dan kue';
  if (c.contains('ice')) return 'kedai es krim';
  if (c.contains('court')) return 'food court';
  if (c.contains('bar') || c.contains('pub')) return 'bar';
  if (c.contains('warung')) return 'warung makan';
  if (c.contains('resto')) return 'restoran';
  return 'tempat makan';
}

const _vibes = <String, List<String>>{
  'kafe': [
    'Cocok untuk nongkrong santai, ngobrol bersama teman, atau bekerja sambil menikmati kopi.',
    'Pilihan yang pas untuk menikmati minuman dan camilan dalam suasana santai.',
  ],
  'restoran': [
    'Cocok untuk makan bersama keluarga maupun teman.',
    'Bisa jadi pilihan untuk makan siang atau makan malam bersama orang terdekat.',
  ],
  'gerai makanan cepat saji': [
    'Praktis untuk santap cepat saat waktu terbatas.',
    'Pilihan tepat ketika butuh makan tanpa menunggu lama.',
  ],
  'toko roti dan kue': [
    'Cocok untuk membeli roti dan kue, baik untuk sarapan maupun oleh-oleh.',
  ],
  'kedai es krim': [
    'Tempat yang pas untuk menyegarkan diri dengan hidangan dingin.',
  ],
  'food court': [
    'Banyak pilihan hidangan dalam satu tempat, praktis untuk rombongan.',
  ],
  'bar': ['Cocok untuk bersantai dan bertemu teman di waktu senggang.'],
  'warung makan': ['Menyajikan hidangan harian dengan suasana yang sederhana.'],
  'tempat makan': [
    'Bisa jadi pilihan untuk makan bersama keluarga maupun teman.',
    'Cocok disinggahi saat sedang mencari tempat makan di sekitar sini.',
  ],
};

int _seed(String s) =>
    s.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

String _list(List<String> items) {
  if (items.length == 1) return items.first;
  if (items.length == 2) return '${items[0]} dan ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')}, dan ${items.last}';
}

/// Deskripsi tempat. Memakai `description` dari database bila ada; bila
/// kosong, disusun dari data yang benar-benar dimiliki (kategori, alamat,
/// harga, jam buka, menu, rating Google, cabang). Tidak mengarang fakta.
String buildDescription(
  Restaurant r, {
  List<Food> foods = const [],
  bool isBranch = false,
  int siblingCount = 0,
}) {
  final custom = r.description?.trim();
  if (custom != null && custom.isNotEmpty) return custom;

  final seed = _seed(r.id + r.name);
  final kind = _kind(r.category);
  final info = branchOf(r);
  final area = areaLabel(r);
  final province = r.province.trim();
  final where =
      (province.isNotEmpty && province.toLowerCase() != area.toLowerCase())
      ? '$area, $province'
      : area;

  final out = <String>[];

  out.add('${isBranch ? info.brand : r.name} adalah $kind di $where.');

  final vibes = _vibes[kind] ?? _vibes['tempat makan']!;
  out.add(vibes[seed % vibes.length]);

  if (r.priceMin > 0) {
    if (r.priceMax > r.priceMin) {
      final avg = (r.priceMin + r.priceMax) / 2;
      final tier = avg <= 30000
          ? 'tergolong terjangkau'
          : (avg <= 80000 ? 'berada di kisaran menengah' : 'tergolong premium');
      out.add('Kisaran harganya ${r.priceRange} ($tier).');
    } else {
      out.add('Harga mulai dari ${formatRp(r.priceMin)}.');
    }
  }

  if (foods.isNotEmpty) {
    final names = <String>[];
    for (final f in foods) {
      final n = f.name.trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
      if (names.length == 3) break;
    }
    final rest = foods.length - names.length;
    if (names.isNotEmpty) {
      out.add(
        'Menu yang tersedia antara lain ${_list(names)}'
        '${rest > 0 ? ', serta $rest menu lainnya' : ''}.',
      );
    }
  }

  final hours = r.openingHours?.trim();
  if (hours != null && hours.isNotEmpty) {
    out.add('Jam operasional: $hours.');
  }

  if (r.reviewCount > 0) {
    out.add(
      'Mendapat rating ${r.rating.toStringAsFixed(1)} dari '
      '${r.reviewCount} ulasan di Google.',
    );
  }

  if (isBranch) {
    out.add(
      'Ini adalah salah satu cabang ${info.brand}'
      '${siblingCount > 0 ? ' (ada ${siblingCount + 1} cabang di daftar kami)' : ''}. '
      'Menu dan harga bisa berbeda di tiap cabang.',
    );
  }

  return out.join(' ');
}
