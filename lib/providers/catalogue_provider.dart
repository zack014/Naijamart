import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../models/product.dart';
import '../services/store_api.dart';
import 'cart_provider.dart';
import 'favourites_provider.dart';

@immutable
class CatalogueState {
  const CatalogueState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.moreError,
    this.query = '',
    this.category = '',
  });

  final List<Product> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  /// Failure of the first page (shows a full-screen retry state).
  final ApiException? error;

  /// Failure while loading further pages (shows an inline retry).
  final ApiException? moreError;

  final String query;

  /// Empty string means "All".
  final String category;

  bool get isFiltered => query.isNotEmpty || category.isNotEmpty;

  CatalogueState copyWith({
    List<Product>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ApiException? error,
    bool clearError = false,
    ApiException? moreError,
    bool clearMoreError = false,
    String? query,
    String? category,
  }) =>
      CatalogueState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        moreError: clearMoreError ? null : (moreError ?? this.moreError),
        query: query ?? this.query,
        category: category ?? this.category,
      );
}

final catalogueProvider =
    StateNotifierProvider<CatalogueController, CatalogueState>((ref) {
  return CatalogueController(ref);
});

class CatalogueController extends StateNotifier<CatalogueState> {
  CatalogueController(this._ref) : super(const CatalogueState()) {
    refresh();
  }

  final Ref _ref;
  Timer? _debounce;

  /// Bumped on every new query so late responses from older requests are ignored.
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Loads the first page. [keepItems] avoids a blank flash on pull-to-refresh.
  Future<void> refresh({bool keepItems = false}) async {
    final generation = ++_generation;
    state = state.copyWith(
      items: keepItems ? state.items : const [],
      isLoading: !keepItems || state.items.isEmpty,
      isLoadingMore: false,
      hasMore: true,
      clearError: true,
      clearMoreError: true,
    );
    try {
      final items = await _ref.read(storeApiProvider).products(
            query: state.query,
            category: state.category,
            offset: 0,
            limit: AppConfig.pageSize,
          );
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= AppConfig.pageSize,
      );
      _ref.read(cartProvider.notifier).refreshFrom(items);
      _ref.read(favouritesProvider.notifier).refreshFrom(items);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        error: ApiException.from(error),
        // Keep stale items on screen if a pull-to-refresh failed.
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.error != null) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearMoreError: true);
    try {
      final page = await _ref.read(storeApiProvider).products(
            query: state.query,
            category: state.category,
            offset: state.items.length,
            limit: AppConfig.pageSize,
          );
      if (!mounted || generation != _generation) return;
      final known = state.items.map((p) => p.id).toSet();
      final fresh = page.where((p) => !known.contains(p.id)).toList();
      state = state.copyWith(
        items: [...state.items, ...fresh],
        isLoadingMore: false,
        hasMore: page.length >= AppConfig.pageSize && fresh.isNotEmpty,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        isLoadingMore: false,
        moreError: ApiException.from(error),
      );
    }
  }

  /// Debounced so we do not hit the API on every keystroke.
  void setQuery(String query) {
    final trimmed = query.trim();
    _debounce?.cancel();
    if (trimmed == state.query) return;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      state = state.copyWith(query: trimmed);
      refresh();
    });
  }

  void setCategory(String category) {
    if (category == state.category) return;
    _debounce?.cancel();
    state = state.copyWith(category: category);
    refresh();
  }

  void clearFilters() {
    _debounce?.cancel();
    state = state.copyWith(query: '', category: '');
    refresh();
  }
}
