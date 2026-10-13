import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Navigator extends NavigationProvider {
  String? route;
  @override
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) async {
    route = routeName;
  }
}

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('banner fits width $width at text scale $scale and opens Discovery', (tester) async {
        final font = FontLoader('InstrumentSansPricing')
          ..addFont(rootBundle.load('assets/fonts/InstrumentSans-Bold.ttf'));
        await font.load();
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final navigator = _Navigator();
        await tester.pumpWidget(
          Provider<NavigationProvider>.value(
            value: navigator,
            child: MaterialApp(
              theme: buildTheme(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(padding: EdgeInsets.all(16), child: DiscoverButton()),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final banner = tester.getRect(find.byType(DiscoverButton));
        for (final label in [AppStrings.exploreText, AppStrings.discoverSomethingText]) {
          final text = tester.getRect(find.text(label));
          expect(text.left, greaterThanOrEqualTo(banner.left));
          expect(text.right, lessThanOrEqualTo(banner.right));
          expect(text.bottom, lessThanOrEqualTo(banner.bottom));
        }
        await tester.tap(find.byType(DiscoverButton));
        expect(navigator.route, AppRoutes.discover);
      });
    }
  }
}
