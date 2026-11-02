import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/theme/theme_notifier.dart';
import 'package:cherry_mvp/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.text(AppStrings.communityRulesText), findsOneWidget);

    MethodCall? launch;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      launch = call;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.tap(find.text(AppStrings.privacyPolicyText));
    await tester.pumpAndSettle();
    expect(launch?.method, 'launch');
    expect(launch?.arguments['url'], 'https://cherry.org.uk/privacypolicy');
    expect(launch?.arguments['useSafariVC'], false);
    expect(launch?.arguments['useWebView'], false);

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

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.communityRulesText));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text(AppStrings.communityRulesText), findsWidgets);
    expect(find.text('Date last updated: 19.09.2026'), findsOneWidget);
    expect(find.text('1. Acceptance and scope'), findsOneWidget);
  });
}
