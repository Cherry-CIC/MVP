import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/config/theme_mode.dart';
import 'package:cherry_mvp/features/settings/setings_view_model.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_account.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_footer.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_personal.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_shop.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_support.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_toggle_section.dart';
import 'package:cherry_mvp/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isSwitchedDark = false;
  bool isSwitchedHide = false;

  void toggleSwitchDark(bool value) {
    setState(() {
      isSwitchedDark = value;
    });
    if (value) {
      appThemeModeNotifier.darkMode();
      context.read<SettingsViewModel>().setThemeMode(AppThemeModeE.dark.json);
    } else {
      appThemeModeNotifier.lightMode();
      context.read<SettingsViewModel>().setThemeMode(AppThemeModeE.dark.json);
    }
  }

  void toggleSwitchHide(bool value) {
    setState(() {
      isSwitchedHide = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppStrings.settingsText),
            floating: true,
            snap: true,
          ),
          SettingsToggleSection(
            isSwitchedDark: isSwitchedDark,
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
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
          ),
        ],
      ),
    );
  }
}
