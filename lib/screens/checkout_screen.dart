
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_provider.dart';
import '../services/store_api.dart';
import '../widgets/ui.dart';
import 'order_confirmation_screen.dart';

enum PaymentMethod {
  paystack(
    'paystack',
    'Pay with Paystack',
    'Card, bank and USSD payments',
    Icons.lock_outline_rounded,
  ),
  flutterwave(
    'flutterwave',
    'Pay with Flutterwave',
    'Secure card and bank payments',
    Icons.payment_rounded,
  ),
  bankTransfer(
    'bank_transfer',
    'Bank transfer',
    'Your order is held until we confirm your transfer',
    Icons.account_balance_outlined,
  );

  const PaymentMethod(
    this.apiValue,
    this.title,
    this.subtitle,
    this.icon,
  );

  final String apiValue;
  final String title;
  final String subtitle;
  final IconData icon;
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({
    super.key,
    this.initialPaymentMethod = PaymentMethod.paystack,
  });

  final PaymentMethod initialPaymentMethod;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _recipient = TextEditingController(
    text: ref.read(authProvider).user?.fullName ?? '',
  );

  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();

  late PaymentMethod _payment;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payment = widget.initialPaymentMethod;
  }

  @override
  void dispose() {
    _recipient.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  String get _deliveryAddress => [
        '${_recipient.text.trim()} (${_phone.text.trim()})',
        _street.text.trim(),
        '${_city.text.trim()}, ${_state.text.trim()}',
      ].join('\n');

  Future<void> _placeOrder() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final lines = ref.read(cartProvider);

    if (lines.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }

    if (!ref.read(authProvider).isAuthenticated) {
      setState(() {
        _error = 'Please sign in before placing your order.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = ref.read(storeApiProvider);

      // Synchronise the cart with the backend.
      for (final line in lines) {
        await api.updateCartItem(
          line.product.id,
          line.quantity,
        );
      }

      // The backend calculates and validates the final order amount.
      final result = await api.checkout(
        deliveryAddress: _deliveryAddress,
        paymentMethod: _payment.apiValue,
      );

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(ordersProvider);

      if (!mounted) return;

      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            result: result,
            method: _payment,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final mapped = ApiException.from(error);

      setState(() {
        _error = mapped.isUnauthorized
            ? 'Your session has expired. Please sign in again.'
            : mapped.message;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final lines = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ContentWidth(
        maxWidth: 640,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: scheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // DELIVERY DETAILS
              _SectionTitle('Delivery details'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _recipient,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Recipient name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2)
                        ? 'Enter the recipient’s name'
                        : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.telephoneNumber,
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '0801 234 5678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    isValidNigerianPhone(v ?? '')
                        ? null
                        : 'Enter a valid Nigerian phone number',
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _street,
                enabled: !_busy,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.streetAddressLine1,
                ],
                decoration: const InputDecoration(
                  labelText: 'Street address',
                  hintText: 'House number, street and area',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5)
                        ? 'Enter your street address'
                        : null,
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.addressCity,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'City',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _state,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.addressState,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'State',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // PAYMENT METHODS
              _SectionTitle('Payment method'),
              const SizedBox(height: 10),

              for (final method in PaymentMethod.values) ...[
                _PaymentTile(
                  method: method,
                  selected: _payment == method,
                  onTap: _busy
                      ? null
                      : () {
                          setState(() {
                            _payment = method;
                            _error = null;
                          });
                        },
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 14),

              // ORDER SUMMARY
              _SectionTitle('Order summary'),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${line.quantity} × ${line.product.name}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                naira(line.totalKobo),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 22),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            naira(subtotal),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Delivery fees and taxes, if any, are confirmed by the store with your order.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PLACE ORDER
              FilledButton(
                onPressed: _busy ? null : _placeOrder,
                child: _busy
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Place order · ${naira(subtotal, showDecimals: false)}',
                      ),
              ),

              const SizedBox(height: 12),

              Text(
                'Online payments are securely processed by Paystack or Flutterwave. NaijaMart never sees or stores your card details. Bank transfers require confirmation.',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: '${method.title}. ${method.subtitle}',
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .07)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: selected
                ? scheme.primary
                : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  method.icon,
                  color: scheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? scheme.primary
                      : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
