import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/config/environment_config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/dependency.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_gate.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  SafeLog.event(AppLogEvent.firebaseEmulatorsEnabled);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigatorKey = context.read<NavigationProvider>().navigatorKey;

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          theme: buildTheme(),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeNotifier.mode,
          home: child,
        );
      },
      child: AuthGate(),
    );
  }
}
