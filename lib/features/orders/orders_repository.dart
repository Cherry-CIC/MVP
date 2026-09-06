import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';

abstract class IOrdersRepository {
  Future<Result<List<OrderSummary>>> fetchOrders();
}

final class OrdersRepository implements IOrdersRepository {
  static const int _maximumConcurrentProductRequests = 4;

  final ApiService _apiService;

  OrdersRepository(this._apiService);

  @override
  Future<Result<List<OrderSummary>>> fetchOrders() async {
    try {
      final result = await _apiService.get<dynamic>(ApiEndpoints.myOrders);
      if (!result.isSuccess || result.value == null) {
        SafeLog.event(
          AppLogEvent.ordersLoadFailed,
          level: SafeLogLevel.warning,
        );
        return Result.failure(
          result.error ?? 'Could not load your orders',
        );
      }

      final rawOrders = _extractOrders(result.value);
      if (rawOrders == null) {
        SafeLog.event(
          AppLogEvent.ordersResponseInvalid,
          level: SafeLogLevel.warning,
        );
        return Result.failure('Could not load your orders');
      }

      final orders = rawOrders.map(OrderSummary.tryFromOrderJson).whereType<OrderSummary>().toList(growable: false);
      if (orders.isEmpty) {
        return Result.success(const []);
      }

      final charityLogos = await _fetchCharityLogos();
      final products = await _fetchProducts(
        orders.map((order) => order.productId).where((productId) => productId.isNotEmpty).toSet(),
      );

      final enrichedOrders = orders
          .map((order) {
            final product = products[order.productId];
            if (product == null) {
              return order;
            }

            return order.copyWith(
              productName: order.productName == OrderSummary.fallbackProductName && product.name.isNotEmpty
                  ? product.name
                  : order.productName,
              imageUrl: product.imageUrl,
              size: product.size,
              charityLogoUrl: charityLogos[product.charityId] ?? '',
            );
          })
          .toList(growable: false);

      return Result.success(enrichedOrders);
    } catch (_) {
      SafeLog.event(
        AppLogEvent.ordersLoadFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure('Could not load your orders');
    }
  }

  List<dynamic>? _extractOrders(dynamic response) {
    if (response is! Map || response['success'] == false) {
      return null;
    }

    final data = response['data'];
    if (data is! Map) {
      return null;
    }

    final orders = data['orders'];
    return orders is List ? orders : null;
  }

  Future<Map<String, String>> _fetchCharityLogos() async {
    try {
      final result = await _apiService.get<dynamic>(ApiEndpoints.charities);
      if (!result.isSuccess || result.value == null) {
        SafeLog.event(
          AppLogEvent.ordersCharityEnrichmentFailed,
          level: SafeLogLevel.warning,
        );
        return const {};
      }

      final response = result.value;
      if (response is! Map || response['success'] == false) {
        SafeLog.event(
          AppLogEvent.ordersCharityEnrichmentInvalid,
          level: SafeLogLevel.warning,
        );
        return const {};
      }

      final data = response['data'];
      if (data is! List) {
        SafeLog.event(
          AppLogEvent.ordersCharityEnrichmentInvalid,
          level: SafeLogLevel.warning,
        );
        return const {};
      }

      final charityLogos = <String, String>{};
      for (final value in data) {
        if (value is! Map) {
          continue;
        }
        final id = _readString(value['id']);
        final imageUrl = _readString(value['imageUrl']);
        if (id.isNotEmpty && imageUrl.isNotEmpty) {
          charityLogos[id] = imageUrl;
        }
      }
      return charityLogos;
    } catch (_) {
      SafeLog.event(
        AppLogEvent.ordersCharityEnrichmentFailed,
        level: SafeLogLevel.warning,
      );
      return const {};
    }
  }

  Future<Map<String, _ProductEnrichment>> _fetchProducts(
    Set<String> productIds,
  ) async {
    final ids = productIds.toList(growable: false);
    final products = <String, _ProductEnrichment>{};
    var failedProducts = 0;

    for (var start = 0; start < ids.length; start += _maximumConcurrentProductRequests) {
      final candidateEnd = start + _maximumConcurrentProductRequests;
      final end = candidateEnd < ids.length ? candidateEnd : ids.length;
      final batch = ids.sublist(start, end);
      final results = await Future.wait(
        batch.map(_fetchProduct),
      );

      for (var index = 0; index < batch.length; index++) {
        final product = results[index];
        if (product == null) {
          failedProducts++;
        } else {
          products[batch[index]] = product;
        }
      }
    }

    if (failedProducts > 0) {
      SafeLog.event(
        AppLogEvent.ordersProductEnrichmentPartial,
        level: SafeLogLevel.warning,
      );
    }
    return products;
  }

  Future<_ProductEnrichment?> _fetchProduct(String productId) async {
    try {
      final result = await _apiService.get<dynamic>(
        ApiEndpoints.productById(productId),
      );
      if (!result.isSuccess || result.value == null) {
        return null;
      }

      final response = result.value;
      if (response is! Map || response['success'] == false) {
        return null;
      }

      final data = response['data'];
      return _ProductEnrichment.tryFromJson(data);
    } catch (_) {
      return null;
    }
  }

  static String _readString(dynamic value) {
    return value is String ? value.trim() : '';
  }
}

final class _ProductEnrichment {
  final String name;
  final String imageUrl;
  final String size;
  final String charityId;

  const _ProductEnrichment({
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.charityId,
  });

  static _ProductEnrichment? tryFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final rawImages = value['product_images'] ?? value['images'] ?? value['productImages'];
    final imageUrl = rawImages is List
        ? rawImages
              .whereType<String>()
              .map((url) => url.trim())
              .firstWhere(
                (url) => url.isNotEmpty,
                orElse: () => '',
              )
        : '';

    return _ProductEnrichment(
      name: _readString(value['name']),
      imageUrl: imageUrl,
      size: _readString(value['size']),
      charityId: _readString(value['charityId']),
    );
  }

  static String _readString(dynamic value) {
    return value is String ? value.trim() : '';
  }
}
