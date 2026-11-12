import 'package:flutter/foundation.dart';

import 'product.dart';

/// A product snapshot plus the quantity in the cart. Storing the snapshot
/// means the cart renders without the catalogue being loaded.
@immutable
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get totalKobo => product.priceKobo * quantity;

  CartLine copyWith({Product? product, int? quantity}) => CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
        quantity: (json['quantity'] as num).toInt(),
      );
}
