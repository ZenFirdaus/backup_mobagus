class Restaurant {
  final String id;
  final String name;
  final String category;
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

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
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
      };

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
