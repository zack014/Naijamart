
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/launcher.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../providers/app_providers.dart';
import '../providers/orders_provider.dart';
import '../widgets/ui.dart';
import 'checkout_screen.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.result,
    required this.method,
  });

  final CheckoutResult result;
  final PaymentMethod method;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  bool _checking = false;

  // Both Paystack and Flutterwave are online payment providers.
  bool get _isOnline =>
      widget.method == PaymentMethod.paystack ||
      widget.method == PaymentMethod.flutterwave;

  bool get _isBankTransfer =>
      widget.method == PaymentMethod.bankTransfer;

  @override
  void initState() {
    super.initState();

    if (_isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pay(auto: true);
      });
    }
  }

  Future<void> _pay({bool auto = false}) async {
    final uri = safeHttpsUri(widget.result.paymentUrl);

    if (uri == null) {
      if (!auto && mounted) {
        showAppSnack(
          context,
          'The payment link is unavailable. Contact support with your order reference.',
          isError: true,
        );
      }
      return;
    }

    final opened = await openExternal(uri);

    if (!opened && mounted) {
      showAppSnack(
        context,
        'Could not open the payment page.',
        isError: true,
        actionLabel: 'Retry',
        onAction: _pay,
      );
    }
  }

  Future<void> _checkStatus() async {
    if (_checking) return;

    setState(() => _checking = true);

    try {
      final orders = await ref.refresh(ordersProvider.future);

      if (!mounted) return;

      Order? match;

      for (final order in orders) {
        if (order.reference == widget.result.reference) {
          match = order;
          break;
        }
      }

      if (match == null) {
        showAppSnack(
          context,
          'We could not find this order yet. Try again shortly.',
        );
      } else if (match.isPaid) {
        showAppSnack(
          context,
          'Payment received. Thank you!',
        );
      } else {
        showAppSnack(
          context,
          'Payment is still ${match.paymentStatus.toLowerCase()}.',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          '$error',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  void _goTo(int tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ref.read(navIndexProvider.notifier).state = tab;
  }

  String get _paymentMessage {
    if (widget.method == PaymentMethod.paystack) {
      return 'Complete your Paystack payment to confirm your order. If the payment page did not open, tap Pay now.';
    }

    if (widget.method == PaymentMethod.flutterwave) {
      return 'Complete your Flutterwave payment to confirm your order. If the payment page did not open, tap Pay now.';
    }

    return 'Your order has been created. We will confirm it after your bank transfer has been received and verified.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reference = widget.result.reference;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(NavTab.home);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Order placed'),
        ),
        body: SafeArea(
          child: ContentWidth(
            maxWidth: 560,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Brand.success.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 48,
                      color: Brand.success,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Thank you for your order!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _paymentMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 22),

                if (reference.isNotEmpty)
                  Card(
                    child: ListTile(
                      title: const Text('Order reference'),
                      subtitle: Text(
                        reference,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Copy reference',
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: reference),
                          );

                          if (context.mounted) {
                            showAppSnack(
                              context,
                              'Reference copied',
                            );
                          }
                        },
                      ),
                    ),
                  ),

                if (_isBankTransfer) ...[
                  const SizedBox(height: 12),
                  _BankDetails(reference: reference),
                ],

                const SizedBox(height: 22),

                if (_isOnline) ...[
                  FilledButton.icon(
                    onPressed: () => _pay(),
                    icon: const Icon(Icons.lock_outline_rounded),
                    label: const Text('Pay now'),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: _checking ? null : _checkStatus,
                    child: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Refresh payment status'),
                  ),

                  const SizedBox(height: 10),
                ],

                if (_isBankTransfer)
                  FilledButton(
                    onPressed: () => _goTo(NavTab.orders),
                    child: const Text('View my orders'),
                  )
                else
                  TextButton(
                    onPressed: () => _goTo(NavTab.orders),
                    child: const Text('View my orders'),
                  ),

                TextButton(
                  onPressed: () => _goTo(NavTab.home),
                  child: const Text('Continue shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BankDetails extends StatelessWidget {
  const _BankDetails({
    required this.reference,
  });

  final String reference;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppConfig.hasBankDetails
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transfer to',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(AppConfig.bankName),

                  Text(
                    AppConfig.bankAccountNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 1,
                    ),
                  ),

                  if (AppConfig.bankAccountName.isNotEmpty)
                    Text(AppConfig.bankAccountName),

                  const SizedBox(height: 10),

                  Text(
                    'Use $reference as the payment reference so we can match your transfer.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(
                'Contact support with your order reference to receive our bank account details.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
      ),
    );
  }
}
