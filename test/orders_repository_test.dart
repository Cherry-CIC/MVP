import 'dart:async';

import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _GetHandler = FutureOr<Result<dynamic>> Function(String endpoint);

class _FakeApiService implements ApiService {
  final _GetHandler _handler;
  final List<String> requestedEndpoints = [];

  _FakeApiService(this._handler);

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedEndpoints.add(endpoint);
    final result = await _handler(endpoint);
    if (!result.isSuccess) {
      return Result.failure(result.error);
    }
    return Result.success(result.value as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('OrderSummary', () {
    test('parses documented order fields without converting minor units', () {
      final order = OrderSummary.tryFromOrderJson({
        'id': ' order-1 ',
        'productId': ' product-1 ',
        'productName': ' Shirt ',
        'productAmount': 400,
        'totalAmount': 2599,
        'currency': ' gbp ',
        'deliveryState': ' shipped ',
        'deliveryLabel': ' On the way ',
      });

      expect(order, isNotNull);
      expect(order!.id, 'order-1');
      expect(order.productId, 'product-1');
      expect(order.productName, 'Shirt');
      expect(order.itemPriceMinor, 400);
      expect(order.totalAmountMinor, 2599);
      expect(order.currency, 'GBP');
      expect(order.deliveryState, 'shipped');
      expect(order.deliveryLabel, 'On the way');
    });

    test('retains valid ISO currencies and uses GBP only as a fallback', () {
      final euroOrder = OrderSummary.tryFromOrderJson(
        _orderJson(
          id: 'euro-order',
          productId: 'product-1',
          currency: 'eur',
        ),
      );
      final missingCurrencyOrder = OrderSummary.tryFromOrderJson(
        _orderJson(
          id: 'fallback-order',
          productId: 'product-2',
          currency: null,
        ),
      );

      expect(euroOrder!.currency, 'EUR');
      expect(missingCurrencyOrder!.currency, 'GBP');
    });

    test('rejects a missing order identifier and preserves a missing product identifier', () {
      expect(
        OrderSummary.tryFromOrderJson({
          'productId': 'product-1',
          'productName': 'Shirt',
        }),
        isNull,
      );

      final orderWithoutProduct = OrderSummary.tryFromOrderJson({
        'id': 'order-without-product',
        'productName': 'Purchased item',
      });
      expect(orderWithoutProduct, isNotNull);
      expect(orderWithoutProduct!.productId, isEmpty);
      expect(orderWithoutProduct.productName, 'Purchased item');
      expect(orderWithoutProduct.itemPriceMinor, isNull);
    });

    test('treats unsafe monetary values as unavailable', () {
      final order = OrderSummary.tryFromOrderJson(
        _orderJson(
          id: 'order-2',
          productId: 'product-2',
          productAmount: 12.5,
          totalAmount: 12.5,
        ),
      );
      expect(order!.itemPriceMinor, isNull);
      expect(order.totalAmountMinor, isNull);
    });
  });

  group('OrdersRepository', () {
    test('enriches order metadata without replacing its purchase price', () async {
      final apiService = _FakeApiService((endpoint) {
        if (endpoint == ApiEndpoints.myOrders) {
          return Result.success({
            'success': true,
            'data': {
              'orders': [
                _orderJson(
                  id: 'order-1',
                  productId: 'product-1',
                  productName: 'Purchased shirt',
                  productAmount: 400,
                  totalAmount: 2599,
                  currency: 'gbp',
                  deliveryState: 'shipped',
                  deliveryLabel: 'On the way',
                ),
              ],
              'count': 1,
            },
          });
        }
        if (endpoint == ApiEndpoints.charities) {
          return Result.success({
            'success': true,
            'data': [
              {
                'id': 'charity-1',
                'imageUrl': 'https://example.com/charity.png',
              },
            ],
          });
        }
        if (endpoint == ApiEndpoints.productById('product-1')) {
          return Result.success({
            'success': true,
            'data': _productJson(
              id: 'product-1',
              name: 'Current shirt name',
              price: '4.25',
              charityId: 'charity-1',
            ),
          });
        }
        return Result.failure('Unexpected endpoint');
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      expect(apiService.requestedEndpoints, [
        ApiEndpoints.myOrders,
        ApiEndpoints.charities,
        ApiEndpoints.productById('product-1'),
      ]);
      final order = result.value!.single;
      expect(order.id, 'order-1');
      expect(order.productName, 'Purchased shirt');
      expect(order.imageUrl, 'https://example.com/product.jpg');
      expect(order.size, 'M');
      expect(order.charityLogoUrl, 'https://example.com/charity.png');
      expect(order.itemPriceMinor, 400);
      expect(order.totalAmountMinor, 2599);
      expect(order.currency, 'GBP');
      expect(order.deliveryState, 'shipped');
      expect(order.deliveryLabel, 'On the way');
    });

    test('keeps valid orders and tolerates malformed records', () async {
      final apiService = _FakeApiService((endpoint) {
        if (endpoint == ApiEndpoints.myOrders) {
          return Result.success({
            'success': true,
            'data': {
              'orders': [
                'not an order',
                {'id': 'missing-product'},
                _orderJson(
                  id: 'valid-order',
                  productId: 'product-1',
                  productName: '',
                  currency: null,
                  deliveryState: null,
                  status: 'preparing',
                ),
              ],
            },
          });
        }
        if (endpoint == ApiEndpoints.charities) {
          return Result.failure('Unavailable');
        }
        return Result.success({
          'success': true,
          'data': _productJson(
            id: 'product-1',
            name: 'Fallback product name',
          ),
        });
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(2));
      final missingProductOrder = result.value!.first;
      expect(missingProductOrder.id, 'missing-product');
      expect(missingProductOrder.productId, isEmpty);
      expect(missingProductOrder.productName, OrderSummary.fallbackProductName);
      final validOrder = result.value!.last;
      expect(validOrder.id, 'valid-order');
      expect(validOrder.productName, 'Fallback product name');
      expect(validOrder.currency, 'GBP');
      expect(validOrder.deliveryState, 'preparing');
      expect(validOrder.charityLogoUrl, isEmpty);
    });

    test('keeps the basic order when all enrichment fails', () async {
      final apiService = _FakeApiService((endpoint) {
        if (endpoint == ApiEndpoints.myOrders) {
          return Result.success({
            'success': true,
            'data': {
              'orders': [
                _orderJson(
                  id: 'order-1',
                  productId: 'deleted-product',
                  productName: 'Purchased item',
                ),
              ],
            },
          });
        }
        return Result.failure('Unavailable');
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      final order = result.value!.single;
      expect(order.productName, 'Purchased item');
      expect(order.imageUrl, isEmpty);
      expect(order.charityLogoUrl, isEmpty);
      expect(order.itemPriceMinor, 400);
    });

    test('keeps the historical amount paired with its order currency', () async {
      final apiService = _FakeApiService((endpoint) {
        if (endpoint == ApiEndpoints.myOrders) {
          return Result.success({
            'success': true,
            'data': {
              'orders': [
                _orderJson(
                  id: 'euro-order',
                  productId: 'product-1',
                  currency: 'EUR',
                ),
              ],
            },
          });
        }
        if (endpoint == ApiEndpoints.charities) {
          return Result.success({
            'success': true,
            'data': const [],
          });
        }
        return Result.success({
          'success': true,
          'data': _productJson(
            id: 'product-1',
            price: 9,
          ),
        });
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      expect(result.value!.single.currency, 'EUR');
      expect(result.value!.single.itemPriceMinor, 400);
    });

    test('deduplicates product IDs and runs no more than four product requests', () async {
      var inFlightProductRequests = 0;
      var maximumInFlightProductRequests = 0;
      final apiService = _FakeApiService((endpoint) async {
        if (endpoint == ApiEndpoints.myOrders) {
          return Result.success({
            'success': true,
            'data': {
              'orders': [
                for (var index = 1; index <= 6; index++)
                  _orderJson(
                    id: 'order-$index',
                    productId: 'product-$index',
                  ),
                _orderJson(
                  id: 'duplicate-product-order',
                  productId: 'product-1',
                ),
              ],
            },
          });
        }
        if (endpoint == ApiEndpoints.charities) {
          return Result.success({
            'success': true,
            'data': const [],
          });
        }

        inFlightProductRequests++;
        if (inFlightProductRequests > maximumInFlightProductRequests) {
          maximumInFlightProductRequests = inFlightProductRequests;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        inFlightProductRequests--;

        final productId = Uri.decodeComponent(
          endpoint.substring('${ApiEndpoints.products}/'.length),
        );
        return Result.success({
          'success': true,
          'data': _productJson(id: productId),
        });
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(7));
      expect(maximumInFlightProductRequests, 4);
      final productRequests = apiService.requestedEndpoints
          .where((endpoint) => endpoint.startsWith('${ApiEndpoints.products}/'))
          .toList();
      expect(productRequests, hasLength(6));
      expect(
        productRequests.where(
          (endpoint) => endpoint == ApiEndpoints.productById('product-1'),
        ),
        hasLength(1),
      );
    });

    test('does not enrich an empty order list', () async {
      final apiService = _FakeApiService((endpoint) {
        return Result.success({
          'success': true,
          'data': {
            'orders': const [],
            'count': 0,
          },
        });
      });
      final repository = OrdersRepository(apiService);

      final result = await repository.fetchOrders();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
      expect(apiService.requestedEndpoints, [ApiEndpoints.myOrders]);
    });

    test('treats main request and envelope failures as fatal', () async {
      final failedRequest = OrdersRepository(
        _FakeApiService(
          (_) => Result.failure('Technical failure'),
        ),
      );
      final unsuccessfulEnvelope = OrdersRepository(
        _FakeApiService(
          (_) => Result.success({'success': false}),
        ),
      );
      final malformedEnvelope = OrdersRepository(
        _FakeApiService(
          (_) => Result.success({
            'success': true,
            'data': {'count': 1},
          }),
        ),
      );

      final failedResult = await failedRequest.fetchOrders();
      final unsuccessfulResult = await unsuccessfulEnvelope.fetchOrders();
      final malformedResult = await malformedEnvelope.fetchOrders();

      expect(failedResult.isSuccess, isFalse);
      expect(failedResult.error, 'Technical failure');
      expect(unsuccessfulResult.isSuccess, isFalse);
      expect(malformedResult.isSuccess, isFalse);
    });
  });
}

Map<String, dynamic> _orderJson({
  required String id,
  required String productId,
  String productName = 'Example shirt',
  dynamic productAmount = 400,
  dynamic totalAmount = 2599,
  dynamic currency = 'GBP',
  dynamic deliveryState = 'preparing',
  String deliveryLabel = 'Preparing',
  String? status,
}) {
  return {
    'id': id,
    'productId': productId,
    'productName': productName,
    'productAmount': productAmount,
    'totalAmount': totalAmount,
    'currency': currency,
    'deliveryState': deliveryState,
    'deliveryLabel': deliveryLabel,
    'status': status,
  };
}

Map<String, dynamic> _productJson({
  required String id,
  String name = 'Example shirt',
  dynamic price = 4,
  String charityId = 'charity-1',
}) {
  return {
    'id': id,
    'name': name,
    'product_images': [
      '',
      'https://example.com/product.jpg',
    ],
    'price': price,
    'size': 'M',
    'charityId': charityId,
  };
}
