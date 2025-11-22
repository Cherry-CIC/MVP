import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';

class SettingsCategoryGroup extends StatelessWidget {
  const SettingsCategoryGroup({
    super.key,
    required this.children,
    required this.heading, this.onTap,
  });

  final List<SectionSettingsItem> children;
  final VoidCallback? onTap;
  final String heading;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
        itemCount: children.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(heading),
              titleTextStyle: Theme.of(context).textTheme.titleMedium,
            );
          }
          final item = children[index - 1];
          return SettingsItem(
            title: item.title,
            onTap: () {
            // Inside the closure, we check if the item has an action...
            if (item.onTap != null) {
              // ...and execute that action, passing the context available from itemBuilder.
              item.onTap!(context);
            }
          },
            trailing: item.trailing,
          );
        });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('heading', heading));
  }
}
