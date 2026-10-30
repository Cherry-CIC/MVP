import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/products/widgets/product_safety_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Done hides the keyboard and preserves the draft at text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final results = <ReportDraft?>[];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  results.add(await showReportProductSheet(context, title: AppStrings.productPageReportSellerTitle));
                },
                child: const Text('Open report'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Harassment or abuse'));
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'First paragraph\nMore details');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Done').hitTestable(), findsOneWidget);
      expect(find.text(AppStrings.productPageReportSubmit).hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(find.text('Done')).dy, lessThan(367));
      expect(tester.getBottomRight(find.text(AppStrings.productPageReportSubmit)).dy, lessThan(367));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(results, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'First paragraph\nMore details');
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
      await tester.tap(find.text(AppStrings.productPageReportSubmit));
      await tester.pumpAndSettle();
      expect(results.single!.reason, 'harassment_or_abuse');
      expect(results.single!.message, 'First paragraph\nMore details');
    });
  }
}
