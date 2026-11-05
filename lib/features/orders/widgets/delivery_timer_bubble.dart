import 'dart:async';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/orders/delivery_countdown.dart';
import 'package:flutter/material.dart';

class DeliveryTimerBubble extends StatefulWidget {
  const DeliveryTimerBubble({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onExpired,
    this.now = DateTime.now,
  });

  final DateTime deadline;
  final DateTime Function() now;
  final VoidCallback onTap;
  final VoidCallback onExpired;

  @override
  State<DeliveryTimerBubble> createState() => _DeliveryTimerBubbleState();
}

class _DeliveryTimerBubbleState extends State<DeliveryTimerBubble> {
  Timer? _timer;
  Duration get _remaining => widget.deadline.difference(widget.now());

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void didUpdateWidget(DeliveryTimerBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _timer?.cancel();
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    final remaining = _remaining;
    final delay = remaining < const Duration(seconds: 1) ? remaining : const Duration(seconds: 1);
    _timer = Timer(delay, () {
      setState(() {});
      if (_remaining <= Duration.zero) {
        widget.onExpired();
      } else {
        _scheduleTick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    if (remaining <= Duration.zero) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colours = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? colours.onPrimaryContainer : AppColors.primaryAction;
    return Semantics(
      button: true,
      label: 'Delivery reminder, ${remaining.spokenCountdown} left to confirm',
      hint: 'Open delivery details',
      child: Material(
        shape: const StadiumBorder(),
        color: isDark ? colours.surfaceContainerHigh : AppColors.pinkBackground,
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            if (_remaining > Duration.zero) widget.onTap();
          },
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 30, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remaining.countdownText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accent,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text('left to confirm', style: theme.textTheme.bodySmall?.copyWith(color: colours.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
