import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/categories/widget/category_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CategoryErrorWidget displays content and triggers retry',
      (WidgetTester tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryErrorWidget(
          errorMessage: 'Network timeout',
          onRetry: () {
            retried = true;
          },
        ),
      ),
    );

    expect(find.text(AppStrings.failedToLoadCategories), findsOneWidget);
    expect(find.text('Network timeout'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();

    expect(retried, isTrue);
  });
}
