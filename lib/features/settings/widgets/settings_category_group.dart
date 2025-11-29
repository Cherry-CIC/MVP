import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';

class SettingsCategoryGroup extends StatelessWidget {
  const SettingsCategoryGroup({
    super.key,
    required this.children,
    required this.heading,
    this.onTap,
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
        if (item.title == AppStrings.logOutText) {
          return SettingsItem(
            title: item.title,
            trailing: item.trailing,
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Sign out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Sign out',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                context.read<LoginViewModel>().clearStatus();
                context.read<AuthViewModel>().logout(context);
              }
            },
          );
        }
        return SettingsItem(
          title: item.title,
          trailing: item.trailing,
          onTap: () {
            // Inside the closure, we check if the item has an action...
            if (item.onTap != null) {
              // ...and execute that action, passing the context available from itemBuilder.
              item.onTap!(context);
            }
          },
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('heading', heading));
  }
}
