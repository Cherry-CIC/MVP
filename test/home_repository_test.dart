import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiService implements ApiService {
  _FakeApiService(this.response);

  final dynamic response;

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
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
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'product-1');
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
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'product-2');
    });

    test('parses products from direct products responses', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'products': [_productJson(id: 'product-3')],
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'product-3');
    });

    test('parses products from nested data.products responses', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': true,
          'message': 'Products with details fetched successfully',
          'data': {
            'products': [_productJson(id: 'product-4')],
          },
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'product-4');
    });

    test('returns an empty product list for unsuccessful response envelopes', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': false,
          'message': 'Unauthorized',
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('returns an empty product list for unexpected response structures', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'message': 'Unexpected response without products',
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('returns an empty product list when the API service fails', () async {
      final repository = HomeRepository(const _FailingApiService());

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });
  });
}

Map<String, dynamic> _productJson({required String id}) {
  return {
    'id': id,
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
