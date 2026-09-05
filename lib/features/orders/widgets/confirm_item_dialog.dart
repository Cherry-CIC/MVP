import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:flutter/material.dart';

enum ConfirmItemAction { confirm, dispute }

class ConfirmItemDialog extends StatelessWidget {
  final OrderSummary order;

  const ConfirmItemDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOrderImage = order.imageUrl.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Confirm this item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOrderImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    order.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Text(
            order.productName,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('Have you received your item as expected?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(ConfirmItemAction.dispute),
          child: const Text('Raise dispute'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ConfirmItemAction.confirm),
          child: const Text('Yes, all good'),
        ),
      ],
    );
  }
}