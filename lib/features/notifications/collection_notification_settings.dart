import 'dart:ui' show ImageFilter;
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'collection_push_controller.dart';

const String kDeliveryNotificationSubtitle =
    "From pickups to dropoffs, get delivery updates so you never miss a step! (We won't take the micky with notifications)";

class CollectionNotificationSettings extends StatelessWidget {
  const CollectionNotificationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final push = context.watch<CollectionPushController?>();
    if (push == null || !push.supported) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          title: const Text('Delivery notifications'),
          subtitle: const Text(kDeliveryNotificationSubtitle),
          value: push.enabled,
          onChanged: push.busy ? null : push.setEnabled,
        ),
        if (push.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(push.error!),
                  if (push.enabled && !push.registered)
                    TextButton(onPressed: push.busy ? null : push.refresh, child: const Text('Try again')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DeliveryNotificationPromptDialog extends StatelessWidget {
  const DeliveryNotificationPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Get delivery updates',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  kDeliveryNotificationSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: buttonStyle.copyWith(
                    backgroundColor: const WidgetStatePropertyAll(AppColors.primaryAction),
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow updates'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
