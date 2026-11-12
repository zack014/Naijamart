import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijamart/models/product.dart';
import 'package:naijamart/providers/app_providers.dart';
import 'package:naijamart/providers/cart_provider.dart';
import 'package:naijamart/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Product product) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 190, height: 310, child: ProductCard(product: product)),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('shows name and price, and adds to cart', (tester) async {
    const product = Product(id: 1, name: 'Table Lamp', category: 'Home & Living', priceKobo: 1450000, quantity: 5);
    final container = await _pump(tester, product);

    expect(find.text('Table Lamp'), findsOneWidget);
    expect(find.text('₦14,500'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pump();

    expect(container.read(cartCountProvider), 1);
  });

  testWidgets('disables add-to-cart when out of stock', (tester) async {
    const product = Product(id: 2, name: 'Sold Out Item', category: 'Other', priceKobo: 1000, quantity: 0);
    final container = await _pump(tester, product);

    expect(find.text('Out of stock'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to cart'), warnIfMissed: false);
    await tester.pump();

    expect(container.read(cartCountProvider), 0);
  });
}
