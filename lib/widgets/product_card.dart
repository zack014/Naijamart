import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favourites_provider.dart';
import '../screens/product_detail_screen.dart';
import 'ui.dart';

void openProduct(BuildContext context, Product product) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductDetailScreen(product: product),
    ),
  );
}

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final Product product;

  static const _navy = Color(0xFF071B3B);
  static const _gold = Color(0xFFE6A83A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFavourite = ref.watch(isFavouriteProvider(product.id));

    return Semantics(
      container: true,
      label: '${product.name}, ${naira(product.priceKobo)}'
          '${product.inStock ? '' : ', out of stock'}',
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openProduct(context, product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PRODUCT IMAGE
              AspectRatio(
                aspectRatio: 1.02,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: product.imageUrl,
                      iconSize: 48,
                    ),

                    // Soft image overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 45,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .12),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FAVOURITE BUTTON
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: .96),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: isFavourite
                              ? 'Remove from saved'
                              : 'Save for later',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            final saved = ref
                                .read(favouritesProvider.notifier)
                                .toggle(product);

                            showAppSnack(
                              context,
                              saved
                                  ? 'Saved for later'
                                  : 'Removed from saved',
                            );
                          },
                          icon: Icon(
                            isFavourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavourite
                                ? const Color(0xFFD62F4B)
                                : _navy,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // STOCK BADGE
                    if (!product.inStock)
                      const Positioned(
                        left: 8,
                        bottom: 9,
                        child: _Badge('Out of stock'),
                      )
                    else if (product.lowStock)
                      Positioned(
                        left: 8,
                        bottom: 9,
                        child: _Badge(
                          'Only ${product.quantity} left',
                          warning: true,
                        ),
                      ),
                  ],
                ),
              ),

              // PRODUCT DETAILS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 9, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB98526),
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          fontSize: 12.5,
                        ),
                      ),
                      const Spacer(),

                      // PRICE AND CART ACTION
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                naira(
                                  product.priceKobo,
                                  showDecimals: false,
                                ),
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 35,
                            height: 35,
                            child: IconButton(
                              tooltip: 'Add to cart',
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: product.inStock
                                    ? _navy
                                    : scheme.surfaceContainerHighest,
                                foregroundColor: product.inStock
                                    ? _gold
                                    : scheme.onSurfaceVariant,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              onPressed: product.inStock
                                  ? () => _quickAdd(context, ref)
                                  : null,
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickAdd(BuildContext context, WidgetRef ref) {
    final result = ref.read(cartProvider.notifier).add(product);

    switch (result) {
      case CartAddResult.added:
        showAppSnack(context, 'Added to your cart');
      case CartAddResult.limitReached:
        showAppSnack(
          context,
          'You already have all available stock in your cart.',
        );
      case CartAddResult.outOfStock:
        showAppSnack(
          context,
          'Sorry, this item is out of stock.',
          isError: true,
        );
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    this.warning = false,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: warning
            ? const Color(0xFFE6A83A)
            : Colors.black87,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: warning
              ? const Color(0xFF071B3B)
              : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Responsive product grid.
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({
    super.key,
    required this.products,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context)
        .scale(1)
        .clamp(1.0, 1.6)
        .toDouble();

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.crossAxisExtent;
        final columns = (width / 180).floor().clamp(2, 5).toInt();
        final itemWidth = (width - gap * (columns - 1)) / columns;
        final extent = itemWidth + 116 * textScale;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ProductCard(
              product: products[index],
            ),
            childCount: products.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: extent,
          ),
        );
      },
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    super.key,
    this.count = 6,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.crossAxisExtent;
        final columns = (width / 180).floor().clamp(2, 5).toInt();
        final itemWidth = (width - gap * (columns - 1)) / columns;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(
                  height: itemWidth,
                  radius: Radii.lg,
                ),
                const SizedBox(height: 10),
                const Skeleton(width: 60, height: 10),
                const SizedBox(height: 8),
                const Skeleton(height: 13),
                const SizedBox(height: 8),
                const Skeleton(width: 80, height: 16),
              ],
            ),
            childCount: count,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            mainAxisExtent: itemWidth + 116,
          ),
        );
      },
    );
  }
}