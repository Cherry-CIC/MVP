import 'package:cherry_mvp/features/notifications/collection_notification_inbox.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_dialog.dart';
import 'package:cherry_mvp/features/orders/widgets/ready_to_collect_dialog.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_host.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_timer_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends Fake implements IOrdersRepository {
  List<OrderSummary> orders = [];
  int fetchCount = 0;
  bool failFetch = false;
  String? confirmed;
  String? disputed;

  @override
  Future<Result<List<OrderSummary>>> fetchOrders({bool deliveryRemindersOnly = false}) async {
    fetchCount++;
    if (failFetch) return Result.failure('Offline');
    expect(deliveryRemindersOnly, isTrue);
    return Result.success(orders);
  }

  @override
  Future<Result<dynamic>> confirmOrderReceived(String orderId) async {
    confirmed = orderId;
    return Result.success(null);
  }

  @override
  Future<Result<dynamic>> submitOrderDispute(String orderId, {required String reason, String? message}) async {
    disputed = orderId;
    return Result.success(null);
  }
}

OrderSummary order(String id, {int? hours = 12, String state = 'awaiting_confirmation'}) =>
    OrderSummary.tryFromOrderJson({
      'id': id,
      'productName': 'Item ${id.toUpperCase()}',
      'deliveryState': state,
      'collectedAt': DateTime.now().toUtc().subtract(const Duration(hours: 36)).toIso8601String(),
      if (hours != null) 'confirmationDeadline': DateTime.now().toUtc().add(Duration(hours: hours)).toIso8601String(),
    })!.copyWith(size: 'L');

Future<void> _open(
  WidgetTester tester,
  _Repository repo, {
  String userId = 'buyer',
  CollectionNotificationInbox? notifications,
  DateTime Function() now = DateTime.now,
  Future<bool> Function(Uri)? openLink,
}) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<IOrdersRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => OrdersViewModel(repository: repo)),
      ],
      child: MaterialApp(
        home: DeliveryReminderHost(
          key: ValueKey(userId),
          userId: userId,
          notifications: notifications,
          now: now,
          openLink: openLink,
          builder: (_, timer) => Scaffold(body: const Text('Home'), floatingActionButton: timer),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void background(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

Future<void> resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

Finder get timerBubble => find.byKey(const ValueKey('delivery-timer-bubble'));

Future<void> dismissReminder(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
  expect(find.byType(DeliveryReminderDialog), findsNothing);
}

Future<void> reopenReminder(WidgetTester tester) async {
  await tester.tap(timerBubble);
  await tester.pumpAndSettle();
  expect(find.byType(DeliveryReminderDialog), findsOneWidget);
}

OrderSummary collectionOrder({String state = 'awaiting_collection', int hours = 72, bool map = true}) =>
    OrderSummary.tryFromOrderJson({
      'id': 'collection',
      'productName': 'Collection shirt',
      'deliveryState': state,
      'readyForCollectionAt': DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String(),
      'collectionDeadline': DateTime.now().toUtc().add(Duration(hours: hours)).toIso8601String(),
      'trackingUrl': 'https://tracking.inpost.co.uk/parcel',
      if (map)
        'collectionPoint': {
          'name': 'InPost locker',
          'addressLine1': '1 High Street',
          'city': 'London',
          'postalCode': 'SW1A 1AA',
          'country': 'GB',
        },
    })!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('notification tap refreshes and reopens the correct dismissed collection', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final inbox = CollectionNotificationInbox()..setUser('buyer');
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo, notifications: inbox);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    final before = repo.fetchCount;
    inbox.receive({
      'type': 'ready_to_collect',
      'userId': 'buyer',
      'orderId': 'collection',
      'eventId': 'one',
    }, opened: true);
    await tester.pumpAndSettle();
    expect(repo.fetchCount, greaterThan(before));
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
    expect(inbox.pendingFor('buyer'), isNull);
    await tester.pumpWidget(const SizedBox());
    inbox.dispose();
  });

  testWidgets('old collection notification opens confirmation after collection', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready', 'collection'],
    });
    final inbox = CollectionNotificationInbox()..setUser('buyer');
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo, notifications: inbox);
    repo.orders = [order('collection', hours: 47)];
    inbox.receive({
      'type': 'ready_to_collect',
      'userId': 'buyer',
      'orderId': 'collection',
      'eventId': 'one',
    }, opened: true);
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    inbox.dispose();
  });

  testWidgets('notification for returned parcel cannot reopen a stale reminder', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final inbox = CollectionNotificationInbox()..setUser('buyer');
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo, notifications: inbox);
    repo.orders = [collectionOrder(state: 'returned')];
    inbox.receive({
      'type': 'ready_to_collect',
      'userId': 'buyer',
      'orderId': 'collection',
      'eventId': 'one',
    }, opened: true);
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(timerBubble, findsNothing);
    expect(inbox.pendingFor('buyer'), isNull);
    await tester.pumpWidget(const SizedBox());
    inbox.dispose();
  });

  testWidgets('notification tap replaces another open reminder without overlapping', (tester) async {
    final inbox = CollectionNotificationInbox()..setUser('buyer');
    final repo = _Repository()..orders = [order('another', hours: 1), collectionOrder()];
    await _open(tester, repo, notifications: inbox);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
    inbox.receive({
      'type': 'ready_to_collect',
      'userId': 'buyer',
      'orderId': 'collection',
      'eventId': 'one',
    }, opened: true);
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
    inbox.dispose();
  });

  testWidgets('failed notification refresh waits for fresh data before opening', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final inbox = CollectionNotificationInbox()..setUser('buyer');
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo, notifications: inbox);
    repo.failFetch = true;
    inbox.receive({
      'type': 'ready_to_collect',
      'userId': 'buyer',
      'orderId': 'collection',
      'eventId': 'one',
    }, opened: true);
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(inbox.pendingFor('buyer'), isNotNull);
    background(tester);
    repo.failFetch = false;
    await resume(tester);
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    inbox.dispose();
  });

  testWidgets('locker arrival never starts a timer and customer collection does', (tester) async {
    final arrival = OrderSummary.tryFromOrderJson({
      'id': 'a',
      'productName': 'Item A',
      'deliveryState': 'awaiting_collection',
      'lockerDeliveredAt': DateTime.now().toUtc().toIso8601String(),
      'confirmationDeadline': DateTime.now().add(const Duration(hours: 48)).toUtc().toIso8601String(),
    })!;
    final repo = _Repository()..orders = [arrival];
    await _open(tester, repo);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    expect(timerBubble, findsNothing);

    // An older API may still supply an arrival-based deadline.
    background(tester);
    repo.orders = [arrival.copyWith(deliveryState: 'awaiting_confirmation')];
    await resume(tester);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    expect(timerBubble, findsNothing);

    background(tester);
    repo.orders = [order('a', hours: 48, state: 'collected')];
    await resume(tester);
    expect(find.text('Your item has been collected'), findsOneWidget);
    expect(find.text('The 48 hours started when you collected your parcel.'), findsOneWidget);
    await dismissReminder(tester);
    expect(timerBubble, findsOneWidget);
    await reopenReminder(tester);
    expect(find.text('Item A'), findsOneWidget);
  });

  testWidgets('cold start uses earliest active deadline and outside dismissal survives reopening', (tester) async {
    final first = order('first');
    final repo = _Repository()
      ..orders = [
        order('old', hours: -1),
        order('unknown', hours: null),
        order('confirmed', state: 'confirmed'),
        order('disputed', state: 'disputed'),
        order('later', hours: 24),
        first,
      ];
    await _open(tester, repo);
    expect(find.text('Item FIRST'), findsOneWidget);
    final countdown = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan?.toPlainText().contains('left to check') == true,
      ),
    );
    expect(countdown.textSpan!.toPlainText(includeSemanticsLabels: false), matches(RegExp(r'^(12:00:00|11:59:\d{2})')));
    await dismissReminder(tester);
    expect(timerBubble, findsOneWidget);
    expect(repo.confirmed, isNull);
    await reopenReminder(tester);
    final reopened = tester.widget<DeliveryReminderDialog>(find.byType(DeliveryReminderDialog));
    expect(reopened.order.id, first.id);
    expect(reopened.order.confirmationDeadline, first.confirmationDeadline);
    await dismissReminder(tester);

    repo.orders = [first];
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, repo);
    expect(find.text('Your item has been collected'), findsNothing);
    expect(timerBubble, findsOneWidget);
    await reopenReminder(tester);
    expect(find.text('Item FIRST'), findsOneWidget);
    await dismissReminder(tester);

    await _open(tester, repo, userId: 'another-buyer');
    expect(find.text('Your item has been collected'), findsOneWidget);
  });

  testWidgets('delivery while away appears on resume and View item requires explicit confirmation', (tester) async {
    final repo = _Repository();
    await _open(tester, repo);
    expect(find.text('Your item has been collected'), findsNothing);
    background(tester);
    repo.orders = [order('delivered')];
    await resume(tester);
    await tester.tap(find.text('View item'));
    await tester.pumpAndSettle();
    expect(repo.confirmed, isNull);
    expect(find.text('Item DELIVERED'), findsOneWidget);
    await tester.tap(find.text('Yes, all good'));
    await tester.pumpAndSettle();
    expect(repo.confirmed, 'delivered');
    expect(timerBubble, findsNothing);
  });

  testWidgets('a reminder open in the background is revalidated when the buyer returns', (tester) async {
    final repo = _Repository()..orders = [order('a')];
    await _open(tester, repo);
    expect(find.text('Your item has been collected'), findsOneWidget);
    background(tester);
    repo.orders = [order('a', hours: -1)];
    await resume(tester);
    expect(find.text('Your item has been collected'), findsNothing);
  });

  testWidgets('cancelling the receipt action keeps the timer available', (tester) async {
    final repo = _Repository()..orders = [order('a')];
    await _open(tester, repo);
    await dismissReminder(tester);
    await reopenReminder(tester);
    await tester.tap(find.text('View item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.confirmed, isNull);
    await reopenReminder(tester);
    expect(find.text('Item A'), findsOneWidget);
  });

  testWidgets('on resume a dismissed timer follows the earliest remaining eligible order', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['first', 'next'],
    });
    final next = order('next', hours: 24);
    final repo = _Repository()..orders = [next, order('first')];
    await _open(tester, repo);
    await reopenReminder(tester);
    expect(find.text('Item FIRST'), findsOneWidget);
    await dismissReminder(tester);

    background(tester);
    repo.orders = [next, order('first', hours: -1)];
    await resume(tester);
    await reopenReminder(tester);
    expect(find.text('Item NEXT'), findsOneWidget);
    await dismissReminder(tester);

    background(tester);
    repo.orders = [order('next', state: 'confirmed')];
    await resume(tester);
    expect(timerBubble, findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
  });

  testWidgets('corner timer ticks down, exposes a tap action at large text sizes and expires once', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    var now = DateTime.utc(2026, 11, 1, 12);
    final deadline = now.add(const Duration(seconds: 3));
    var expires = 0;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: DeliveryTimerBubble(
            deadline: deadline,
            now: () => now,
            onTap: () => taps++,
            onExpired: () => expires++,
          ),
        ),
      ),
    );
    expect(find.text('00:00:03'), findsOneWidget);
    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.label.contains('left to confirm') && data.hasAction(SemanticsAction.tap);
      }),
      findsOne,
    );
    expect(tester.getSize(find.byType(DeliveryTimerBubble)).height, greaterThanOrEqualTo(48));

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:02'), findsOneWidget);
    await tester.tap(find.text('00:00:02'));
    expect(taps, 1);
    now = deadline;
    await tester.tap(find.text('00:00:02'));
    expect(taps, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('left to confirm'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(expires, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('problem action opens the dispute form for the displayed order', (tester) async {
    final repo = _Repository()..orders = [order('a')];
    await _open(tester, repo);
    await tester.tap(find.text('Something’s not right'));
    await tester.pumpAndSettle();
    expect(find.text('Raise dispute'), findsOneWidget);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(repo.disputed, 'a');
    expect(timerBubble, findsNothing);
    expect(repo.confirmed, isNull);
  });
  testWidgets('collection dismissal survives relaunch without hiding the later confirmation stage', (tester) async {
    final ready = collectionOrder();
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo);
    expect(find.text('Ready to collect'), findsOneWidget);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    expect(
      tester.widget<ReadyToCollectDialog>(find.byType(ReadyToCollectDialog)).collectionDeadline,
      ready.collectionDeadline,
    );
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, repo);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    background(tester);
    repo.orders = [order('collection')];
    await resume(tester);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
  });

  testWidgets('an open collection dialog hands over on foreground refresh', (tester) async {
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo);
    repo.orders = [order('collection')];
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
  });

  for (final state in ['returned', 'returning', 'cancelled', 'failed', 'confirmed']) {
    testWidgets('$state clears an open collection dialog on resume', (tester) async {
      final repo = _Repository()..orders = [collectionOrder()];
      await _open(tester, repo);
      background(tester);
      repo.orders = [collectionOrder(state: state)];
      await resume(tester);
      expect(find.byType(ReadyToCollectDialog), findsNothing);
      expect(find.byType(DeliveryReminderDialog), findsNothing);
      expect(timerBubble, findsNothing);
    });
  }

  testWidgets('expiry has its own dismissal and does not claim a return', (tester) async {
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    background(tester);
    repo.orders = [collectionOrder(hours: -1)];
    await resume(tester);
    expect(find.text('Collection window ended'), findsOneWidget);
    expect(find.textContaining('returned'), findsNothing);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    background(tester);
    await resume(tester);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
  });

  testWidgets('map and tracking use API destinations without confirming receipt', (tester) async {
    final repo = _Repository()..orders = [collectionOrder()];
    final opened = <Uri>[];
    await _open(
      tester,
      repo,
      openLink: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(opened.single.host, 'www.google.com');
    expect(opened.single.queryParameters['query'], contains('1 High Street'));
    expect(repo.confirmed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repo.orders = [collectionOrder(map: false)];
    await _open(
      tester,
      repo,
      userId: 'second-buyer',
      openLink: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await tester.tap(find.text('Track parcel'));
    await tester.pumpAndSettle();
    expect(opened.last.toString(), 'https://tracking.inpost.co.uk/parcel');
  });

  testWidgets('failed external link offers a working retry', (tester) async {
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo, openLink: (_) async => false);
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open this link. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadyToCollectDialog), findsOneWidget);
  });

  test('collection API parsing keeps UTC deadlines through enrichment and rejects unsafe links', () {
    final parsed = collectionOrder();
    expect(parsed.copyWith(productName: 'Updated').collectionDeadline, parsed.collectionDeadline);
    expect(parsed.collectionDeadline!.isUtc, isTrue);
    expect(parsed.canShowCollectionReminder, isTrue);
    final invalid = OrderSummary.tryFromOrderJson({
      'id': 'unsafe',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': '2026-11-07T09:00:00',
      'collectionDeadline': '2026-11-10T09:00:00',
      'trackingUrl': 'javascript:alert(1)',
      'collectionPoint': {'name': 'Locker'},
    })!;
    expect(invalid.canShowCollectionReminder, isFalse);
    expect(invalid.trackingUri, isNull);
    expect(invalid.collectionMapUri, isNull);
  });
  testWidgets('collection timer reopens the same deadline after dismissal and relaunch', (tester) async {
    final ready = collectionOrder();
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo);
    expect(timerBubble, findsNothing);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(find.text('left to collect'), findsOneWidget);
    expect(tester.widget<DeliveryTimerBubble>(timerBubble).deadline, ready.collectionDeadline);
    await tester.tap(timerBubble);
    await tester.pumpAndSettle();
    expect(timerBubble, findsNothing);
    expect(tester.widget<ReadyToCollectDialog>(find.byType(ReadyToCollectDialog)).order.id, ready.id);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, repo);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(tester.widget<DeliveryTimerBubble>(timerBubble).deadline, ready.collectionDeadline);
  });

  testWidgets('earliest dismissed timer wins across stages and switches when it clears', (tester) async {
    final collect = collectionOrder(hours: 12);
    final confirm = order('confirmation', hours: 2);
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready', 'confirmation'],
    });
    final repo = _Repository()..orders = [collect, confirm];
    await _open(tester, repo);
    expect(find.text('left to confirm'), findsOneWidget);
    expect(tester.widget<DeliveryTimerBubble>(timerBubble).deadline, confirm.confirmationDeadline);
    background(tester);
    repo.orders = [collect];
    await resume(tester);
    expect(find.text('left to collect'), findsOneWidget);
    await tester.tap(timerBubble);
    await tester.pumpAndSettle();
    expect(find.text('Collection shirt'), findsOneWidget);
  });

  testWidgets('equal collection deadlines select the same parcel regardless of API ordering', (tester) async {
    final deadline = DateTime.now().toUtc().add(const Duration(hours: 12));
    OrderSummary ready(String id) => OrderSummary.tryFromOrderJson({
      'id': id,
      'productName': 'Parcel $id',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': DateTime.now().toUtc().toIso8601String(),
      'collectionDeadline': deadline.toIso8601String(),
    })!;
    final a = ready('a');
    final b = ready('b');
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:a:ready', 'collection:b:ready'],
    });
    final repo = _Repository()..orders = [b, a];
    await _open(tester, repo);
    await tester.tap(timerBubble);
    await tester.pumpAndSettle();
    expect(find.text('Parcel a'), findsOneWidget);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    background(tester);
    repo.orders = [a, b];
    await resume(tester);
    await tester.tap(timerBubble);
    await tester.pumpAndSettle();
    expect(find.text('Parcel a'), findsOneWidget);
  });

  for (final state in ['returned', 'returning', 'cancelled', 'failed']) {
    testWidgets('$state removes a dismissed collection timer on refresh', (tester) async {
      final ready = collectionOrder();
      SharedPreferences.setMockInitialValues({
        'deliveryReminder.buyer': ['collection:collection:ready'],
      });
      final repo = _Repository()..orders = [ready];
      await _open(tester, repo);
      expect(find.text('left to collect'), findsOneWidget);
      background(tester);
      repo.orders = [ready.copyWith(deliveryState: state)];
      await resume(tester);
      expect(timerBubble, findsNothing);
      expect(find.byType(ReadyToCollectDialog), findsNothing);
    });
  }

  testWidgets('collection timer hands over to confirmation with its own fixed deadline', (tester) async {
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final repo = _Repository()..orders = [collectionOrder()];
    await _open(tester, repo);
    final confirmed = order('collection', hours: 47);
    background(tester);
    repo.orders = [confirmed];
    await resume(tester);
    expect(find.text('left to collect'), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
    expect(timerBubble, findsNothing);
    await dismissReminder(tester);
    expect(find.text('left to confirm'), findsOneWidget);
    expect(tester.widget<DeliveryTimerBubble>(timerBubble).deadline, confirmed.confirmationDeadline);
  });

  testWidgets('collection timer expires once and refreshes before choosing expiry or confirmation', (tester) async {
    var now = DateTime.now().toUtc();
    final deadline = now.add(const Duration(seconds: 3));
    final ready = OrderSummary.tryFromOrderJson({
      'id': 'collection',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': now.subtract(const Duration(hours: 72)).toIso8601String(),
      'collectionDeadline': deadline.toIso8601String(),
    })!;
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo, now: () => now);
    expect(find.text('00:00:03'), findsOneWidget);
    now = deadline;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(repo.fetchCount, 2);
    expect(timerBubble, findsNothing);
    expect(find.text('Collection window ended'), findsOneWidget);
    expect(find.textContaining('returned'), findsNothing);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(repo.fetchCount, 2);
  });

  testWidgets('failed expiry refresh hides the timer without inventing a shipment outcome', (tester) async {
    var now = DateTime.now().toUtc();
    final deadline = now.add(const Duration(seconds: 2));
    final ready = OrderSummary.tryFromOrderJson({
      'id': 'collection',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': now.subtract(const Duration(hours: 72)).toIso8601String(),
      'collectionDeadline': deadline.toIso8601String(),
    })!;
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo, now: () => now);
    repo.failFetch = true;
    now = deadline;
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(timerBubble, findsNothing);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    repo.failFetch = false;
    background(tester);
    await resume(tester);
    expect(find.text('Collection window ended'), findsOneWidget);
  });
  testWidgets('expiry while backgrounded waits for resume and honours a returned status', (tester) async {
    var now = DateTime.now().toUtc();
    final deadline = now.add(const Duration(seconds: 2));
    final ready = OrderSummary.tryFromOrderJson({
      'id': 'collection',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': now.subtract(const Duration(hours: 72)).toIso8601String(),
      'collectionDeadline': deadline.toIso8601String(),
    })!;
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo, now: () => now);
    background(tester);
    now = deadline;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(repo.fetchCount, 1);
    // Flutter does not render new frames while paused; check the visible UI after resume.
    repo.orders = [ready.copyWith(deliveryState: 'returned')];
    await resume(tester);
    expect(repo.fetchCount, 2);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsNothing);
    expect(timerBubble, findsNothing);
  });

  testWidgets('collection reported at expiry opens confirmation instead of an expired collection notice', (
    tester,
  ) async {
    var now = DateTime.now().toUtc();
    final deadline = now.add(const Duration(seconds: 2));
    final ready = OrderSummary.tryFromOrderJson({
      'id': 'collection',
      'deliveryState': 'awaiting_collection',
      'readyForCollectionAt': now.subtract(const Duration(hours: 72)).toIso8601String(),
      'collectionDeadline': deadline.toIso8601String(),
    })!;
    SharedPreferences.setMockInitialValues({
      'deliveryReminder.buyer': ['collection:collection:ready'],
    });
    final repo = _Repository()..orders = [ready];
    await _open(tester, repo, now: () => now);
    now = deadline;
    repo.orders = [order('collection', hours: 48)];
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(repo.fetchCount, 2);
    expect(find.text('Collection window ended'), findsNothing);
    expect(find.byType(ReadyToCollectDialog), findsNothing);
    expect(find.byType(DeliveryReminderDialog), findsOneWidget);
    expect(timerBubble, findsNothing);
  });
}
