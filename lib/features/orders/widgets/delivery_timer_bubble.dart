import 'dart:async';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/features/orders/delivery_countdown.dart';
import 'package:flutter/material.dart';

enum DeliveryTimerPurpose { confirmation, collection }

class DeliveryTimerBubble extends StatefulWidget {
  const DeliveryTimerBubble({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onExpired,
    this.now = DateTime.now,
    this.purpose = DeliveryTimerPurpose.confirmation,
  });

  final DateTime deadline;
  final DeliveryTimerPurpose purpose;
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
    final isCollection = widget.purpose == DeliveryTimerPurpose.collection;
    final verb = isCollection ? 'collect' : 'confirm';
    final availableWidth = MediaQuery.sizeOf(context).width - MediaQuery.paddingOf(context).horizontal - 32;
    final accent = isDark ? colours.onPrimaryContainer : AppColors.primaryAction;
    return Semantics(
      button: true,
      label: '${isCollection ? 'Collection' : 'Delivery'} reminder, ${remaining.spokenCountdown} left to $verb',
      hint: isCollection ? 'Open collection details' : 'Open delivery details',
      child: Material(
        shape: const StadiumBorder(),
        color: isDark ? colours.surfaceContainerHigh : AppColors.pinkBackground,
        elevation: isCollection ? 3 : 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            if (_remaining > Duration.zero) widget.onTap();
          },
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: isCollection ? 56 : 48,
                // Scaffold offsets an end-floating control from the screen edge.
                // Leave room for both margins when enlarged text needs to wrap.
                maxWidth: availableWidth > 0 ? availableWidth : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: isCollection ? 34 : 30, color: accent),
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
                              fontSize: isCollection ? 20 : null,
                              color: accent,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'left to $verb',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isCollection ? colours.onSurfaceVariant : colours.onSurface,
                            ),
                          ),
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
