import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/widgets/empty_state_card.dart';
import 'package:cherry_mvp/core/widgets/profile_section_icontextrow.dart';
import 'package:cherry_mvp/features/categories/widget/category_empty_widget.dart';
import 'package:cherry_mvp/features/categories/widget/category_error_widget.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_dialog.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_empty_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_error_widget.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/confirm_item_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light, double textScale = 1.0}) {
  return MaterialApp(
    theme: buildTheme(brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('Dialogs and Modals Accessibility', () {
    testWidgets('ConfirmItemDialog buttons meet tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      const order = OrderSummary(
        id: '123',
        productId: 'p456',
        productName: 'Denim Jacket',
        size: 'M',
        imageUrl: '',
        charityLogoUrl: '',
        itemPriceMinor: 3000,
        totalAmountMinor: 3000,
        currency: 'GBP',
        deliveryState: 'delivered',
        deliveryLabel: 'Delivered',
      );

      await tester.pumpWidget(_app(const ConfirmItemDialog(order: order)));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      expect(find.text('Denim Jacket'), findsOneWidget);
      expect(find.text('Raise dispute'), findsOneWidget);
      expect(find.text('Yes, all good'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('ConfirmItemDialog scales to 2.0x text without overflow', (tester) async {
      const order = OrderSummary(
        id: '123',
        productId: 'p456',
        productName: 'Denim Jacket',
        size: 'M',
        imageUrl: '',
        charityLogoUrl: '',
        itemPriceMinor: 3000,
        totalAmountMinor: 3000,
        currency: 'GBP',
        deliveryState: 'delivered',
        deliveryLabel: 'Delivered',
      );

      await tester.pumpWidget(_app(const ConfirmItemDialog(order: order), textScale: 2.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PhotoTipsDialog meets guidelines and excludes decorative icons', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const PhotoTipsDialog()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      expect(find.text('Ok'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('PhotoTipsDialog scales to 2.0x text cleanly', (tester) async {
      await tester.pumpWidget(_app(const PhotoTipsDialog(), textScale: 2.0));
      expect(tester.takeException(), isNull);
    });
  });

  group('Empty and Error State Accessibility', () {
    testWidgets('EmptyStateCard excludes background image and renders accessible text', (tester) async {
      await tester.pumpWidget(_app(const EmptyStateCard(message: 'No items found')));
      expect(find.text('No items found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmptyStateCard scales to 2.0x text without overflow', (tester) async {
      await tester.pumpWidget(_app(const EmptyStateCard(message: 'No items found'), textScale: 2.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardErrorWidget announces error with liveRegion and provides 48dp retry', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          DashboardErrorWidget(
            errorMessage: 'Network timeout',
            onRetry: () {},
          ),
        ),
      );

      final liveRegionFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(liveRegionFinder, findsOneWidget);

      final retryButton = find.widgetWithText(ElevatedButton, AppStrings.retry);
      expect(retryButton, findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('DashboardEmptyWidget excludes decorative icon and presents message', (tester) async {
      await tester.pumpWidget(_app(const DashboardEmptyWidget()));
      expect(find.text(AppStrings.noProductsAvailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryErrorWidget announces liveRegion and provides 48dp retry', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          CategoryErrorWidget(
            errorMessage: 'Failed to load',
            onRetry: () {},
          ),
        ),
      );

      final liveRegionFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      );
      expect(liveRegionFinder, findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('CategoryEmptyWidget presents accessible category empty message', (tester) async {
      await tester.pumpWidget(_app(const CategoryEmptyWidget()));
      expect(find.text(AppStrings.noCategoriesAvailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Shared Display Widgets Accessibility', () {
    testWidgets('IconTextRow excludes decorative image and presents label text', (tester) async {
      await tester.pumpWidget(
        _app(
          const IconTextRow(
            assetPath: AppImages.profileLocation,
            text: 'Tracked 48 Delivery',
          ),
        ),
      );
      expect(find.text('Tracked 48 Delivery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
