import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../providers/cart_provider.dart';
import '../providers/favourites_provider.dart';
import '../widgets/ui.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;

  Product get product => widget.product;

  void _addToCart() {
    final result =
        ref.read(cartProvider.notifier).add(product, quantity: _quantity);

    switch (result) {
      case CartAddResult.added:
        setState(() => _quantity = 1);
        showAppSnack(
          context,
          'Added to your cart',
          actionLabel: 'View cart',
          onAction: _openCart,
        );
      case CartAddResult.limitReached:
        showAppSnack(context,
            'Only ${product.quantity} available. We added what we could.');
      case CartAddResult.outOfStock:
        showAppSnack(context, 'Sorry, this item is out of stock.', isError: true);
    }
  }

  void _openCart() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(navIndexProvider.notifier).state = NavTab.cart;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFavourite = ref.watch(isFavouriteProvider(product.id));
    final inCart = ref.watch(cartQuantityProvider(product.id));
    final remaining = (product.quantity - inCart).clamp(0, product.quantity).toInt();
    final maxSelectable = remaining < 1 ? 1 : remaining;
    if (_quantity > maxSelectable) _quantity = maxSelectable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: isFavourite ? 'Remove from saved' : 'Save for later',
            onPressed: () {
              final saved = ref.read(favouritesProvider.notifier).toggle(product);
              showAppSnack(context, saved ? 'Saved for later' : 'Removed from saved');
            },
            icon: Icon(
              isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavourite ? const Color(0xFFD62F4B) : null,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.lg + 4),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppImage(
                  url: product.imageUrl,
                  iconSize: 96,
                  semanticLabel: product.name,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.category.toUpperCase(),
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                product.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              naira(product.priceKobo),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _StockRow(product: product),
            if (inCart > 0) ...[
              const SizedBox(height: 6),
              Text('$inCart already in your cart',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 22),
            Text('About this item',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              product.description.trim().isEmpty
                  ? 'Product information will be updated by the seller.'
                  : product.description,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(height: 1.55, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: ContentWidth(
            maxWidth: 640,
            child: Row(
              children: [
                if (remaining > 0) ...[
                  QuantityStepper(
                    quantity: _quantity,
                    onDecrement:
                        _quantity > 1 ? () => setState(() => _quantity--) : null,
                    onIncrement: () => setState(() => _quantity++),
                    canIncrement: _quantity < maxSelectable,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: remaining > 0 ? _addToCart : null,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      !product.inStock
                          ? 'Out of stock'
                          : remaining == 0
                              ? 'All stock in cart'
                              : 'Add to cart · ${naira(product.priceKobo * _quantity, showDecimals: false)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    final IconData icon;
    final String text;
    if (!product.inStock) {
      color = scheme.error;
      icon = Icons.remove_circle_outline_rounded;
      text = 'Currently out of stock';
    } else if (product.lowStock) {
      color = Brand.warning;
      icon = Icons.local_fire_department_outlined;
      text = 'Only ${product.quantity} left, order soon';
    } else {
      color = Brand.success;
      icon = Icons.check_circle_outline_rounded;
      text = 'In stock';
    }
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 7),
        Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
