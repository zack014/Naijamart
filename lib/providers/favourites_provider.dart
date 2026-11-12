import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'app_providers.dart';

final favouritesProvider =
    StateNotifierProvider<FavouritesController, List<Product>>((ref) {
  return FavouritesController(ref.watch(sharedPreferencesProvider));
});

final isFavouriteProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(favouritesProvider.select(
    (list) => list.any((p) => p.id == productId),
  ));
});

/// Saved products, kept on-device as snapshots so the Saved tab works
/// offline and without loading the whole catalogue.
class FavouritesController extends StateNotifier<List<Product>> {
  FavouritesController(this._prefs) : super(_load(_prefs));

  static const _key = 'naijamart_favourites_v1';
  final SharedPreferences _prefs;

  static List<Product> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _set(List<Product> next) {
    state = next;
    _prefs.setString(_key, jsonEncode(next.map((p) => p.toJson()).toList()));
  }

  /// Returns true when the product is now saved.
  bool toggle(Product product) {
    final exists = state.any((p) => p.id == product.id);
    if (exists) {
      _set(state.where((p) => p.id != product.id).toList());
      return false;
    }
    _set([product, ...state]);
    return true;
  }

  void clear() => _set(const []);

  void refreshFrom(List<Product> fresh) {
    if (state.isEmpty || fresh.isEmpty) return;
    final byId = {for (final p in fresh) p.id: p};
    var changed = false;
    final next = state.map((p) {
      final latest = byId[p.id];
      if (latest != null && latest != p) {
        changed = true;
        return latest;
      }
      return p;
    }).toList();
    if (changed) _set(next);
  }
}
