import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/orders/collection_deadline.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/ready_to_collect_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _order = OrderSummary(
  id: 'CH123456',
  productId: 'shirt',
  productName: 'Beige cargo shirt',
  imageUrl: '',
  size: 'L',
  condition: 'Barely worn',
  charityLogoUrl: '',
  itemPriceMinor: 800,
  totalAmountMinor: 880,
  currency: 'GBP',
  deliveryState: 'awaiting_collection',
  deliveryLabel: 'Ready to collect',
);

Future<void> _open(
  WidgetTester tester, {
  required DateTime deadline,
  required DateTime Function() now,
  bool map = false,
  bool tracking = false,
  OrderSummary order = _order,
  Brightness brightness = Brightness.light,
  List<ReadyToCollectAction?>? results,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final action = await showDialog<ReadyToCollectAction>(
                context: context,
                builder: (_) => ReadyToCollectDialog(
                  order: order,
                  collectionDeadline: deadline,
                  now: now,
                  canOpenMap: map,
                  canTrackParcel: tracking,
                ),
              );
              results?.add(action);
            },
            child: const Text('Preview'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Preview'));
  await tester.pumpAndSettle();
}

Finder _countdown(String value) => find.text('Time left: $value', findRichText: true);

void main() {
  final arrival = DateTime.utc(2026, 11, 6, 12);
  final deadline = collectionDeadlineFromArrival(arrival);

  test('deadline uses 72 elapsed hours from the recorded arrival and normalises offsets', () {
    final offsetArrival = DateTime.parse('2026-10-24T12:00:00+01:00');
    final result = collectionDeadlineFromArrival(offsetArrival);
    expect(result, DateTime.utc(2026, 10, 27, 11));
    expect(result.isUtc, isTrue);
    expect(result.difference(offsetArrival), const Duration(hours: 72));
  });

  testWidgets('dismissal and reopening retain the absolute deadline', (tester) async {
    var now = arrival;
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => now, map: true, results: results);
    expect(find.text('Ready to collect'), findsOneWidget);
    expect(find.text('Beige cargo shirt'), findsOneWidget);
    expect(find.text('£8.00'), findsOneWidget);
    expect(find.text('Collected'), findsNothing);
    expect(_countdown('72:00:00'), findsOneWidget);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(results, [ReadyToCollectAction.dismiss]);
    now = arrival.add(const Duration(hours: 5, minutes: 2));
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(_countdown('66:58:00'), findsOneWidget);
    expect(tester.widget<ReadyToCollectDialog>(find.byType(ReadyToCollectDialog)).collectionDeadline, deadline);
  });

  testWidgets('map action is returned without confirming or opening another dialog', (tester) async {
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => arrival, map: true, tracking: true, results: results);
    expect(find.text('Track parcel'), findsNothing);
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(results, [ReadyToCollectAction.openMap]);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
  });

  testWidgets('tracking is the fallback when no map destination is available', (tester) async {
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => arrival, tracking: true, results: results);
    expect(find.text('Open map'), findsNothing);
    await tester.tap(find.text('Track parcel'));
    await tester.pumpAndSettle();
    expect(results, [ReadyToCollectAction.trackParcel]);
  });

  testWidgets('missing destinations leave an explicit working dismissal', (tester) async {
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => arrival, results: results);
    expect(find.text('Open map'), findsNothing);
    expect(find.text('Track parcel'), findsNothing);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(results, [ReadyToCollectAction.dismiss]);
  });

  for (final elapsed in [Duration.zero, const Duration(hours: 1)]) {
    testWidgets('deadline reached plus $elapsed shows neutral expiry and tracking', (tester) async {
      final results = <ReadyToCollectAction?>[];
      await _open(
        tester,
        deadline: deadline,
        now: () => deadline.add(elapsed),
        map: true,
        tracking: true,
        results: results,
      );
      expect(find.text('Collection window ended'), findsOneWidget);
      expect(find.text('Open map'), findsNothing);
      expect(find.textContaining('Time left:', findRichText: true), findsNothing);
      expect(find.textContaining('returned'), findsNothing);
      expect(find.textContaining('forgot'), findsNothing);
      expect(find.text('Track parcel'), findsOneWidget);
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();
      expect(results, [ReadyToCollectAction.dismiss]);
    });
  }

  testWidgets('ticker changes to expiry without closing the dialog or restarting', (tester) async {
    var now = deadline.subtract(const Duration(seconds: 1));
    await _open(tester, deadline: deadline, now: () => now, map: true);
    expect(_countdown('00:00:01'), findsOneWidget);
    now = deadline;
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Collection window ended'), findsOneWidget);
    expect(find.text('Open map'), findsNothing);
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
  });

  testWidgets('resume rechecks wall-clock expiry immediately', (tester) async {
    var now = arrival;
    await _open(tester, deadline: deadline, now: () => now, map: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = deadline.add(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Collection window ended'), findsOneWidget);
    expect(find.text('Open map'), findsNothing);
  });

  testWidgets('a map tap at expiry is rejected between timer ticks', (tester) async {
    var now = deadline.subtract(const Duration(seconds: 1));
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => now, map: true, results: results);
    now = deadline;
    await tester.tap(find.text('Open map'));
    await tester.pump();
    expect(results, isEmpty);
    expect(find.text('Collection window ended'), findsOneWidget);
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
  });

  testWidgets('barrier and back dismiss without invoking a collection action', (tester) async {
    final results = <ReadyToCollectAction?>[];
    await _open(tester, deadline: deadline, now: () => arrival, results: results);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(results, [null]);
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(results, [null, null]);
  });

  testWidgets('narrow screen and large text scroll long details without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(
      tester,
      deadline: deadline,
      now: () => arrival,
      map: true,
      order: _order.copyWith(
        productName: 'A very long descriptive name for a pre-loved linen cargo shirt',
        size: 'Extra large',
        condition: 'Good condition with minor signs of wear',
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('$brightness exposes labelled 48px controls and a quiet spoken countdown', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, deadline: deadline, now: () => arrival, map: true, brightness: brightness);
        final countdown = tester.getSemantics(find.bySemanticsLabel('72 hours left to collect')).getSemanticsData();
        expect(countdown.flagsCollection.isLiveRegion, isFalse);
        for (final label in ['Open map', 'Not yet']) {
          final button = find.widgetWithText(FilledButton, label);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          final semantics = tester.getSemantics(button).getSemanticsData();
          expect(semantics.hasAction(SemanticsAction.tap), isTrue);
          expect(semantics.label, contains(label));
        }
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        handle.dispose();
      }
    });
  }
}
