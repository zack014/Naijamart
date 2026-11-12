import 'package:flutter/foundation.dart';

export '../core/format.dart' show naira;

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.priceKobo,
    this.slug = '',
    this.description = '',
    this.imageUrl = '',
    this.quantity = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String category;
  final int priceKobo;
  final String description;
  final String imageUrl;

  /// Units in stock.
  final int quantity;

  bool get inStock => quantity > 0;
  bool get lowStock => quantity > 0 && quantity <= 5;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num).toInt(),
        name: '${json['name'] ?? ''}',
        slug: '${json['slug'] ?? ''}',
        category: '${json['category'] ?? 'Other'}',
        priceKobo: (json['price_kobo'] as num).toInt(),
        description: '${json['description'] ?? ''}',
        imageUrl: '${json['image_url'] ?? ''}',
        quantity: ((json['quantity'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'category': category,
        'price_kobo': priceKobo,
        'description': description,
        'image_url': imageUrl,
        'quantity': quantity,
      };

  Product copyWith({int? quantity, int? priceKobo}) => Product(
        id: id,
        name: name,
        slug: slug,
        category: category,
        priceKobo: priceKobo ?? this.priceKobo,
        description: description,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
      );

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.priceKobo == priceKobo &&
      other.quantity == quantity &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(id, name, priceKobo, quantity, imageUrl);
}
