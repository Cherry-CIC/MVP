// feature/118-product-details-page
import 'package:cherry_mvp/features/products/product_page.dart';

import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/settings/settings_page.dart';
// main
import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/register/registerpage.dart';
import 'package:cherry_mvp/features/home/homepage.dart';
import 'package:cherry_mvp/features/login/loginpage.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgotPassword';
  static const String home = '/home';
  static const String chat = '/chat'; // <- added chat route
  static const String discover = '/discover';
// feature/118-product-details-page
  static const String product = '/product'; // <- added product route

  static const String settingspage = '/settings';
// main

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case product:
        // Assuming ProductPage takes a productId as an argument
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductPage(productId: productId),
        );
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case discover:
        return MaterialPageRoute(builder: (_) => DiscoverPage());
      case settingspage:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
