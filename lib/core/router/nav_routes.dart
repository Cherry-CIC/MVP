import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/register/registerpage.dart';
import 'package:cherry_mvp/features/home/homepage.dart';
import 'package:cherry_mvp/features/login/loginpage.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/home/widgets/chat_page.dart'; // <- import ChatPage

class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgotPassword';
  static const String home = '/home';
  static const String chat = '/chat'; // <- added chat route

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case chat:
        return MaterialPageRoute(builder: (_) => ChatPage(showAppBar: true)); // <- route added
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