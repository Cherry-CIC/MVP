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

  testWidgets('expands Contact dropdown under Support and opens contact URL', (
    tester,
  ) async {
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

    expect(find.text(AppStrings.supportText), findsOneWidget);
    expect(find.text(AppStrings.contactText), findsOneWidget);
    expect(find.text(AppStrings.contactUrl), findsNothing);

    await tester.tap(find.text(AppStrings.contactText));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.contactUrl), findsOneWidget);

    MethodCall? launch;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      launch = call;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.tap(find.text(AppStrings.contactUrl));
    await tester.pumpAndSettle();

    expect(launch?.method, 'launch');
    expect(launch?.arguments['url'], 'https://cherry.org.uk/contact');
    expect(launch?.arguments['useSafariVC'], false);
    expect(launch?.arguments['useWebView'], false);
  });

  testWidgets('shows fallback snackbar when launching contact URL fails', (
    tester,
  ) async {
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

    await tester.tap(find.text(AppStrings.contactText));
    await tester.pumpAndSettle();

    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      return false;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.tap(find.text(AppStrings.contactUrl));
    await tester.pumpAndSettle();

    expect(
      find.text('Please open https://cherry.org.uk/contact in your browser.'),
      findsOneWidget,
    );
  });
}
