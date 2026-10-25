/// Jenis sajian (kolom dish_type di database) -> label dan ikon cadangan.
/// Nilai dish_type diturunkan dari NAMA tempat lewat kata kunci,
/// jadi ini "jenis sajian berdasarkan nama", BUKAN daftar menu asli.
class DishType {
  final String label;
  final String emoji; // dipakai bila foto belum tersedia

  const DishType(this.label, this.emoji);
}

const Map<String, DishType> dishTypes = {
  'nasi_padang': DishType('Nasi Padang', '🍛'),
  'soto': DishType('Soto & Rawon', '🍲'),
  'bakso': DishType('Bakso', '🍢'),
  'mie': DishType('Mie & Ramen', '🍜'),
  'ayam': DishType('Ayam & Bebek', '🍗'),
  'sate': DishType('Sate', '🍢'),
  'seafood': DishType('Seafood & Ikan', '🦐'),
  'masakan_jawa': DishType('Masakan Jawa', '🍚'),
  'bakpia': DishType('Bakpia', '🥮'),
  'burger_pizza': DishType('Burger & Pizza', '🍔'),
  'steak': DishType('Steak & Grill', '🥩'),
  'kopi': DishType('Kopi', '☕'),
  'minuman_kue': DishType('Minuman & Kue', '🧁'),
  'jepang_korea': DishType('Jepang & Korea', '🍣'),
  'chinese': DishType('Chinese Food', '🥟'),
  'warung_nasi': DishType('Warung & Nasi', '🍽️'),
};

/// Ikon cadangan per kategori, dipakai bila dish_type tidak diketahui.
const Map<String, String> categoryEmoji = {
  'restoran': '🍽️',
  'cafe': '☕',
  'fast_food': '🍔',
  'food_court': '🏬',
};

/// Label untuk ditampilkan, atau null bila jenis sajian tidak diketahui.
String? dishLabel(String? dishType) => dishTypes[dishType]?.label;
