import 'package:cherry_mvp/core/services/error_string.dart';
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

void main() {
  group('HomeRepository', () {
    test('parses products from nested data.products responses', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': true,
          'message': 'Products with details fetched successfully',
          'data': {
            'products': [_productJson()],
          },
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'product-1');
      expect(result.value!.single.name, 'Jumper');
    });

    test('returns a friendly error for unsupported product response shapes', () async {
      final repository = HomeRepository(
        _FakeApiService({
          'success': true,
          'data': {
            'products': {'id': 'not-a-list'},
          },
        }),
      );

      final result = await repository.fetchProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, ErrorStrings.apiError);
    });
  });
}

Map<String, dynamic> _productJson() {
  return {
    'id': 'product-1',
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
    'createdAt': '2026-07-14T00:00:00.000Z',
    'updatedAt': '2026-07-14T00:00:00.000Z',
  };
}
