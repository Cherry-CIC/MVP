import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/orders/delivery_countdown.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/order_reminder_item_summary.dart';
import 'package:flutter/material.dart';

enum ReadyToCollectAction { openMap, trackParcel, dismiss }

/// Presentation only: the caller owns eligibility, persistence and navigation.
/// Supply the stored arrival-based deadline, never a fresh 72-hour window.
class ReadyToCollectDialog extends StatefulWidget {
  const ReadyToCollectDialog({
    super.key,
    required this.order,
    required this.collectionDeadline,
    this.now,
    this.canOpenMap = false,
    this.canTrackParcel = false,
  });

  final OrderSummary order;
  final DateTime collectionDeadline;
  final DateTime Function()? now;
  final bool canOpenMap;
  final bool canTrackParcel;

  @override
  State<ReadyToCollectDialog> createState() => _ReadyToCollectDialogState();
}

class _ReadyToCollectDialogState extends State<ReadyToCollectDialog> with WidgetsBindingObserver {
  late final Timer _ticker;
  Duration get _remaining => widget.collectionDeadline.difference((widget.now ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    _ticker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _complete(ReadyToCollectAction action) {
    // Recheck at the instant of the tap, including between timer ticks.
    if (action == ReadyToCollectAction.openMap && _remaining <= Duration.zero) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final remaining = _remaining;
    final expired = remaining <= Duration.zero;
    final showMap = !expired && widget.canOpenMap;
    final showTracking = !showMap && widget.canTrackParcel;
    final accent = isDark ? scheme.onPrimaryContainer : AppColors.primaryAction;
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        alignment: Alignment.bottomCenter,
        insetPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        backgroundColor: isDark ? scheme.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderReminderItemSummary(order: widget.order, showCollectedBadge: false),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  child: Text(
                    expired ? 'Collection window ended' : 'Ready to collect',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  expired
                      ? 'Your 72-hour collection window has ended. Check InPost for the latest parcel status.'
                      : 'Please collect your item from the InPost locker.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (!expired) ...[
                  const SizedBox(height: 8),
                  // Read on focus; do not interrupt the screen reader every second.
                  Semantics(
                    label: '${remaining.spokenCountdown} left to collect',
                    excludeSemantics: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Time left: '),
                          TextSpan(
                            text: remaining.countdownText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (showMap || showTracking) ...[
                  FilledButton(
                    style: buttonStyle.copyWith(
                      backgroundColor: const WidgetStatePropertyAll(AppColors.primaryAction),
                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    ),
                    onPressed: () =>
                        _complete(showMap ? ReadyToCollectAction.openMap : ReadyToCollectAction.trackParcel),
                    child: Text(showMap ? 'Open map' : 'Track parcel'),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton.tonal(
                  style: buttonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      isDark ? scheme.surfaceContainerHighest : const Color(0xFFE0E0E0),
                    ),
                    foregroundColor: WidgetStatePropertyAll(accent),
                  ),
                  onPressed: () => _complete(ReadyToCollectAction.dismiss),
                  child: Text(expired ? 'I understand' : 'Not yet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
