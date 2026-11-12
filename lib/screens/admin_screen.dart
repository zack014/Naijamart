
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ui.dart';
import 'admin_product_form_screen.dart';
import 'main_shell.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  void _openStorefront(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider.select((s) => s.isAdmin));
    final user = ref.watch(authProvider.select((s) => s.user));

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const StateMessage(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Administrators only',
          message: 'Sign in with an administrator account to manage the store.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NaijaMart Admin',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                'Store management',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: () {
                ref.invalidate(adminOrdersProvider);
                ref.invalidate(adminProductsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonalIcon(
                onPressed: () => _openStorefront(context),
                icon: const Icon(Icons.storefront_outlined, size: 19),
                label: const Text('Store'),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_outlined),
                text: 'Overview',
              ),
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'Products',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersTab(adminName: user?.firstName ?? 'Admin'),
            const _ProductsTab(),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.adminName});

  final String adminName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    final theme = Theme.of(context);

    return orders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Orders unavailable',
        message: '$error',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(adminOrdersProvider),
      ),
      data: (list) {
        final paid = list.where((o) => o.isPaid).toList();
        final revenue = paid.fold<int>(0, (sum, o) => sum + o.totalKobo);
        final pending = list.length - paid.length;

        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminOrdersProvider.future),
          child: ContentWidth(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF061B45),
                        Color(0xFF124A91),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.waving_hand_rounded,
                        color: Color(0xFFE5A52E),
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome back, $adminName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your store, products and customer orders.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MainShell(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Visit customer storefront'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Store overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total orders',
                        value: '${list.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Metric(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'Awaiting payment',
                        value: '$pending',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Metric(
                  icon: Icons.payments_outlined,
                  label: 'Paid revenue',
                  value: naira(revenue),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent orders',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 42,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No orders yet',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'New customer orders will appear here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final Order order in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OrderCard(order: order),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    Product? product,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );

    ref.invalidate(adminProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load products',
        message: '$error',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(adminProductsProvider),
      ),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(adminProductsProvider.future),
        child: ContentWidth(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your catalogue',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${list.length} products in your store',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 35,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _open(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add a new product',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${list.length} items',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 35,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 45,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your catalogue is empty',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add your first product to start building your store.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              for (final product in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _open(
                        context,
                        ref,
                        product: product,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Radii.sm),
                              child: SizedBox(
                                width: 76,
                                height: 76,
                                child: AppImage(
                                  url: product.imageUrl,
                                  iconSize: 30,
                                ),
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    naira(product.priceKobo),
                                    style: TextStyle(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        product.inStock
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        size: 13,
                                        color: product.inStock
                                            ? Colors.green
                                            : scheme.error,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        product.inStock
                                            ? '${product.quantity} in stock'
                                            : 'Out of stock',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: product.inStock
                                              ? scheme.onSurfaceVariant
                                              : scheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit_outlined,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (list.length >= 100)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing the first 100 products.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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
