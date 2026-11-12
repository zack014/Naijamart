import 'package:flutter_test/flutter_test.dart';
import 'package:naijamart/models/app_user.dart';
import 'package:naijamart/models/order.dart';
import 'package:naijamart/models/product.dart';

void main() {
  test('Product round-trips through JSON', () {
    const p = Product(id: 7, name: 'Bag', category: 'Fashion', priceKobo: 250000, quantity: 4);
    final copy = Product.fromJson(p.toJson());
    expect(copy, p);
    expect(copy.lowStock, isTrue);
  });

  test('Product.fromJson tolerates missing optional fields', () {
    final p = Product.fromJson({'id': 1, 'price_kobo': 100});
    expect(p.name, '');
    expect(p.category, 'Other');
    expect(p.inStock, isFalse);
  });

  test('AppUser detects admin from role or flag', () {
    expect(AppUser.fromJson({'id': 1, 'email': 'a@b.c', 'role': 'admin'}).isAdmin, isTrue);
    expect(AppUser.fromJson({'id': 1, 'email': 'a@b.c', 'is_admin': true}).isAdmin, isTrue);
    expect(AppUser.fromJson({'id': 1, 'email': 'a@b.c', 'role': 'customer'}).isAdmin, isFalse);
  });

  test('AppUser initials', () {
    expect(const AppUser(id: 1, email: 'a@b.c', fullName: 'Ada Obi').initials, 'AO');
    expect(const AppUser(id: 1, email: 'z@b.c', fullName: '').initials, 'Z');
  });

  test('Order parses totals and items', () {
    final o = Order.fromJson({
      'reference': 'NM-1',
      'status': 'processing',
      'payment_status': 'paid',
      'total_kobo': 500000,
      'items': [
        {'product_name': 'Bag', 'quantity': 2, 'unit_price_kobo': 250000}
      ],
    });
    expect(o.isPaid, isTrue);
    expect(o.items.single.totalKobo, 500000);
  });

  test('CheckoutResult accepts either url key', () {
    expect(CheckoutResult.fromJson({'reference': 'r', 'authorization_url': 'https://x.y'}).paymentUrl, 'https://x.y');
    expect(CheckoutResult.fromJson({'reference': 'r', 'url': 'https://a.b'}).paymentUrl, 'https://a.b');
    expect(CheckoutResult.fromJson({'reference': 'r'}).paymentUrl, isNull);
  });
}
