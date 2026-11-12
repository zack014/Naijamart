
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'auth_screen.dart';

class GetStartedScreen extends ConsumerWidget {
  const GetStartedScreen({super.key});

  static const Color navy = Color(0xFF061B45);
  static const Color navyCard = Color(0xFF102A58);
  static const Color orange = Color(0xFFFF7900);
  static const Color gold = Color(0xFFFFB800);

  Future<void> _openAuth(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );

    await ref.read(onboardingSeenProvider.notifier).markSeen();
  }

  Future<void> _continueAsGuest(WidgetRef ref) async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // BRAND HEADER: original logo and tagline artwork.
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 941 / 510,
                            child: Image.asset(
                              'assets/images/naijamart_brand_header.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Functional Skip button.
                          Positioned(
                            top: 8,
                            right: 10,
                            child: Container(
                              color: Colors.white,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _continueAsGuest(ref),
                                icon: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                label: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: navy,
                                  size: 17,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // NAVY WELCOME SECTION.
                      Container(
                        width: double.infinity,
                        color: navy,
                        child: Column(
                          children: [
                            // Shopping products illustration.
                            Image.asset(
                              'assets/images/naijamart_welcome_products.png',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                4,
                                22,
                                30,
                              ),
                              child: Column(
                                children: [
                                  // Welcome heading.
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 29,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.7,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        TextSpan(text: 'Welcome to '),
                                        TextSpan(
                                          text: 'NaijaMart',
                                          style: TextStyle(
                                            color: orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  const Text(
                                    'Your trusted online marketplace for '
                                    'quality products, secure payments '
                                    'and fast delivery across Nigeria.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Three feature cards.
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: _FeatureCard(
                                          icon: Icons.shopping_bag_rounded,
                                          title: 'Wide\nProduct Range',
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: _FeatureCard(
                                          icon: Icons.verified_user_rounded,
                                          title: 'Secure\nPayments',
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: _FeatureCard(
                                          icon: Icons.local_shipping_rounded,
                                          title: 'Reliable\nDelivery',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 29),

                                  // Page indicators from the reference.
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _PageDot(active: true),
                                      _PageDot(active: false),
                                      _PageDot(active: false),
                                    ],
                                  ),

                                  const SizedBox(height: 34),

                                  // Get Started.
                                  SizedBox(
                                    width: double.infinity,
                                    height: 62,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [gold, orange],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(40),
                                        boxShadow: [
                                          BoxShadow(
                                            color: orange.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: FilledButton(
                                        onPressed: () =>
                                            _openAuth(context, ref),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Get Started',
                                              style: TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 29,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 17),

                                  // Log In.
                                  SizedBox(
                                    width: double.infinity,
                                    height: 59,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _openAuth(context, ref),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 1.7,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                      ),
                                      child: const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 17),

                                  TextButton(
                                    onPressed: () =>
                                        _continueAsGuest(ref),
                                    child: Text(
                                      'Continue shopping as guest',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF102A58),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFF244477),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFA000),
            size: 35,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: active ? 14 : 12,
      height: active ? 14 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFFFF7900)
            : Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}
