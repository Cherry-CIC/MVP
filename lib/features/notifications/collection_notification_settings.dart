import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'collection_push_controller.dart';

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
          title: const Text('Collection notifications'),
          subtitle: const Text(
            'Let cherry notify you when your parcel is ready to collect. Reminders in the app always work.',
          ),
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
