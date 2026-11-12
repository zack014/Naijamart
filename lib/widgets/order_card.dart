import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/order.dart';
import 'ui.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = formatDateTime(order.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showOrderDetails(context, order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    text: humanize(order.status),
                    color: statusColor(context, order.status),
                  ),
                ],
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(date,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusPill(
                    text: 'Payment ${order.paymentStatus.toLowerCase()}',
                    color: statusColor(context, order.paymentStatus),
                  ),
                  const Spacer(),
                  Text(naira(order.totalKobo),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showOrderDetails(BuildContext context, Order order) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => _OrderSheet(order: order),
  );
}

class _OrderSheet extends StatelessWidget {
  const _OrderSheet({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      minChildSize: .4,
      maxChildSize: .92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Order details',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              StatusPill(
                text: humanize(order.status),
                color: statusColor(context, order.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Row(
            label: 'Reference',
            value: order.reference,
            trailing: IconButton(
              tooltip: 'Copy reference',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: order.reference));
                if (context.mounted) showAppSnack(context, 'Reference copied');
              },
            ),
          ),
          if (formatDateTime(order.createdAt).isNotEmpty)
            _Row(label: 'Placed', value: formatDateTime(order.createdAt)),
          _Row(label: 'Payment', value: humanize(order.paymentStatus)),
          if (order.paymentMethod.isNotEmpty)
            _Row(label: 'Method', value: humanize(order.paymentMethod)),
          if (order.deliveryAddress.isNotEmpty)
            _Row(label: 'Deliver to', value: order.deliveryAddress),
          if (order.items.isNotEmpty) ...[
            const Divider(height: 28),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('${item.quantity} × ${item.name}')),
                    const SizedBox(width: 12),
                    Text(naira(item.totalKobo),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(naira(order.totalKobo),
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900, color: scheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
