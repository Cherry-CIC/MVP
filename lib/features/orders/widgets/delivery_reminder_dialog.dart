import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/order_currency_formatter.dart';
import 'package:flutter/material.dart';

enum DeliveryReminderAction { view, report, interrupted }

class DeliveryReminderDialog extends StatefulWidget {
  const DeliveryReminderDialog({super.key, required this.order});
  final OrderSummary order;

  @override
  State<DeliveryReminderDialog> createState() => _DeliveryReminderDialogState();
}

class _DeliveryReminderDialogState extends State<DeliveryReminderDialog> {
  late final Timer _ticker;

  Duration get _remaining => widget.order.confirmationDeadline!.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= Duration.zero && ModalRoute.of(context)?.isCurrent == true) {
        _ticker.cancel();
        Navigator.pop(context, DeliveryReminderAction.interrupted);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = _remaining;
    final seconds = remaining.isNegative ? 0 : (remaining.inMilliseconds + 999) ~/ 1000;
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
    final accent = theme.brightness == Brightness.dark ? scheme.onPrimaryContainer : AppColors.primaryAction;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        alignment: Alignment.bottomCenter,
        insetPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: scheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ItemSummary(order: widget.order),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    'Your item has arrived',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: time,
                        semanticsLabel: '${seconds ~/ 3600} hours and ${seconds ~/ 60 % 60} minutes',
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const TextSpan(text: ' left to check and confirm your item.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('The 48 hours started when your parcel arrived at the collection point.'),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: shape,
                  ),
                  onPressed: seconds == 0 ? null : () => Navigator.pop(context, DeliveryReminderAction.view),
                  child: const Text('View item'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surfaceContainerHighest,
                    foregroundColor: accent,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: shape,
                  ),
                  onPressed: seconds == 0 ? null : () => Navigator.pop(context, DeliveryReminderAction.report),
                  child: const Text('Something’s not right'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [order.size, order.condition].where((s) => s.isNotEmpty).join(' · ');
    final price = OrderCurrencyFormatter.formatItemPrice(order);
    return Row(
      children: [
        SizedBox.square(
          dimension: 70,
          child: order.imageUrl.isEmpty
              ? const Icon(Icons.shopping_bag_outlined)
              : ImageProviderHelper.buildImage(imagePath: order.imageUrl, borderRadius: BorderRadius.circular(8)),
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ImageProviderHelper.buildImage(
                  imagePath: order.charityLogoUrl,
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xffd6ffca), borderRadius: BorderRadius.circular(6)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'Delivered',
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
