import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/utils/utils.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Load environment variables
  await dotenv.load();

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  Stripe.merchantIdentifier = dotenv.env['STRIPE_MERCHANT_IDENTIFIER']!;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(providers: [...buildProviders(prefs)], child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigatorService, child) {
        return MaterialApp(
          navigatorKey: navigatorService.navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          theme: buildTheme(),
          darkTheme: buildTheme(Brightness.dark),
          home: WelcomePage(),
        );
      },
    );
  }
}
