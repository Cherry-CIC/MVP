import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/config/theme_mode.dart';
import 'package:cherry_mvp/features/settings/setings_view_model.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/router.dart';
import 'core/utils/utils.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Load environment variables
  await dotenv.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(providers: [...buildProviders(prefs)], child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) async {
      _setThemeMode(context.read<SettingsViewModel>().themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigatorService, child) {
        return ListenableBuilder(
          listenable: appThemeModeNotifier,

          builder: (context, child) => MaterialApp(
            navigatorKey: navigatorService.navigatorKey,
            onGenerateRoute: AppRoutes.generateRoute,
            themeMode: appThemeModeNotifier.themeMode,
            theme: buildTheme(),
            darkTheme: buildTheme(Brightness.dark),
            home: WelcomePage(),
          ),
        );
      },
    );
  }
}

void _setThemeMode(String mode) {
  switch (mode.mode) {
    case AppThemeModeE.light:
      appThemeModeNotifier.lightMode();
      break;
    case AppThemeModeE.dark:
      appThemeModeNotifier.darkMode();
      break;
    default:
      appThemeModeNotifier.systemMode();
      break;
  }
}

enum AppThemeModeE {
  dark('dark'),
  light('light'),
  system('system');

  final String json;

  const AppThemeModeE(this.json);
}

extension ThemeModeX on String {
  AppThemeModeE get mode => AppThemeModeE.values.firstWhere(
    (element) => element.json == this,
    orElse: () => AppThemeModeE.dark,
  );
}
