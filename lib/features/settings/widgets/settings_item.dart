import 'package:flutter/material.dart';

class SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String? trailing;

  const SettingsItem(
      {super.key, required this.title, this.onTap, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title),
      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
      trailing: SizedBox(
        height: 24,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if ((trailing ?? '').isNotEmpty)
              Text(
                trailing!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
