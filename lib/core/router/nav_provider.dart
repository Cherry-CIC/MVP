import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
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

  /// Opens [CharityProfilePage] for a loaded [Charity].
  Future<void> openCharityProfile(Charity charity) {
    return openCharityProfileByDetails(
      CharityProfileArgs(
        charity: charity,
        charityId: charity.id,
        charityName: charity.name,
        charityImageUrl: charity.imageUrl,
      ),
    );
  }

  /// Opens [CharityProfilePage] from partial charity metadata (e.g. product cards).
  Future<void> openCharityProfileByDetails(CharityProfileArgs args) async {
    final validated = CharityProfileArgs.fromRouteArgument(args);
    if (validated == null) return;
    await navigateTo(AppRoutes.charityProfile, arguments: validated);
  }

  /// Opens [CharityProfilePage] using [NavigationProvider] when mounted, or falls
  /// back to the nearest [Navigator] for standalone widget trees and tests.
  static Future<void> openCharityProfileFromContext(
    BuildContext context,
    CharityProfileArgs args,
  ) async {
    final validated = CharityProfileArgs.fromRouteArgument(args);
    if (validated == null) return;
    NavigationProvider? navigator;
    try {
      navigator = Provider.of<NavigationProvider>(context, listen: false);
    } on ProviderNotFoundException {
      navigator = null;
    }
    if (navigator != null && navigator.navigatorKey.currentState != null) {
      await navigator.openCharityProfileByDetails(validated);
    } else if (context.mounted) {
      await Navigator.of(context).pushNamed(
        AppRoutes.charityProfile,
        arguments: validated,
      );
    }
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
