import 'package:cherry_mvp/core/config/app_theme.dart';
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

  // Connect to local emulators in debug mode
  if (kDebugMode) {
    try {
      const host = 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      print('Connected to Firebase Emulators');
    } catch (e) {
      print('Failed to connect to Firebase Emulators: $e');
    }
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(providers: [...buildProviders(prefs)], child: MyApp()));
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
