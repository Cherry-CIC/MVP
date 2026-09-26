import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';

class NavigationProvider {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  static String? publicProfileUserId(String? userId) {
    final value = userId?.trim();
    if (value == null ||
        value.isEmpty ||
        value == '.' ||
        value == '..' ||
        value == 'deleted_user' ||
        RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(value)) {
      return null;
    }
    return value;
  }

  /// The shared entry point for seller and other public user links.
  Future<void> openPublicUserProfile(String? userId) async {
    final validatedId = publicProfileUserId(userId);
    if (validatedId == null) return;
    await navigateTo(AppRoutes.publicUserProfile, arguments: validatedId);
  }

  Future<dynamic> replaceWith(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToAndRemoveUntil(String routeName, RoutePredicate predicate, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);
  }

  void goBack([Object? arguments]) {
    navigatorKey.currentState!.pop(arguments);
  }

  Future<void> showPurchaseSecurity() async {
    await navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) => const PurchaseSecurity(),
        fullscreenDialog: true,
      ),
    );
  }
}
