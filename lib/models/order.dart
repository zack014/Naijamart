import 'package:flutter/foundation.dart';

@immutable
class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.unitPriceKobo,
  });

  final String name;
  final int quantity;
  final int unitPriceKobo;

  int get totalKobo => quantity * unitPriceKobo;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        name: '${json['product_name'] ?? json['name'] ?? 'Item'}',
        quantity: ((json['quantity'] ?? 1) as num).toInt(),
        unitPriceKobo: ((json['unit_price_kobo'] ?? json['price_kobo'] ?? 0) as num).toInt(),
      );
}

@immutable
class Order {
  const Order({
    required this.reference,
    required this.status,
    required this.paymentStatus,
    required this.totalKobo,
    this.createdAt,
    this.deliveryAddress = '',
    this.paymentMethod = '',
    this.items = const [],
  });

  final String reference;
  final String status;
  final String paymentStatus;
  final int totalKobo;
  final String? createdAt;
  final String deliveryAddress;
  final String paymentMethod;
  final List<OrderLine> items;

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Order(
      reference: '${json['reference'] ?? json['id'] ?? 'Order'}',
      status: '${json['status'] ?? 'pending'}',
      paymentStatus: '${json['payment_status'] ?? 'pending'}',
      totalKobo: ((json['total_kobo'] ?? 0) as num).toInt(),
      createdAt: json['created_at'] == null ? null : '${json['created_at']}',
      deliveryAddress: '${json['delivery_address'] ?? ''}',
      paymentMethod: '${json['payment_method'] ?? ''}',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// Result of `POST /checkout`.
@immutable
class CheckoutResult {
  const CheckoutResult({required this.reference, this.paymentUrl});

  final String reference;
  final String? paymentUrl;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final url = json['authorization_url'] ?? json['url'];
    return CheckoutResult(
      reference: '${json['reference'] ?? ''}',
      paymentUrl: url is String && url.isNotEmpty ? url : null,
    );
  }
}
