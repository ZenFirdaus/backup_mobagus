import '../utils/format.dart';

class Food {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final int price;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;

  const Food({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'].toString(),
      restaurantId: json['restaurant_id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: json['price'] as int? ?? 0,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get priceLabel => formatRp(price);
}
