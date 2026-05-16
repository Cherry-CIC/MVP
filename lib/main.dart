import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Load environment variables
  await dotenv.load();

  await Firebase.initializeApp();
  await _configureFirebaseEmulators();

  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(providers: [...buildProviders(prefs)], child: MyApp()));
}

Future<void> _configureFirebaseEmulators() async {
  if (!kDebugMode) {
    return;
  }

  final emulatorConfig = AppEnvironment.firebaseEmulatorConfig;
  if (emulatorConfig == null) {
    return;
  }

  await FirebaseAuth.instance.useAuthEmulator(
    emulatorConfig.host,
    emulatorConfig.authPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    emulatorConfig.host,
    emulatorConfig.firestorePort,
  );

  debugPrint(
    'Firebase emulators enabled on ${emulatorConfig.host} '
    '(auth: ${emulatorConfig.authPort}, '
    'firestore: ${emulatorConfig.firestorePort})',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, ThemeNotifier>(
      builder: (context, navigatorService, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorService.navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          theme: buildTheme(),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeNotifier.mode,
          home: AuthGate(),
        );
      },
    );
  }
}
