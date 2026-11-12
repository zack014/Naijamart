import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/store_api.dart';
import 'auth_provider.dart';

/// The signed-in customer's orders. Re-fetches when the user changes.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
  if (!signedIn) return const [];
  return ref.watch(storeApiProvider).orders();
});

/// All store orders (admin only; the server enforces the role).
final adminOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(storeApiProvider).adminOrders();
});

/// Products for the admin list (first 100; the storefront paginates).
final adminProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(storeApiProvider).products(limit: 100);
});
