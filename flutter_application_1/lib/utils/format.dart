/// Format angka jadi "Rp25.000".
String formatRp(num v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}

/// Format label kategori agar rapi (misal fast_food -> Fast Food)
String formatCategoryLabel(String c) => switch (c.trim().toLowerCase()) {
      'fast_food' || 'fast food' => 'Fast Food',
      'food_court' || 'food court' => 'Food Court',
      'cafe' || 'kafe' => 'Cafe',
      'restoran' || 'restaurant' => 'Restoran',
      'warung_tradisional' || 'warung tradisional' || 'warung' =>
        'Warung Tradisional',
      'angkringan' => 'Angkringan',
      _ => c
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' '),
    };

