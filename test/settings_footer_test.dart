import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/app_info_provider.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

void main() {
  group('AppStrings.formatAppVersion', () {
    test('formats version and distinct build number', () {
      expect(
        AppStrings.formatAppVersion('0.1.1', '9'),
        'Version 0.1.1 (Build 9)',
      );
    });

    test('formats version alone when build number is empty', () {
      expect(
        AppStrings.formatAppVersion('0.1.1', ''),
        'Version 0.1.1',
      );
    });

    test('formats version alone when build number matches version', () {
      expect(
        AppStrings.formatAppVersion('0.1.1', '0.1.1'),
        'Version 0.1.1',
      );
    });

    test('returns empty string when version is empty', () {
      expect(AppStrings.formatAppVersion('   ', '9'), '');
    });
  });

  group('SettingsFooter', () {
    testWidgets('displays dynamic version and build from PackageInfo', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'Cherry',
        packageName: 'com.cherry.mvp',
        version: '0.1.1',
        buildNumber: '9',
        buildSignature: '',
      );

      final appInfoProvider = AppInfoProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppInfoProvider>.value(
          value: appInfoProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SettingsFooter(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text('Version 0.1.1 (Build 9)'), findsOneWidget);
    });

    testWidgets('omits version subtitle when packageInfoLoader fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SettingsFooter(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.textContaining('Version'), findsNothing);
    });
  });
}
