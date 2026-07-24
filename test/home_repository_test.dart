import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiService implements ApiService {
  _FakeApiService(this.response);

  final dynamic response;
  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastQueryParameters = queryParameters;
    return Result.success(response as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingApiService implements ApiService {
  const _FailingApiService();

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return Result.failure('technical failure');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HomeRepository', () {
    test('parses products from top-level list responses', () async {
      final repository = HomeRepository(
        _FakeApiService([_productJson(id: 'product-1')]),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value!.products, hasLength(1));
      expect(result.value!.products.single.id, 'product-1');
      expect(result.value!.hasMore, isFalse);
    });

    test('parses products from the standard wrapped data list', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': true,
          'message': 'Products fetched successfully',
          'data': [_productJson(id: 'product-2')],
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value!.products, hasLength(1));
      expect(result.value!.products.single.id, 'product-2');
    });

    test('parses products from direct products responses', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'products': [_productJson(id: 'product-3')],
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value!.products, hasLength(1));
      expect(result.value!.products.single.id, 'product-3');
    });

    test('parses products and pagination meta from nested data.products responses', () async {
      final apiService = _FakeApiService({
        'success': true,
        'message': 'Products with details fetched successfully',
        'data': {
          'products': [_productJson(id: 'product-4')],
        },
        'meta': {
          'limit': 20,
          'nextCursor': 'cursor-2',
          'hasMore': true,
        },
      });
      final repository = HomeRepository(
        apiService,
      );

      final result = await repository.fetchProducts(
        limit: 20,
        cursor: 'cursor-1',
        search: ' jumper ',
      );

      expect(result.isSuccess, isTrue);
      expect(result.value!.products, hasLength(1));
      expect(result.value!.products.single.id, 'product-4');
      expect(result.value!.limit, 20);
      expect(result.value!.nextCursor, 'cursor-2');
      expect(result.value!.hasMore, isTrue);
      expect(apiService.lastQueryParameters, {
        'limit': 20,
        'cursor': 'cursor-1',
        'search': 'jumper',
      });
    });

    test('returns failure for unsuccessful response envelopes', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': false,
          'message': 'Unauthorized',
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });

    test('returns failure for unexpected response structures', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'message': 'Unexpected response without products',
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });

    test('returns failure when the API service fails', () async {
      final repository = HomeRepository(const _FailingApiService());

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, 'technical failure');
    });

    test('omits empty cursor and search query parameters', () async {
      final apiService = _FakeApiService({
        'success': true,
        'data': {
          'products': [_productJson(id: 'product-5')],
        },
      });
      final repository = HomeRepository(apiService);

      await repository.fetchProducts(limit: 10, cursor: '', search: '   ');

      expect(apiService.lastQueryParameters, {'limit': 10});
    });

    test('excludes products owned by the signed-in seller', () async {
      final repository = HomeRepository(
        _FakeApiService([
          _productJson(id: 'own-product', userId: 'seller-1'),
          _productJson(id: 'other-product', userId: 'seller-2'),
        ]),
        currentUserIdProvider: () => 'seller-1',
      );

      final result = await repository.fetchProducts();

      expect(
        result.value!.products.map((product) => product.id),
        ['other-product'],
      );
    });
  });
}

Map<String, dynamic> _productJson({
  required String id,
  String? userId,
}) {
  return {
    'id': id,
    'userId': ?userId,
    'name': 'Jumper',
    'description': 'Blue jumper',
    'quality': 'GOOD',
    'product_images': ['https://example.com/jumper.jpg'],
    'donation': 20,
    'price': 20,
    'securityFee': 2,
    'likes': 0,
    'number': 1,
    'size': 'Medium',
    'postageSize': 'postage-medium',
    'categoryId': 'category-1',
    'charityId': 'charity-1',
    'createdAt': '2026-07-15T00:00:00.000Z',
    'updatedAt': '2026-07-15T00:00:00.000Z',
  };
}
