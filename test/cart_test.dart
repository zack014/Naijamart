import 'package:flutter_test/flutter_test.dart';
import 'package:naijamart/models/product.dart';
import 'package:naijamart/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lamp = Product(id: 1, name: 'Lamp', category: 'Home & Living', priceKobo: 100000, quantity: 3);
const _soldOut = Product(id: 2, name: 'Gone', category: 'Other', priceKobo: 5000, quantity: 0);

Future<(CartController, SharedPreferences)> _make() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return (CartController(prefs), prefs);
}

void main() {
  test('adds items and totals correctly', () async {
    final (cart, _) = await _make();
    expect(cart.add(_lamp, quantity: 2), CartAddResult.added);
    expect(cart.state.single.quantity, 2);
    expect(cart.state.single.totalKobo, 200000);
  });

  test('never exceeds available stock', () async {
    final (cart, _) = await _make();
    cart.add(_lamp, quantity: 3);
    expect(cart.add(_lamp), CartAddResult.limitReached);
    expect(cart.state.single.quantity, 3);
  });

  test('caps a large add to stock and reports it', () async {
    final (cart, _) = await _make();
    expect(cart.add(_lamp, quantity: 10), CartAddResult.limitReached);
    expect(cart.state.single.quantity, 3);
  });

  test('refuses out-of-stock products', () async {
    final (cart, _) = await _make();
    expect(cart.add(_soldOut), CartAddResult.outOfStock);
    expect(cart.state, isEmpty);
  });

  test('decrement removes the line at zero', () async {
    final (cart, _) = await _make();
    cart.add(_lamp);
    cart.decrement(_lamp.id);
    expect(cart.state, isEmpty);
  });

  test('persists across restarts', () async {
    final (cart, prefs) = await _make();
    cart.add(_lamp, quantity: 2);
    await Future<void>.delayed(Duration.zero);

    final restored = CartController(prefs);
    expect(restored.state.single.product.name, 'Lamp');
    expect(restored.state.single.quantity, 2);
  });

  test('refreshFrom trims quantity to new stock and updates price', () async {
    final (cart, _) = await _make();
    cart.add(_lamp, quantity: 3);
    cart.refreshFrom([_lamp.copyWith(quantity: 1, priceKobo: 120000)]);
    expect(cart.state.single.quantity, 1);
    expect(cart.state.single.product.priceKobo, 120000);
  });

  test('survives corrupted stored data', () async {
    SharedPreferences.setMockInitialValues({'naijamart_cart_v1': '{not json'});
    final prefs = await SharedPreferences.getInstance();
    expect(CartController(prefs).state, isEmpty);
  });
}
