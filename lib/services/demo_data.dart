import '../models/product.dart';

/// Sample catalogue used only when built with `--dart-define=USE_DEMO_DATA=true`.
const demoProducts = <Product>[
  Product(id: 1001, name: 'Classic Everyday Sneakers', category: 'Fashion', priceKobo: 1850000, description: 'Comfortable everyday sneakers.', quantity: 18),
  Product(id: 1002, name: 'Wireless Headphones', category: 'Electronics', priceKobo: 3250000, description: 'Wireless headphones for music and calls.', quantity: 12),
  Product(id: 1003, name: 'Minimalist Wrist Watch', category: 'Accessories', priceKobo: 2400000, description: 'A stylish everyday wrist watch.', quantity: 9),
  Product(id: 1004, name: 'Modern Table Lamp', category: 'Home & Living', priceKobo: 1450000, description: 'A modern lamp for your living space.', quantity: 15),
  Product(id: 1005, name: 'Travel Backpack', category: 'Fashion', priceKobo: 2100000, description: 'A practical backpack for everyday use.', quantity: 20),
  Product(id: 1006, name: 'Bluetooth Speaker', category: 'Electronics', priceKobo: 2750000, description: 'Portable wireless speaker.', quantity: 3),
  Product(id: 1007, name: 'Skincare Essentials', category: 'Beauty', priceKobo: 1950000, description: 'A sample skincare essentials bundle.', quantity: 14),
  Product(id: 1008, name: 'Fashion Sunglasses', category: 'Accessories', priceKobo: 950000, description: 'Classic sunglasses for everyday style.', quantity: 0),
];

List<Product> filterDemoProducts({
  String query = '',
  String category = '',
  int offset = 0,
  int limit = 20,
}) {
  final q = query.trim().toLowerCase();
  final matches = demoProducts.where((p) {
    final inCategory = category.isEmpty || p.category.toLowerCase() == category.toLowerCase();
    final inQuery = q.isEmpty || '${p.name} ${p.category} ${p.description}'.toLowerCase().contains(q);
    return inCategory && inQuery;
  }).toList();
  if (offset >= matches.length) return const [];
  final end = (offset + limit).clamp(0, matches.length).toInt();
  return matches.sublist(offset, end);
}
