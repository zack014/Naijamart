import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_line.dart';
import '../models/product.dart';
import 'app_providers.dart';

enum CartAddResult { added, limitReached, outOfStock }

final cartProvider =
    StateNotifierProvider<CartController, List<CartLine>>((ref) {
  return CartController(ref.watch(sharedPreferencesProvider));
});

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold<int>(0, (sum, l) => sum + l.quantity),
);

final cartSubtotalProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold<int>(0, (sum, l) => sum + l.totalKobo),
);

/// Quantity of one product currently in the cart (0 when absent).
final cartQuantityProvider = Provider.family<int, int>((ref, productId) {
  for (final line in ref.watch(cartProvider)) {
    if (line.product.id == productId) return line.quantity;
  }
  return 0;
});

/// The cart is stored on-device so it survives app restarts and works for
/// guests. It is sent to the server when the customer checks out.
class CartController extends StateNotifier<List<CartLine>> {
  CartController(this._prefs) : super(_load(_prefs));

  static const _key = 'naijamart_cart_v1';
  final SharedPreferences _prefs;

  static List<CartLine> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((l) => l.quantity > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _set(List<CartLine> next) {
    state = next;
    _prefs.setString(_key, jsonEncode(next.map((l) => l.toJson()).toList()));
  }

  CartAddResult add(Product product, {int quantity = 1}) {
    if (!product.inStock) return CartAddResult.outOfStock;
    final index = state.indexWhere((l) => l.product.id == product.id);
    final current = index == -1 ? 0 : state[index].quantity;
    final wanted = current + quantity;
    final capped = wanted > product.quantity ? product.quantity : wanted;
    if (capped <= current) return CartAddResult.limitReached;

    final next = [...state];
    if (index == -1) {
      next.add(CartLine(product: product, quantity: capped));
    } else {
      next[index] = next[index].copyWith(product: product, quantity: capped);
    }
    _set(next);
    return wanted > product.quantity
        ? CartAddResult.limitReached
        : CartAddResult.added;
  }

  void decrement(int productId) {
    final index = state.indexWhere((l) => l.product.id == productId);
    if (index == -1) return;
    final line = state[index];
    final next = [...state];
    if (line.quantity <= 1) {
      next.removeAt(index);
    } else {
      next[index] = line.copyWith(quantity: line.quantity - 1);
    }
    _set(next);
  }

  void remove(int productId) =>
      _set(state.where((l) => l.product.id != productId).toList());

  void clear() => _set(const []);

  /// Updates stored price / stock from freshly loaded catalogue data, and
  /// trims quantities that now exceed available stock.
  void refreshFrom(List<Product> fresh) {
    if (state.isEmpty || fresh.isEmpty) return;
    final byId = {for (final p in fresh) p.id: p};
    var changed = false;
    final next = <CartLine>[];
    for (final line in state) {
      final latest = byId[line.product.id];
      if (latest == null) {
        next.add(line);
        continue;
      }
      var qty = line.quantity;
      if (latest.quantity > 0 && qty > latest.quantity) qty = latest.quantity;
      final updated = line.copyWith(product: latest, quantity: qty);
      if (latest != line.product || qty != line.quantity) changed = true;
      next.add(updated);
    }
    if (changed) _set(next);
  }
}
