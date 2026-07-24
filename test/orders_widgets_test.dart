import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/order_currency_formatter.dart';
import 'package:cherry_mvp/features/orders/orders_page.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _QueuedOrdersRepository implements IOrdersRepository {
  final List<Result<List<OrderSummary>>> responses;
  int requestCount = 0;

  _QueuedOrdersRepository(this.responses);

  @override
  Future<Result<List<OrderSummary>>> fetchOrders() async {
    requestCount++;
    return responses.removeAt(0);
  }
}

OrderSummary _order({
  String id = 'order-1',
  String productName = 'Example shirt',
  String currency = 'GBP',
  int? itemPriceMinor = 400,
  String deliveryState = 'delivered',
  String deliveryLabel = 'Delivered',
  String imageUrl = '',
  String charityLogoUrl = '',
}) {
  return OrderSummary(
    id: id,
    productId: 'product-1',
    productName: productName,
    imageUrl: imageUrl,
    size: 'M',
    charityLogoUrl: charityLogoUrl,
    itemPriceMinor: itemPriceMinor,
    totalAmountMinor: 825,
    currency: currency,
    deliveryState: deliveryState,
    deliveryLabel: deliveryLabel,
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required OrdersViewModel viewModel,
  VoidCallback? onBack,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: MyOrdersPage(onBack: onBack ?? () {}),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('OrderCurrencyFormatter', () {
    test('formats GBP minor units without widget-level currency text', () {
      expect(
        OrderCurrencyFormatter.formatItemPrice(_order()),
        '£4.00',
      );
    });

    test('does not label a GBP product price as another currency', () {
      expect(
        OrderCurrencyFormatter.formatItemPrice(
          _order(currency: 'EUR'),
        ),
        isNull,
      );
    });

    test('uses an ISO code for an explicitly formatted unknown currency', () {
      expect(
        OrderCurrencyFormatter.formatMinorUnits(
          minorUnits: 400,
          currency: 'ZZZ',
        ),
        'ZZZ 4.00',
      );
    });
  });

  group('OrderStatusFormatter', () {
    test('prefers a non-empty backend delivery label', () {
      expect(
        OrderStatusFormatter.labelFor(
          _order(
            deliveryState: 'unexpected_state',
            deliveryLabel: 'Ready to collect',
          ),
        ),
        'Ready to collect',
      );
    });

    test('maps recognised states and keeps unknown states neutral', () {
      expect(
        OrderStatusFormatter.labelFor(
          _order(deliveryState: 'in_transit', deliveryLabel: ''),
        ),
        'On the way',
      );
      expect(
        OrderStatusFormatter.labelFor(
          _order(deliveryState: 'mystery', deliveryLabel: ''),
        ),
        AppStrings.myOrdersStatusUnavailable,
      );
    });
  });

  testWidgets('order card matches the required information hierarchy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OrderCard(order: _order()),
          ),
        ),
      ),
    );

    expect(find.text('Example shirt'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('£4.00'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Example shirt. Size M. £4.00. Delivered.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('order card uses safe fallbacks for partial enrichment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OrderCard(
              order: _order(
                currency: 'EUR',
                itemPriceMinor: null,
                deliveryState: 'unknown',
                deliveryLabel: '',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.myOrdersPriceUnavailable), findsOneWidget);
    expect(find.text(AppStrings.myOrdersStatusUnavailable), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order card tolerates narrow screens and 200 per cent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: OrderCard(order: _order()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Example shirt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long product names can grow without overflowing the image row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OrderCard(
              order: _order(
                productName: 'Baggy Beige Men’s Button Shirt',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Baggy Beige Men’s Button Shirt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Orders loads orders and invokes its back callback', (
    tester,
  ) async {
    var wentBack = false;
    final repository = _QueuedOrdersRepository([
      Result.success([_order()]),
    ]);
    final viewModel = OrdersViewModel(repository: repository);

    await _pumpPage(
      tester,
      viewModel: viewModel,
      onBack: () => wentBack = true,
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myOrdersTitle), findsOneWidget);
    expect(find.text('Example shirt'), findsOneWidget);
    expect(repository.requestCount, 1);

    await tester.tap(find.byTooltip(AppStrings.back));
    expect(wentBack, isTrue);
  });

  testWidgets('My Orders shows an empty state after a successful load', (
    tester,
  ) async {
    final viewModel = OrdersViewModel(
      repository: _QueuedOrdersRepository([
        Result.success(const []),
      ]),
    );

    await _pumpPage(tester, viewModel: viewModel);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myOrdersEmpty), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('My Orders supports retry after an initial failure', (
    tester,
  ) async {
    final repository = _QueuedOrdersRepository([
      Result.failure('technical failure'),
      Result.success([_order()]),
    ]);
    final viewModel = OrdersViewModel(repository: repository);

    await _pumpPage(tester, viewModel: viewModel);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.myOrdersLoadFailed), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);

    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(find.text('Example shirt'), findsOneWidget);
    expect(repository.requestCount, 2);
  });

  testWidgets('disposing My Orders clears cached account data', (
    tester,
  ) async {
    final viewModel = OrdersViewModel(
      repository: _QueuedOrdersRepository([
        Result.success([_order()]),
      ]),
    );

    await _pumpPage(tester, viewModel: viewModel);
    await tester.pumpAndSettle();
    expect(viewModel.orders, isNotEmpty);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(viewModel.orders, isEmpty);
  });
}
