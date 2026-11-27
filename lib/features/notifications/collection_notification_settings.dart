import 'package:app_settings/app_settings.dart';
import 'push_messaging_gateway.dart';
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
          title: const Text('Locker collection alerts'),
          subtitle: const Text('Get a notification when your parcel is ready to collect.'),
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
                  if (push.permission == PushPermission.denied)
                    TextButton(onPressed: () => AppSettings.openAppSettings(), child: const Text('Open phone settings'))
                  else if (push.enabled && !push.registered)
                    TextButton(onPressed: push.busy ? null : push.refresh, child: const Text('Try again')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
