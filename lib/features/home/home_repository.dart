import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:logging/logging.dart';
import 'home_model.dart';

abstract class IHomeRepository {
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  });
}

final class ProductPage {
  final List<Product> products;
  final int limit;
  final String? nextCursor;
  final bool hasMore;

  const ProductPage({
    required this.products,
    required this.limit,
    required this.nextCursor,
    required this.hasMore,
  });
}

final class HomeRepository implements IHomeRepository {
  final ApiService _apiService;
  final String? Function() _currentUserIdProvider;
  final _log = Logger('HomeRepository');

  HomeRepository(
    this._apiService, {
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? (() => null);

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    try {
      _log.info('Fetching products from API...');
      final result = await _apiService.get(
        ApiEndpoints.productsWithDetails,
        queryParameters: {
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (result.isSuccess && result.value != null) {
        _log.info('API call successful, parsing response...');
        final data = result.value;

        if (data is Map<String, dynamic> && data['success'] == false) {
          _log.warning('Products API returned an unsuccessful response: $data');
          return Result.failure('Products API returned an unsuccessful response');
        }

        final jsonList = _extractProductList(data);
        if (jsonList == null) {
          _log.warning('Unexpected products response structure: ${data.runtimeType}');
          return Result.failure('Unexpected products response structure');
        }

        final List<Product> products = [];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final json = Map<String, dynamic>.from(jsonList[i] as Map);
            final product = Product.fromJson(json);
            products.add(product);
          } catch (e) {
            _log.warning('Failed to parse product $i: $e');
          }
        }

        _log.info('Successfully parsed ${products.length} products');
        final meta = _extractMeta(data);
        return Result.success(
          ProductPage(
            products: excludeCurrentSellerProducts(
              products,
              _currentUserIdProvider(),
            ),
            limit: meta.limit ?? limit,
            nextCursor: meta.nextCursor,
            hasMore: meta.hasMore,
          ),
        );
      } else {
        _log.warning('API call failed: ${result.error}');
        return Result.failure(result.error ?? 'Products API request failed');
      }
    } catch (e) {
      _log.severe('Exception during product fetch: $e');
      return Result.failure('Exception during product fetch');
    }
  }

  List<dynamic>? _extractProductList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directData = data['data'];
      if (directData is List) {
        return directData;
      }

      if (directData is Map<String, dynamic>) {
        final nestedProducts = directData['products'];
        if (nestedProducts is List) {
          return nestedProducts;
        }
      }

      final directProducts = data['products'];
      if (directProducts is List) {
        return directProducts;
      }
    }

    return null;
  }

  _ProductMeta _extractMeta(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const _ProductMeta();
    }

    final meta = data['meta'];
    if (meta is! Map<String, dynamic>) {
      return const _ProductMeta();
    }

    return _ProductMeta(
      limit: _parseInt(meta['limit']),
      nextCursor: meta['nextCursor'] is String ? meta['nextCursor'] as String : null,
      hasMore: meta['hasMore'] == true,
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

final class HomeRepositoryMock implements IHomeRepository {
  final String? Function() _currentUserIdProvider;

  HomeRepositoryMock({
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? (() => null);

  @override
  Future<Result<ProductPage>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? search,
  }) async {
    return Result.success(
      ProductPage(
        products: excludeCurrentSellerProducts(
          dummyProducts,
          _currentUserIdProvider(),
        ).take(limit).toList(),
        limit: limit,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

List<Product> excludeCurrentSellerProducts(
  Iterable<Product> products,
  String? currentUserId,
) {
  final normalizedUserId = currentUserId?.trim();
  if (normalizedUserId == null || normalizedUserId.isEmpty) {
    return products.toList();
  }

  return products
      .where((product) => product.userId?.trim() != normalizedUserId)
      .toList();
}

final class _ProductMeta {
  final int? limit;
  final String? nextCursor;
  final bool hasMore;

  const _ProductMeta({
    this.limit,
    this.nextCursor,
    this.hasMore = false,
  });
}
