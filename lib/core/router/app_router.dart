import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:cherry_mvp/features/addproduct/addproductpage.dart';
import 'package:cherry_mvp/features/home/homepage.dart';
import 'package:cherry_mvp/features/home/widgets/home_screen.dart';
import 'package:cherry_mvp/features/login/loginpage.dart';
import 'package:cherry_mvp/features/messages/messagepage.dart';
import 'package:cherry_mvp/features/profile/profilepage.dart';
import 'package:cherry_mvp/features/register/registerpage.dart';
import 'package:cherry_mvp/features/search/searchpage.dart';
import 'package:cherry_mvp/features/settings/settings_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(navigatorKey: _rootNavigatorKey, routes: [
  GoRoute(path: '/welcome', builder: (context, state) => WelcomePage()),
  GoRoute(path: '/login', builder: (context, state) => LoginPage()),
  GoRoute(path: '/register', builder: (context, state) => RegisterPage()),
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) => HomePage(child: child),
    routes: [
      GoRoute(
          path: '/',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => HomeScreen()),
      GoRoute(
          path: '/search',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => SearchPage()),
      GoRoute(
          path: '/add-product',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => AddProductPage()),
      GoRoute(
          path: '/messages',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => MessagePage()),
      GoRoute(
          path: '/profile',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => ProfilePage(),
          routes: [
            GoRoute(
                path: 'settings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => SettingsPage())
          ]),
    ],
    redirect: (context, state) async {
      if (context.read<FirebaseAuthService>().currentUser != null) {
        return null;
      }

      return '/welcome';
    },
  )
]);
