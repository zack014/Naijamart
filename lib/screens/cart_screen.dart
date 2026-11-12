import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/cart_line.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    var signedIn = ref.read(authProvider).isAuthenticated;
    if (!signedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      signedIn = ok == true;
    }
    if (!signedIn || !context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasUnavailable = lines.any((l) => !l.product.inStock);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: ScreenHeader(
                title: 'My cart',
                subtitle: lines.isEmpty
                    ? null
                    : '$count ${count == 1 ? 'item' : 'items'} in your bag',
                trailing: lines.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Empty your cart?',
                            message: 'All items will be removed from your cart.',
                            confirmLabel: 'Empty cart',
                            destructive: true,
                          );
                          if (ok) ref.read(cartProvider.notifier).clear();
                        },
                        child: const Text('Clear all'),
                      ),
              ),
            ),
            Expanded(
              child: lines.isEmpty
                  ? StateMessage(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your cart is empty',
                      message: 'Add something lovely and it will show up here.',
                      actionLabel: 'Start shopping',
                      onAction: () =>
                          ref.read(navIndexProvider.notifier).state = NavTab.home,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      itemCount: lines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _CartTile(
                        key: ValueKey(lines[index].product.id),
                        line: lines[index],
                      ),
                    ),
            ),
            if (lines.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          naira(subtotal),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Delivery and any applicable charges are confirmed at checkout.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: hasUnavailable
                            ? null
                            : () => _checkout(context, ref),
                        child: Text(hasUnavailable
                            ? 'Remove unavailable items to continue'
                            : 'Continue to checkout'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({super.key, required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final product = line.product;
    final cart = ref.read(cartProvider.notifier);

    return Dismissible(
      key: ValueKey('dismiss-${product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
      ),
      onDismissed: (_) {
        cart.remove(product.id);
        showAppSnack(
          context,
          '${product.name} removed',
          actionLabel: 'Undo',
          // `cart` was captured up front: this tile (and its `ref`) is
          // already disposed by the time Undo is tapped.
          onAction: () => cart.add(product, quantity: line.quantity),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Radii.sm),
              onTap: () => openProduct(context, product),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: AppImage(url: product.imageUrl, iconSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    naira(product.priceKobo),
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w900),
                  ),
                  if (!product.inStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('No longer in stock',
                          style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.inStock)
                        QuantityStepper(
                          compact: true,
                          quantity: line.quantity,
                          onDecrement: () => cart.decrement(product.id),
                          onIncrement: () {
                            final result = cart.add(product);
                            if (result == CartAddResult.limitReached) {
                              showAppSnack(context,
                                  'You have reached the available stock.');
                            }
                          },
                          canIncrement: line.quantity < product.quantity,
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove ${product.name}',
                        onPressed: () => cart.remove(product.id),
                        icon: Icon(Icons.delete_outline_rounded,
                            color: scheme.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
