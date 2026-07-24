import 'dart:async';

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _QueuedOrdersRepository implements IOrdersRepository {
  final List<Future<Result<List<OrderSummary>>>> responses;

  _QueuedOrdersRepository(this.responses);

  @override
  Future<Result<List<OrderSummary>>> fetchOrders() {
    return responses.removeAt(0);
  }
}

void main() {
  group('OrdersViewModel', () {
    test('moves from loading to success', () async {
      final response = Completer<Result<List<OrderSummary>>>();
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([response.future]),
      );

      final request = viewModel.loadOrders();

      expect(viewModel.status.type, StatusType.loading);
      expect(viewModel.orders, isEmpty);

      response.complete(Result.success([_order('order-1')]));
      await request;

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.orders.single.id, 'order-1');
      expect(viewModel.isRefreshing, isFalse);
    });

    test('represents an empty response as a successful empty state', () async {
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([
          Future.value(Result.success(const [])),
        ]),
      );

      await viewModel.loadOrders();

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.orders, isEmpty);
    });

    test('exposes an initial failure and supports retry', () async {
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([
          Future.value(Result.failure('Technical failure')),
          Future.value(Result.success([_order('retried-order')])),
        ]),
      );

      await viewModel.loadOrders();

      expect(viewModel.status.type, StatusType.failure);
      expect(viewModel.status.message, 'Technical failure');

      await viewModel.retryLoad();

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.orders.single.id, 'retried-order');
    });

    test('refresh preserves visible orders and then replaces them', () async {
      final refreshResponse = Completer<Result<List<OrderSummary>>>();
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([
          Future.value(Result.success([_order('existing-order')])),
          refreshResponse.future,
        ]),
      );
      await viewModel.loadOrders();

      final refresh = viewModel.refreshOrders();

      expect(viewModel.orders.single.id, 'existing-order');
      expect(viewModel.isRefreshing, isTrue);

      refreshResponse.complete(
        Result.success([_order('refreshed-order')]),
      );
      await refresh;

      expect(viewModel.orders.single.id, 'refreshed-order');
      expect(viewModel.isRefreshing, isFalse);
      expect(viewModel.refreshError, isNull);
    });

    test('failed refresh preserves visible orders and exposes a refresh error', () async {
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([
          Future.value(Result.success([_order('existing-order')])),
          Future.value(Result.failure('Technical failure')),
        ]),
      );
      await viewModel.loadOrders();

      await viewModel.refreshOrders();

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.orders.single.id, 'existing-order');
      expect(viewModel.refreshError, 'Technical failure');
      expect(viewModel.isRefreshing, isFalse);
    });

    test('a superseded response cannot replace newer orders', () async {
      final staleResponse = Completer<Result<List<OrderSummary>>>();
      final newerResponse = Completer<Result<List<OrderSummary>>>();
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([
          staleResponse.future,
          newerResponse.future,
        ]),
      );

      final staleRequest = viewModel.loadOrders();
      final newerRequest = viewModel.refreshOrders();
      newerResponse.complete(Result.success([_order('newer-order')]));
      await newerRequest;
      staleResponse.complete(Result.success([_order('stale-order')]));
      await staleRequest;

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.orders.single.id, 'newer-order');
    });

    test('clearing orders prevents an in-flight response restoring account data', () async {
      final response = Completer<Result<List<OrderSummary>>>();
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([response.future]),
      );

      final request = viewModel.loadOrders();
      viewModel.clearOrders(notify: false);
      response.complete(
        Result.success([_order('previous-account-order')]),
      );
      await request;

      expect(viewModel.status.type, StatusType.uninitialized);
      expect(viewModel.orders, isEmpty);
      expect(viewModel.isRefreshing, isFalse);
    });

    test('dispose clears orders and ignores an in-flight response', () async {
      final response = Completer<Result<List<OrderSummary>>>();
      final viewModel = OrdersViewModel(
        repository: _QueuedOrdersRepository([response.future]),
      );
      var notifications = 0;
      viewModel.addListener(() {
        notifications++;
      });

      final request = viewModel.loadOrders();
      expect(notifications, 1);
      viewModel.dispose();
      response.complete(
        Result.success([_order('previous-account-order')]),
      );
      await request;

      expect(viewModel.status.type, StatusType.uninitialized);
      expect(viewModel.orders, isEmpty);
      expect(notifications, 1);
    });
  });
}

OrderSummary _order(String id) {
  return OrderSummary(
    id: id,
    productId: 'product-$id',
    productName: 'Example shirt',
    imageUrl: '',
    size: 'M',
    charityLogoUrl: '',
    itemPriceMinor: 400,
    totalAmountMinor: 600,
    currency: 'GBP',
    deliveryState: 'preparing',
    deliveryLabel: 'Preparing',
  );
}
