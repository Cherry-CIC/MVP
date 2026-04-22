import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/checkout/purchase_security.dart';

class NavigationProvider {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
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
