import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_toggle_section.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_support.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_personal.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_shop.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_account.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_footer.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isSwitchedHide = false;
  void toggleSwitchDark(bool value) {
    context.read<ThemeNotifier>().toggleDark(value);
  }

  void toggleSwitchHide(bool value) {
    setState(() {
      isSwitchedHide = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppStrings.settingsText),
            floating: true,
            snap: true,
          ),
          SettingsToggleSection(
            isSwitchedDark: themeNotifier.isDark,
            toggleSwitchDark: toggleSwitchDark,
            isSwitchedHide: isSwitchedHide,
            toggleSwitchHide: toggleSwitchHide,
          ),
          SettingsSupport(),
          SettingsPersonal(),
          SettingsShop(),
          SettingsAccount(),
          SettingsFooter(),
          SliverPadding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }
}
