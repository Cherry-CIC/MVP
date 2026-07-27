import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApiService implements ApiService {
  _RecordingApiService({
    this.getValue,
    this.getError,
    this.postValue,
    this.postError,
  });

  final dynamic getValue;
  final String? getError;
  final dynamic postValue;
  final String? postError;

  String? lastGetEndpoint;
  Map<String, dynamic>? lastQueryParameters;
  String? lastPostEndpoint;
  dynamic lastPostData;
  int postCount = 0;

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetEndpoint = endpoint;
    lastQueryParameters = queryParameters;
    if (getError != null) {
      return Result.failure(getError);
    }
    return Result.success(getValue as T);
  }

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    postCount += 1;
    lastPostEndpoint = endpoint;
    lastPostData = data;
    if (postError != null) {
      return Result.failure(postError);
    }
    return Result.success(postValue as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProductRepository.fetchLikedProducts', () {
    test('uses the authenticated liked-products endpoint and parses products', () async {
      final apiService = _RecordingApiService(
        getValue: {
          'success': true,
          'data': {
            'products': [_productJson(id: 'liked-product')],
          },
          'meta': {
            'limit': 50,
            'nextCursor': null,
            'hasMore': false,
          },
        },
      );
      final repository = ProductRepository(apiService);

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'liked-product');
      expect(apiService.lastGetEndpoint, ApiEndpoints.likedProducts);
      expect(apiService.lastQueryParameters, {'limit': 50});
    });

    test('returns an empty list for an empty API product list', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          getValue: {
            'success': true,
            'data': {'products': <dynamic>[]},
          },
        ),
      );

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('returns an empty list for a success response without products', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          getValue: {
            'success': true,
            'data': <String, dynamic>{},
          },
        ),
      );

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isEmpty);
    });

    test('skips malformed and duplicate products without failing the page', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          getValue: {
            'success': true,
            'data': {
              'products': [
                _productJson(id: 'valid-product'),
                const {'id': 'malformed-product'},
                _productJson(id: 'valid-product'),
                'not-a-product',
              ],
            },
          },
        ),
      );

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, hasLength(1));
      expect(result.value!.single.id, 'valid-product');
    });

    test('propagates API service failures', () async {
      final repository = ProductRepository(
        _RecordingApiService(getError: 'Network unavailable'),
      );

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Network unavailable');
    });

    test('rejects unsuccessful API response envelopes', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          getValue: const {
            'success': false,
            'message': 'Unable to fetch liked products',
          },
        ),
      );

      final result = await repository.fetchLikedProducts();

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });
  });

  group('ProductRepository like updates', () {
    test('likes a product through the API', () async {
      final apiService = _RecordingApiService(
        postValue: const {
          'success': true,
          'data': {'liked': true},
        },
      );
      final repository = ProductRepository(apiService);

      final result = await repository.likeProduct(_product());

      expect(result.isSuccess, isTrue);
      expect(
        apiService.lastPostEndpoint,
        ApiEndpoints.productLike('liked-product'),
      );
      expect(apiService.lastPostData, {'like': true});
    });

    test('unlikes a product through the same API endpoint', () async {
      final apiService = _RecordingApiService(
        postValue: const {
          'success': true,
          'data': {'liked': false},
        },
      );
      final repository = ProductRepository(apiService);

      final result = await repository.unlikeProduct('liked-product');

      expect(result.isSuccess, isTrue);
      expect(
        apiService.lastPostEndpoint,
        ApiEndpoints.productLike('liked-product'),
      );
      expect(apiService.lastPostData, {'like': false});
    });

    test('does not call the API for an invalid product ID', () async {
      final apiService = _RecordingApiService();
      final repository = ProductRepository(apiService);

      final result = await repository.unlikeProduct('invalid/id');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid product ID.');
      expect(apiService.postCount, 0);
    });

    test('propagates API service failures', () async {
      final repository = ProductRepository(
        _RecordingApiService(postError: 'Request failed'),
      );

      final result = await repository.likeProduct(_product());

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Request failed');
    });

    test('rejects a response that does not confirm the requested state', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          postValue: const {
            'success': true,
            'data': {'liked': false},
          },
        ),
      );

      final result = await repository.likeProduct(_product());

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });
  });
}

Product _product() {
  return Product(
    id: 'liked-product',
    name: 'Liked item',
    description: 'A liked test product',
    quality: 'GOOD',
    productImages: const [AppImages.product1],
    donation: 7,
    price: 7,
    securityFee: 1,
    likes: 1,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

Map<String, dynamic> _productJson({required String id}) {
  return {
    'id': id,
    'name': 'Liked item',
    'description': 'A liked test product',
    'quality': 'GOOD',
    'product_images': ['https://example.com/liked-item.jpg'],
    'donation': 7,
    'price': 7,
    'securityFee': 1,
    'likes': 1,
    'number': 1,
    'size': 'M',
    'postageSize': 'small',
    'categoryId': 'category-1',
    'charityId': 'charity-1',
  };
}
