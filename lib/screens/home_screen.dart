
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../providers/auth_provider.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  static const _navy = Color(0xFF071B3B);
  static const _gold = Color(0xFFE6A83A);
  static const _ivory = Color(0xFFFFF9F4);

  static const _categoryIcons = <String, IconData>{
    'All': Icons.grid_view_rounded,
    'Fashion': Icons.checkroom_rounded,
    'Electronics': Icons.devices_rounded,
    'Phones': Icons.smartphone_rounded,
    'Laptops': Icons.laptop_mac_rounded,
    'Computers': Icons.computer_rounded,
    'Phone Accessories': Icons.cable_rounded,
    'Accessories': Icons.headphones_rounded,
    'Home & Living': Icons.chair_alt_rounded,
    'Beauty': Icons.spa_outlined,
    'Health': Icons.favorite_border_rounded,
    'Sports': Icons.sports_soccer_rounded,
    'Food': Icons.restaurant_rounded,
    'Gaming': Icons.sports_esports_rounded,
    'Smart Gadgets': Icons.watch_rounded,
    'Other': Icons.category_outlined,
  };

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 480) {
      ref.read(catalogueProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(catalogueProvider);
    final controller = ref.read(catalogueProvider.notifier);
    final user = ref.watch(authProvider.select((s) => s.user));

    ref.listen<CatalogueState>(catalogueProvider, (previous, next) {
      if (next.error != null &&
          previous?.error != next.error &&
          next.items.isNotEmpty) {
        showAppSnack(
          context,
          next.error!.message,
          isError: true,
          actionLabel: 'Retry',
          onAction: () => controller.refresh(keepItems: true),
        );
      }
    });

    final selected = state.category.isEmpty ? 'All' : state.category;

    final heading = state.query.isNotEmpty
        ? 'Results for "${state.query}"'
        : state.category.isEmpty
            ? 'Popular picks'
            : state.category;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => controller.refresh(keepItems: true),
        child: ContentWidth(
          maxWidth: 1100,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // PREMIUM BRAND HEADER
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: const BoxDecoration(
                    color: _navy,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: _gold,
                                width: 1.5,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/naijamart_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shopping_bag_rounded,
                                color: _navy,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NAIJAMART',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user == null
                                      ? 'Your marketplace. Your choice.'
                                      : 'Welcome back, ${user.firstName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white24,
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: _gold,
                              size: 23,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Find something\nyou will love.',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Discover great products from trusted sellers.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SEARCH
                      Container(
                        decoration: BoxDecoration(
                          color: _ivory,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .14),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) {
                            controller.setQuery(value);
                            setState(() {});
                          },
                          onSubmitted: controller.setQuery,
                          decoration: InputDecoration(
                            hintText: 'Search phones, fashion, gadgets...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _navy,
                              size: 24,
                            ),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _search.clear();
                                      controller.setQuery('');
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 17,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PROMOTIONAL BANNER
              if (!state.isFiltered)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: _MarketplaceBanner(),
                  ),
                ),

              // TRUST FEATURES
              if (!state.isFiltered)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                  sliver: SliverToBoxAdapter(
                    child: _TrustStrip(),
                  ),
                ),

              // CATEGORIES HEADING
              if (!state.isFiltered)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Explore categories',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          'EXPLORE',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // CATEGORY LIST
              if (!state.isFiltered)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 112,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConfig.categories.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 11),
                      itemBuilder: (context, index) {
                        final name = index == 0
                            ? 'All'
                            : AppConfig.categories[index - 1];

                        return _CategoryCard(
                          name: name,
                          icon: _categoryIcons[name] ??
                              Icons.category_outlined,
                          selected: selected == name,
                          onTap: () {
                            controller.setCategory(
                              name == 'All' ? '' : name,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

              // PRODUCT HEADING
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (state.isFiltered)
                        TextButton.icon(
                          onPressed: () {
                            _search.clear();
                            controller.clearFilters();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
              ),

              ..._buildCatalogue(state, controller),

              const SliverToBoxAdapter(
                child: SizedBox(height: 34),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCatalogue(
    CatalogueState state,
    CatalogueController controller,
  ) {
    if (state.isLoading) {
      return const [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: ProductGridSkeleton(),
        ),
      ];
    }

    if (state.error != null && state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load products',
            message: state.error!.message,
            actionLabel: 'Try again',
            onAction: controller.refresh,
          ),
        ),
      ];
    }

    if (state.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateMessage(
            icon: state.isFiltered
                ? Icons.search_off_rounded
                : Icons.storefront_outlined,
            title: state.isFiltered
                ? 'No matches found'
                : 'Products are coming soon',
            message: state.isFiltered
                ? 'Try another search or browse a different category.'
                : 'Our sellers are preparing the catalogue. Check back soon.',
            actionLabel: state.isFiltered ? 'Clear filters' : 'Refresh',
            onAction: state.isFiltered
                ? () {
                    _search.clear();
                    controller.clearFilters();
                    setState(() {});
                  }
                : controller.refresh,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: ProductSliverGrid(products: state.items),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Center(
            child: state.isLoadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  )
                : state.moreError != null
                    ? TextButton.icon(
                        onPressed: controller.loadMore,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'Could not load more. Tap to retry',
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}

class _MarketplaceBanner extends StatelessWidget {
  const _MarketplaceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102D5B),
            Color(0xFF07152E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071B3B).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.shopping_bag_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6A83A),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'THE NAIJAMART EXPERIENCE',
                  style: TextStyle(
                    color: Color(0xFF071B3B),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'Shopping made\nsimple. Every day.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Explore products, compare choices and shop from trusted sellers.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFFE6A83A),
                    size: 17,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'A smarter way to shop',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.verified_user_outlined, 'Trusted shopping'),
      (Icons.local_shipping_outlined, 'Delivery updates'),
      (Icons.lock_outline_rounded, 'Secure checkout'),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Column(
            children: [
              Icon(
                item.$1,
                color: const Color(0xFFB98526),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? const Color(0xFF071B3B)
          : scheme.surfaceContainerHighest.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 91,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE6A83A)
                  : scheme.outlineVariant.withValues(alpha: .5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 27,
                color: selected
                    ? const Color(0xFFE6A83A)
                    : scheme.primary,
              ),
              const SizedBox(height: 9),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
