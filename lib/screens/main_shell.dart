
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/ui.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'favourites_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Tabs are built the first time they are opened.
  final Set<int> _visited = {NavTab.home};

  static const _pages = <Widget>[
    HomeScreen(),
    FavouritesScreen(),
    CartScreen(),
    OrdersScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navIndexProvider);
    final cartCount = ref.watch(cartCountProvider);

    _visited.add(index);

    ref.listen<AuthState>(authProvider, (previous, next) {
      final notice = next.notice;

      if (notice != null) {
        showAppSnack(context, notice, isError: true);
        ref.read(authProvider.notifier).clearNotice();
      }
    });

    return PopScope(
      canPop: index == NavTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(navIndexProvider.notifier).state = NavTab.home;
        }
      },
      child: Scaffold(
        body: SizedBox.expand(
          child: IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < _pages.length; i++)
                if (_visited.contains(i))
                  SizedBox.expand(
                    child: _pages[i],
                  )
                else
                  const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            ref.read(navIndexProvider.notifier).state = value;
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_rounded),
              ),
              label: 'Cart',
              tooltip: cartCount > 0 ? 'Cart, $cartCount items' : 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
