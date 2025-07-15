import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';

class SettingsCategoryGroup extends StatelessWidget {
  const SettingsCategoryGroup({
    super.key,
    required this.children,
    required this.heading,
  });

  final List<SectionSettingsItem> children;
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
            onTap: () {},
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
