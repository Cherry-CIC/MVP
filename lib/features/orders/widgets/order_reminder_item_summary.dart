import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/order_currency_formatter.dart';
import 'package:flutter/material.dart';

class OrderReminderItemSummary extends StatelessWidget {
  const OrderReminderItemSummary({super.key, required this.order, this.showCollectedBadge = true});
  final bool showCollectedBadge;
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [order.size, order.condition].where((s) => s.isNotEmpty).join(' · ');
    final price = OrderCurrencyFormatter.formatItemPrice(order);
    return Row(
      children: [
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: 70,
            child: order.imageUrl.isEmpty
                ? const Icon(Icons.shopping_bag_outlined)
                : ImageProviderHelper.buildImage(imagePath: order.imageUrl, borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.productName, style: theme.textTheme.titleSmall),
              if (details.isNotEmpty) Text(details, style: theme.textTheme.bodySmall),
              Text('Order #${order.id}', style: theme.textTheme.bodySmall),
              if (price != null) Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (order.charityLogoUrl.isNotEmpty)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ImageProviderHelper.buildImage(
                    imagePath: order.charityLogoUrl,
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (showCollectedBadge)
              DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xffd6ffca), borderRadius: BorderRadius.circular(6)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Text(
                    'Collected',
                    style: TextStyle(color: Color(0xff205b12), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
