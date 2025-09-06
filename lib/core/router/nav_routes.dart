// feature/118-product-details-page
import 'package:cherry_mvp/features/checkout/checkout_complete_page.dart';
import 'package:cherry_mvp/features/checkout/checkout_page.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/donation/successful_upload_page.dart';
import 'package:cherry_mvp/features/products/product_page.dart';

import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/settings/settings_page.dart';
// main
import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/register/register_page.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/login/login_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgotPassword';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String discover = '/discover';
  static const String product = '/product';
  static const String settingspage = '/settings';
  static const String donations = '/donations';
  static const String checkout = '/checkout';
  static const String checkoutComplete = '/checkoutComplete';
  static const String donationSuccess = '/donationSuccess';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case product:
        return MaterialPageRoute(builder: (_) => ProductPage());
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case discover:
        return MaterialPageRoute(builder: (_) => DiscoverPage());
      case settingspage:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case donations:
        return MaterialPageRoute(builder: (_) => DonationPage());
      case checkout:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CheckoutPage(),
        );
      case checkoutComplete:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const CheckoutCompletePage(),
        );
      case donationSuccess:
        return MaterialPageRoute(builder: (_) => const SuccessfulUploadPage());
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
