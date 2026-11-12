import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/ui.dart';
import 'auth_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((s) => s.isAuthenticated));
    final orders = ref.watch(ordersProvider);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: ScreenHeader(
                title: 'My orders',
                subtitle: 'Track purchases and payment updates.',
              ),
            ),
            Expanded(
              child: !signedIn
                  ? StateMessage(
                      icon: Icons.lock_outline_rounded,
                      title: 'Sign in to see your orders',
                      message:
                          'Your order history is linked to your account so it stays private.',
                      actionLabel: 'Sign in',
                      onAction: () => Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                    )
                  : orders.when(
                      loading: () => const _OrdersSkeleton(),
                      error: (error, _) => StateMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load your orders',
                        message: '$error',
                        actionLabel: 'Try again',
                        onAction: () => ref.invalidate(ordersProvider),
                      ),
                      data: (list) => RefreshIndicator(
                        onRefresh: () => ref.refresh(ordersProvider.future),
                        child: list.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: 420,
                                    child: StateMessage(
                                      icon: Icons.receipt_long_outlined,
                                      title: 'No orders yet',
                                      message:
                                          'When you place an order, its status and receipt will appear here.',
                                      actionLabel: 'Start shopping',
                                      onAction: () => ref
                                          .read(navIndexProvider.notifier)
                                          .state = NavTab.home,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => OrderCard(order: list[i]),
                              ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const Skeleton(height: 96, radius: 16),
      );
}
