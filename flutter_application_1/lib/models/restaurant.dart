class Restaurant {
  final String id;
  final String name;
  final String category;
  final String? cuisine;
  final String address;
  final String province;
  final double lat;
  final double lng;
  final int priceMin;
  final int priceMax;
  final String? openingHours;
  final String? imageUrl;
  final String? phone;
  final String? website;
  final DateTime createdAt;
  final double rating;
  final int reviewCount;
  final String? description;
  final String? kabupatenKota;
  final String? dishType;

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    this.cuisine,
    required this.address,
    required this.province,
    required this.lat,
    required this.lng,
    required this.priceMin,
    required this.priceMax,
    this.openingHours,
    this.imageUrl,
    this.phone,
    this.website,
    required this.createdAt,
    this.rating = 4.5,
    this.reviewCount = 0,
    this.description,
    this.kabupatenKota,
    this.dishType,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      cuisine: json['cuisine'] as String?,
      address: json['address'] as String? ?? '',
      province: json['province'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      priceMin: json['price_min'] as int? ?? 0,
      priceMax: json['price_max'] as int? ?? 0,
      openingHours: json['opening_hours'] as String?,
      imageUrl: json['image_url'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      rating:
          (json['avg_rating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          4.5,
      reviewCount: json['review_count'] as int? ?? 0,
      description: json['description'] as String?,
      kabupatenKota: json['kabupaten_kota'] as String?,
      dishType: json['dish_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'cuisine': cuisine,
    'address': address,
    'province': province,
    'lat': lat,
    'lng': lng,
    'price_min': priceMin,
    'price_max': priceMax,
    'opening_hours': openingHours,
    'image_url': imageUrl,
    'phone': phone,
    'website': website,
    'rating': rating,
    'review_count': reviewCount,
    'description': description,
    'kabupaten_kota': kabupatenKota,
    'dish_type': dishType,
  };

  /// Gambar dinonaktifkan/dihapus sesuai permintaan user agar tidak ada gambar kuliner yang keliru.
  String get effectiveImageUrl => '';

  static String defaultImageFor({
    required String name,
    required String category,
    String? cuisine,
  }) => '';

  String get priceRange => '${_rp(priceMin)} - ${_rp(priceMax)}';

  static String _rp(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }
}
