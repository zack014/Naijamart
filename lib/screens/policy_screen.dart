import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/launcher.dart';
import '../widgets/ui.dart';

enum PolicyKind { privacy, terms, returns }

/// Opens the hosted policy when a URL is configured (`PRIVACY_URL`,
/// `TERMS_URL`), otherwise the built-in summary.
Future<void> openPolicy(BuildContext context, PolicyKind kind) async {
  final hosted = switch (kind) {
    PolicyKind.privacy => AppConfig.privacyUrl,
    PolicyKind.terms => AppConfig.termsUrl,
    PolicyKind.returns => '',
  };
  final uri = safeHttpsUri(hosted);
  if (uri != null) {
    if (await openExternal(uri)) return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PolicyScreen(kind: kind)),
  );
}

// IMPORTANT: this text summarises what the app does. Have it reviewed by a
// lawyer and replace it with your real policies (or host them and set
// PRIVACY_URL / TERMS_URL) before publishing to the app stores.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.kind});
  final PolicyKind kind;

  static const _content = <PolicyKind, (String, List<(String, String)>)>{
    PolicyKind.privacy: (
      'Privacy Policy',
      [
        (
          'What we collect',
          'When you create an account we collect your name and email address. '
              'When you place an order we collect your delivery name, phone number and address, and your order history.',
        ),
        (
          'How we use it',
          'We use this information to create your account, process and deliver your orders, '
              'send order updates and provide customer support.',
        ),
        (
          'Payments',
          'Online payments are processed by Paystack. NaijaMart does not see or store your card details.',
        ),
        (
          'On your device',
          'Your cart, saved items and sign-in session are stored on your device. '
              'Your sign-in token is kept in your phone’s secure storage and removed when you sign out.',
        ),
        (
          'Your choices',
          'You can sign out at any time, and you can request deletion of your account from the Account tab or by contacting support.',
        ),
      ],
    ),
    PolicyKind.terms: (
      'Terms of Use',
      [
        (
          'Using NaijaMart',
          'By creating an account or placing an order you agree to use the app lawfully and to provide accurate information.',
        ),
        (
          'Orders and pricing',
          'Prices are shown in Nigerian naira. Product availability and the final order total, including any delivery charges, '
              'are confirmed by the store when you place your order.',
        ),
        (
          'Your account',
          'Keep your password private. You are responsible for activity on your account.',
        ),
      ],
    ),
    PolicyKind.returns: (
      'Returns & Refunds',
      [
        (
          'Returns',
          'Return and refund terms are set by NaijaMart and confirmed at the time of purchase. '
              'If there is a problem with an order, contact support with your order reference.',
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, sections) = _content[kind]!;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            for (final (heading, body) in sections) ...[
              Semantics(
                header: true,
                child: Text(heading,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 6),
              Text(body,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(height: 1.55, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
            ],
            if (AppConfig.supportEmail.isNotEmpty)
              Text('Questions? Email ${AppConfig.supportEmail}.',
                  style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
