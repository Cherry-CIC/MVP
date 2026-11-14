import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/app_info_provider.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';

class SettingsFooter extends StatefulWidget {
  const SettingsFooter({
    super.key,
    this.packageInfoLoader,
  });

  final Future<PackageInfo> Function()? packageInfoLoader;

  @override
  State<SettingsFooter> createState() => _SettingsFooterState();
}

class _SettingsFooterState extends State<SettingsFooter> {
  bool _isDeletingAccount = false;
  late final Future<String?> _versionFuture = _loadAppVersion();

  Future<String?> _loadAppVersion() async {
    try {
      final loader = widget.packageInfoLoader ?? PackageInfo.fromPlatform;
      final info = await loader();
      final formatted = AppStrings.formatAppVersion(info.version, info.buildNumber);
      return formatted.isEmpty ? null : formatted;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appInfo = context.watch<AppInfoProvider?>();

    return SliverList.list(
      children: [
        ListTile(
          title: Text(AppStrings.deleteAccountText),
          textColor: Theme.of(context).colorScheme.primary,
          trailing: _isDeletingAccount
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: () async {
            if (_isDeletingAccount) return;

            final confirm = await _showConfirmDialog(context);
            if (confirm != true) return;
            if (!context.mounted) return;

            setState(() => _isDeletingAccount = true);
            final result = await context.read<AuthViewModel>().deleteAccount();

            if (!context.mounted) return;
            setState(() => _isDeletingAccount = false);

            if (!result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.error ?? 'Failed to delete account')),
              );
            }
          },
        ),
        FutureBuilder<String?>(
          future: _versionFuture,
          builder: (context, snapshot) {
            final versionText = snapshot.data;
            return ListTile(
              title: Text(AppStrings.appName),
              titleTextStyle: Theme.of(context).textTheme.titleMedium,
              subtitle: versionText == null ? null : Text(versionText),
              subtitleTextStyle: Theme.of(context).textTheme.labelLarge,
            );
          },
        ),
      ],
    );
  }
}
