
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../core/launcher.dart';
import '../core/theme.dart';
import '../core/theme_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favourites_provider.dart';
import '../widgets/ui.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';
import 'policy_screen.dart';

enum _AccountPaymentMethod {
  paystack(
    'Paystack',
    'Pay securely with card, bank or USSD.',
    Icons.credit_card_rounded,
  ),
  flutterwave(
    'Flutterwave',
    'Pay securely through Flutterwave at checkout.',
    Icons.payment_rounded,
  ),
  bankTransfer(
    'Bank Transfer',
    'Pay by transferring to the bank account provided for your order.',
    Icons.account_balance_rounded,
  );

  const _AccountPaymentMethod(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  _AccountPaymentMethod? _selectedPaymentMethod;

  Future<void> _openPaymentMethod(
    BuildContext context,
    _AccountPaymentMethod method,
  ) async {
    setState(() {
      _selectedPaymentMethod = method;
    });

    final continueToCheckout = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;

        final isBankTransfer =
            method == _AccountPaymentMethod.bankTransfer;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Icon(
                        method.icon,
                        size: 28,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        method.title,
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  method.description,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isBankTransfer
                            ? Icons.info_outline_rounded
                            : Icons.security_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBankTransfer
                              ? 'Bank account details have not been configured yet. You can add them later. Please do not transfer money until official payment details are displayed and verified.'
                              : 'Your payment will be initiated after you place an order. The final amount and order reference will be sent to the payment provider.',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext, true);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Continue to Checkout'),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (continueToCheckout != true || !context.mounted) return;

    final paymentMethod = switch (method) {
      _AccountPaymentMethod.paystack => PaymentMethod.paystack,
      _AccountPaymentMethod.flutterwave => PaymentMethod.flutterwave,
      _AccountPaymentMethod.bankTransfer => PaymentMethod.bankTransfer,
    };

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          initialPaymentMethod: paymentMethod,
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message:
          'You can sign back in at any time. Your cart and saved items stay on this device.',
      confirmLabel: 'Sign out',
    );

    if (!ok) return;

    await ref.read(authProvider.notifier).logout();

    if (context.mounted) {
      showAppSnack(context, 'Signed out.');
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Delete your account?',
      message:
          'This permanently deletes your account and personal data. This cannot be undone.',
      confirmLabel: 'Delete account',
      destructive: true,
    );

    if (!ok) return;

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      ref.read(cartProvider.notifier).clear();
      ref.read(favouritesProvider.notifier).clear();

      if (context.mounted) {
        showAppSnack(context, 'Your account has been deleted.');
      }
    } catch (error) {
      if (!context.mounted) return;

      final mapped = ApiException.from(error);
      final unsupported =
          mapped.statusCode == 404 || mapped.statusCode == 405;

      showAppSnack(
        context,
        unsupported
            ? 'Please contact support to delete your account.'
            : mapped.message,
        isError: true,
      );
    }
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    String failure,
  ) async {
    final ok = await openExternal(uri);

    if (!ok && context.mounted) {
      showAppSnack(context, failure, isError: true);
    }
  }

  void _openSupport(BuildContext context) {
    final phone = AppConfig.supportPhone.trim();
    final whatsapp =
        AppConfig.supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
    final email = AppConfig.supportEmail.trim();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a way to contact the NaijaMart support team.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),

                if (whatsapp.isNotEmpty)
                  _SupportOption(
                    icon: Icons.chat_rounded,
                    title: 'Chat on WhatsApp',
                    subtitle: 'Send us a message on WhatsApp',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _launch(
                        context,
                        Uri.parse('https://wa.me/$whatsapp'),
                        'Could not open WhatsApp.',
                      );
                    },
                  ),

                if (phone.isNotEmpty)
                  _SupportOption(
                    icon: Icons.phone_rounded,
                    title: 'Call customer support',
                    subtitle: phone,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _launch(
                        context,
                        Uri(scheme: 'tel', path: phone),
                        'Could not open the phone app.',
                      );
                    },
                  ),

                if (email.isNotEmpty)
                  _SupportOption(
                    icon: Icons.email_outlined,
                    title: 'Send us an email',
                    subtitle: email,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _launch(
                        context,
                        Uri(scheme: 'mailto', path: email),
                        'Could not open your email app.',
                      );
                    },
                  ),

                if (phone.isEmpty &&
                    whatsapp.isEmpty &&
                    email.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: const Text(
                      'Customer support contact details have not been configured yet. '
                      'Please check back soon.',
                    ),
                  ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final mode = ref.watch(themeModeProvider);

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: SizedBox.expand(
          child: ListView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              const ScreenHeader(title: 'My account'),
              const SizedBox(height: 16),

              // Customer profile
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: Brand.heroGradient,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: user == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 30,
                            )
                          : Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user == null
                                ? 'Welcome to ${AppConfig.appName}'
                                : user.fullName.isEmpty
                                    ? 'Hello!'
                                    : user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user == null
                                ? 'Sign in to checkout and track orders.'
                                : user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (user == null)
                _Tile(
                  icon: Icons.login_rounded,
                  title: 'Sign in or create account',
                  subtitle: 'Access your orders and checkout faster',
                  onTap: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(),
                    ),
                  ),
                ),

              if (auth.isAdmin)
                _Tile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin dashboard',
                  subtitle: 'Manage products and store orders',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const AdminScreen(),
                    ),
                  ),
                ),

              // Payment methods
              const _SectionLabel('Payment Methods'),
              Text(
                'Choose a payment method to continue to checkout. '
                'You can change it before placing your order.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),

              ..._AccountPaymentMethod.values.map(
                (method) => _PaymentMethodTile(
                  method: method,
                  selected: _selectedPaymentMethod == method,
                  onTap: () => _openPaymentMethod(context, method),
                ),
              ),

              // Help and support
              const _SectionLabel('Help & Support'),

              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openSupport(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            color: scheme.onPrimaryContainer,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact NaijaMart',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Get help with orders, payments and your account.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),

              _Tile(
                icon: Icons.smart_toy_outlined,
                title: 'NaijaMart AI Assistant',
                subtitle: 'Automated shopping support is coming soon',
                onTap: () {
                  showAppSnack(
                    context,
                    'AI support is being connected to the NaijaMart server.',
                  );
                },
              ),

              _Tile(
                icon: Icons.assignment_return_outlined,
                title: 'Returns & refunds',
                subtitle: 'Learn about returns and refund requests',
                onTap: () => openPolicy(context, PolicyKind.returns),
              ),

              // Appearance
              const _SectionLabel('Appearance'),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) => ref
                          .read(themeModeProvider.notifier)
                          .setMode(value.first),
                    ),
                  ),
                ),
              ),

              // Legal
              const _SectionLabel('Legal'),

              _Tile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => openPolicy(context, PolicyKind.privacy),
              ),

              _Tile(
                icon: Icons.description_outlined,
                title: 'Terms of use',
                onTap: () => openPolicy(context, PolicyKind.terms),
              ),

              // Account actions
              if (user != null) ...[
                const _SectionLabel('Account'),

                _Tile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: () => _signOut(context, ref),
                ),

                _Tile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle: 'Permanently remove your data',
                  destructive: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ],

              const SizedBox(height: 20),

              Text(
                '${AppConfig.appName} • Shop confidently',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: destructive ? scheme.error : null,
            ),
          ),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _AccountPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 0.8,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    method.icon,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
