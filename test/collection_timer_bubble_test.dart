import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_timer_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpTimer(
  WidgetTester tester, {
  required DateTime deadline,
  required DateTime Function() now,
  VoidCallback? onTap,
  VoidCallback? onExpired,
  DeliveryTimerPurpose purpose = DeliveryTimerPurpose.collection,
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildTheme(brightness),
    home: Scaffold(
      floatingActionButton: DeliveryTimerBubble(
        deadline: deadline,
        now: now,
        purpose: purpose,
        onTap: onTap ?? () {},
        onExpired: onExpired ?? () {},
      ),
      bottomNavigationBar: const SizedBox(height: 56),
    ),
  ),
);

void main() {
  final start = DateTime.utc(2026, 11, 12, 10);

  for (final brightness in Brightness.values) {
    testWidgets('$brightness collection timer has an accessible label, target and contrast', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        var taps = 0;
        await _pumpTimer(
          tester,
          deadline: start.add(const Duration(hours: 23, minutes: 59, seconds: 11)),
          now: () => start,
          brightness: brightness,
          onTap: () => taps++,
        );
        expect(find.text('23:59:11'), findsOneWidget);
        expect(find.text('left to collect'), findsOneWidget);
        expect(find.text('left to confirm'), findsNothing);
        final semantics = tester
            .getSemantics(find.bySemanticsLabel('Collection reminder, 23 hours and 59 minutes left to collect'))
            .getSemanticsData();
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(semantics.hint, 'Open collection details');
        expect(semantics.flagsCollection.isLiveRegion, isFalse);
        final size = tester.getSize(find.byType(DeliveryTimerBubble));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.tap(find.text('left to collect'));
        expect(taps, 1);
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('collection timer fits a 320-pixel screen at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var taps = 0;
    await _pumpTimer(
      tester,
      deadline: start.add(const Duration(hours: 72)),
      now: () => start,
      onTap: () => taps++,
    );
    expect(find.text('72:00:00'), findsOneWidget);
    expect(find.text('left to collect'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final bounds = tester.getRect(find.byType(DeliveryTimerBubble));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    expect(bounds.bottom, lessThan(568 - 56));
    await tester.tap(find.text('72:00:00'));
    expect(taps, 1);
  });

  testWidgets('expiry hides once and rejects a tap between the final ticks', (tester) async {
    var now = start;
    var taps = 0;
    var expiries = 0;
    final deadline = start.add(const Duration(seconds: 2));
    await _pumpTimer(
      tester,
      deadline: deadline,
      now: () => now,
      onTap: () => taps++,
      onExpired: () => expiries++,
    );
    expect(find.text('00:00:02'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:01'), findsOneWidget);
    now = deadline;
    await tester.tap(find.text('00:00:01'));
    expect(taps, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('left to collect'), findsNothing);
    expect(expiries, 1);
    await tester.pump(const Duration(minutes: 2));
    expect(expiries, 1);
  });

  testWidgets('an already expired timer stays hidden and reports expiry once', (tester) async {
    var expiries = 0;
    await _pumpTimer(
      tester,
      deadline: start.subtract(const Duration(seconds: 1)),
      now: () => start,
      onExpired: () => expiries++,
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('left to collect'), findsNothing);
    expect(expiries, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(expiries, 1);
  });

  testWidgets('switching parcel deadlines retains the supplied time and cancels the old expiry', (tester) async {
    var now = start;
    var expiries = 0;
    await _pumpTimer(
      tester,
      deadline: start.add(const Duration(seconds: 1)),
      now: () => now,
      onExpired: () => expiries++,
    );
    final state = tester.state(find.byType(DeliveryTimerBubble));
    await _pumpTimer(
      tester,
      deadline: start.add(const Duration(hours: 5)),
      now: () => now,
      onExpired: () => expiries++,
    );
    expect(tester.state(find.byType(DeliveryTimerBubble)), same(state));
    expect(find.text('05:00:00'), findsOneWidget);
    now = start.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('04:59:59'), findsOneWidget);
    expect(expiries, 0);
  });

  testWidgets('omitting a purpose preserves the confirmation timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          floatingActionButton: DeliveryTimerBubble(
            deadline: start.add(const Duration(hours: 12)),
            now: () => start,
            onTap: () {},
            onExpired: () {},
          ),
        ),
      ),
    );
    expect(find.text('12:00:00'), findsOneWidget);
    expect(find.text('left to confirm'), findsOneWidget);
    expect(find.text('left to collect'), findsNothing);
  });
}
