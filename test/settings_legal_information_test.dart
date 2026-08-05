import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';
import 'package:cherry_mvp/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens legal documents from Legal information', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final navigator = NavigationProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<ThemeNotifier>(
            create: (_) => ThemeNotifier(preferences),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          onGenerateRoute: AppRoutes.generateRoute,
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(AppStrings.legalInformationText),
      500,
    );
    await tester.tap(find.text(AppStrings.legalInformationText));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.privacyPolicyText), findsOneWidget);
    expect(find.text(AppStrings.termsAndConditionsText), findsOneWidget);

    await tester.tap(find.text(AppStrings.privacyPolicyText));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text(AppStrings.privacyPolicyText), findsWidgets);
    expect(find.text('Date last updated: 05.07.2026'), findsOneWidget);
    expect(find.text('1. General'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.termsAndConditionsText));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text(AppStrings.termsAndConditionsText), findsWidgets);
    expect(
      find.text("Welcome to cherry! Let's Cover the Basics..."),
      findsOneWidget,
    );
    expect(find.text('1. About You and Us'), findsOneWidget);
  });
}
