
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final localProducts = <Product>[
  const Product(
    id: 1001,
    name: 'Classic Everyday Sneakers',
    category: 'Fashion',
    priceKobo: 1850000,
    description: 'Comfortable everyday sneakers.',
    quantity: 18,
  ),
  const Product(
    id: 1002,
    name: 'Wireless Headphones',
    category: 'Electronics',
    priceKobo: 3250000,
    description: 'Wireless headphones for music and calls.',
    quantity: 12,
  ),
  const Product(
    id: 1003,
    name: 'Minimalist Wrist Watch',
    category: 'Accessories',
    priceKobo: 2400000,
    description: 'A stylish everyday wrist watch.',
    quantity: 9,
  ),
  const Product(
    id: 1004,
    name: 'Modern Table Lamp',
    category: 'Home',
    priceKobo: 1450000,
    description: 'A modern lamp for your living space.',
    quantity: 15,
  ),
  const Product(
    id: 1005,
    name: 'Travel Backpack',
    category: 'Fashion',
    priceKobo: 2100000,
    description: 'A practical backpack for everyday use.',
    quantity: 20,
  ),
  const Product(
    id: 1006,
    name: 'Bluetooth Speaker',
    category: 'Electronics',
    priceKobo: 2750000,
    description: 'Portable wireless speaker.',
    quantity: 11,
  ),
  const Product(
    id: 1007,
    name: 'Skincare Essentials',
    category: 'Beauty',
    priceKobo: 1950000,
    description: 'A sample skincare essentials bundle.',
    quantity: 14,
  ),
  const Product(
    id: 1008,
    name: 'Fashion Sunglasses',
    category: 'Accessories',
    priceKobo: 950000,
    description: 'Classic sunglasses for everyday style.',
    quantity: 25,
  ),
];

final catalogueProvider =
    StateNotifierProvider<CatalogueController, AsyncValue<List<Product>>>(
  (ref) => CatalogueController(),
);

class CatalogueController extends StateNotifier<AsyncValue<List<Product>>> {
  CatalogueController() : super(const AsyncValue.loading());

  String _query = '';
  String _category = '';

  List<Product> _filteredProducts() {
    return localProducts.where((product) {
      final matchesCategory = _category.isEmpty ||
          product.category.toLowerCase() == _category.toLowerCase();

      final searchable =
          '${product.name} ${product.category} ${product.description}'
              .toLowerCase();

      final matchesQuery =
          _query.isEmpty || searchable.contains(_query.toLowerCase());

      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> load({bool refresh = false}) async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(_filteredProducts());
  }

  Future<void> search({
    String query = '',
    String category = '',
  }) async {
    _query = query.trim();
    _category = category;
    state = AsyncValue.data(_filteredProducts());
  }

  Future<void> reload() async {
    state = AsyncValue.data(_filteredProducts());
  }
}

final favouritesProvider = StateProvider<Set<int>>(
  (ref) => <int>{},
);

final cartProvider =
    StateNotifierProvider<CartController, Map<int, int>>(
  (ref) => CartController(),
);

class CartController extends StateNotifier<Map<int, int>> {
  CartController() : super({});

  void add(int id) {
    state = {...state, id: (state[id] ?? 0) + 1};
  }

  void decrement(int id) {
    final next = {...state};
    final quantity = (next[id] ?? 0) - 1;

    if (quantity <= 0) {
      next.remove(id);
    } else {
      next[id] = quantity;
    }

    state = next;
  }

  void remove(int id) {
    final next = {...state}..remove(id);
    state = next;
  }

  void clear() {
    state = {};
  }
}
