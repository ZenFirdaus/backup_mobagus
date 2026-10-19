class Checkin {
  final String id;
  final String userId;
  final String restaurantId;
  final double lat;
  final double lng;
  final bool verified;
  final DateTime createdAt;
  final String? restaurantName;

  const Checkin({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.lat,
    required this.lng,
    required this.verified,
    required this.createdAt,
    this.restaurantName,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) {
    final resto = json['restaurants'] as Map<String, dynamic>?;
    return Checkin(
      id: json['id'].toString(),
      userId: json['user_id'] as String? ?? '',
      restaurantId: json['restaurant_id'].toString(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      restaurantName: json['restaurant_name'] as String? ?? resto?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'restaurant_id': restaurantId,
    'lat': lat,
    'lng': lng,
    'verified': verified,
    'created_at': createdAt.toIso8601String(),
    'restaurant_name': restaurantName,
  };
}
