import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/favourites_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favouritesProvider);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        maxWidth: 1100,
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
              sliver: SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Saved for later',
                  subtitle: 'Your favourite finds, all in one place.',
                ),
              ),
            ),
            if (saved.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: StateMessage(
                  icon: Icons.favorite_border_rounded,
                  title: 'Nothing saved just yet',
                  message: 'Tap the heart on any product to keep it here.',
                  actionLabel: 'Browse products',
                  onAction: () =>
                      ref.read(navIndexProvider.notifier).state = NavTab.home,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: ProductSliverGrid(products: saved),
              ),
          ],
        ),
      ),
    );
  }
}
