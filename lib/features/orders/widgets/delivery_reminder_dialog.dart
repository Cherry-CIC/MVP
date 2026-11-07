import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/orders/delivery_countdown.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/order_reminder_item_summary.dart';
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
                OrderReminderItemSummary(order: widget.order),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    'Your item has been collected',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: remaining.countdownText,
                        semanticsLabel: remaining.spokenCountdown,
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const TextSpan(text: ' left to check and confirm your item.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('The 48 hours started when you collected your parcel.'),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAction,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    shape: shape,
                  ),
                  onPressed: remaining <= Duration.zero
                      ? null
                      : () => Navigator.pop(context, DeliveryReminderAction.view),
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
                  onPressed: remaining <= Duration.zero
                      ? null
                      : () => Navigator.pop(context, DeliveryReminderAction.report),
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
