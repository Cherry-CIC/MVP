import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends Fake implements IOrdersRepository {
  List<OrderSummary> orders = [];
  String? confirmed;
  String? disputed;

  @override
  Future<Result<List<OrderSummary>>> fetchOrders({bool deliveryRemindersOnly = false}) async {
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
      if (hours != null) 'confirmationDeadline': DateTime.now().toUtc().add(Duration(hours: hours)).toIso8601String(),
    })!.copyWith(size: 'L');

Future<void> open(WidgetTester tester, _Repository repo, {String userId = 'buyer'}) async {
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
          child: const Scaffold(body: Text('Home')),
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('cold start uses earliest active deadline and outside dismissal survives reopening', (tester) async {
    final repo = _Repository()
      ..orders = [
        order('old', hours: -1),
        order('unknown', hours: null),
        order('confirmed', state: 'confirmed'),
        order('disputed', state: 'disputed'),
        order('later', hours: 24),
        order('first'),
      ];
    await open(tester, repo);
    expect(find.text('Item FIRST'), findsOneWidget);
    final countdown = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan?.toPlainText().contains('left to check') == true,
      ),
    );
    expect(countdown.textSpan!.toPlainText(includeSemanticsLabels: false), matches(RegExp(r'^(12:00:00|11:59:\d{2})')));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Your item has arrived'), findsNothing);
    expect(repo.confirmed, isNull);
    repo.orders = [order('first')];
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, repo);
    expect(find.text('Your item has arrived'), findsNothing);
    await open(tester, repo, userId: 'another-buyer');
    expect(find.text('Your item has arrived'), findsOneWidget);
  });

  testWidgets('delivery while away appears on resume and View item requires explicit confirmation', (tester) async {
    final repo = _Repository();
    await open(tester, repo);
    expect(find.text('Your item has arrived'), findsNothing);
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
  });

  testWidgets('a reminder open in the background is revalidated when the buyer returns', (tester) async {
    final repo = _Repository()..orders = [order('a')];
    await open(tester, repo);
    expect(find.text('Your item has arrived'), findsOneWidget);
    background(tester);
    repo.orders = [order('a', hours: -1)];
    await resume(tester);
    expect(find.text('Your item has arrived'), findsNothing);
  });

  testWidgets('problem action opens the dispute form for the displayed order', (tester) async {
    final repo = _Repository()..orders = [order('a')];
    await open(tester, repo);
    await tester.tap(find.text('Something’s not right'));
    await tester.pumpAndSettle();
    expect(find.text('Raise dispute'), findsOneWidget);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(repo.disputed, 'a');
    expect(repo.confirmed, isNull);
  });
}
