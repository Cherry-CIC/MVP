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
    this.getException,
    this.postValue,
    this.postError,
  });

  final dynamic getValue;
  final String? getError;
  final Object? getException;
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
    if (getException != null) {
      throw getException!;
    }
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
  group('ProductRepository.fetchProduct', () {
    test(
      'loads the requested listing with its owner and full details',
      () async {
        final categoryJson = {
          'id': 'category-1',
          'name': 'Tops',
          'imageUrl': 'https://example.com/category.jpg',
          'createdAt': '2026-09-01T00:00:00.000Z',
          'updatedAt': '2026-09-02T00:00:00.000Z',
        };
        final charityJson = {
          'id': 'charity-1',
          'name': 'Test charity',
          'imageUrl': 'https://example.com/charity.jpg',
          'description': 'The chosen charity',
          'website': 'https://example.com/charity',
          'createdAt': '2026-09-01T00:00:00.000Z',
          'updatedAt': '2026-09-02T00:00:00.000Z',
        };
        final apiService = _RecordingApiService(
          getValue: {
            'success': true,
            'data': {
              ..._productJson(id: 'requested-product'),
              'user_id': 'listing-owner',
              'category': categoryJson,
              'charity': charityJson,
              'createdAt': '2026-09-01T00:00:00.000Z',
              'updatedAt': '2026-09-02T00:00:00.000Z',
            },
          },
        );
        final repository = ProductRepository(apiService);

        final result = await repository.fetchProduct('requested-product');

        expect(result.isSuccess, isTrue);
        final product = result.value!;
        expect(product.id, 'requested-product');
        expect(product.userId, 'listing-owner');
        expect(product.name, 'Liked item');
        expect(product.description, 'A liked test product');
        expect(product.quality, 'GOOD');
        expect(product.productImages, ['https://example.com/liked-item.jpg']);
        expect(product.donation, 7);
        expect(product.price, 7);
        expect(product.securityFee, 1);
        expect(product.likes, 1);
        expect(product.number, 1);
        expect(product.size, 'M');
        expect(product.postageSizeId, 'small');
        expect(product.categoryId, 'category-1');
        expect(product.charityId, 'charity-1');
        expect(product.category!.toJson(), categoryJson);
        expect(product.charity!.toJson(), charityJson);
        expect(product.createdAt, '2026-09-01T00:00:00.000Z');
        expect(product.updatedAt, '2026-09-02T00:00:00.000Z');
        expect(
          apiService.lastGetEndpoint,
          ApiEndpoints.productWithDetailsById('requested-product'),
        );
        expect(apiService.lastQueryParameters, isNull);
      },
    );

    test('loads a listing when its optional description is absent', () async {
      final json = _productJson(id: 'requested-product')..remove('description');
      final repository = ProductRepository(
        _RecordingApiService(getValue: {'success': true, 'data': json}),
      );

      final result = await repository.fetchProduct('requested-product');

      expect(result.isSuccess, isTrue);
      expect(result.value!.id, 'requested-product');
      expect(result.value!.description, isEmpty);
    });

    for (final productId in ['', '   ', 'invalid/id']) {
      test('does not request an invalid listing ID "$productId"', () async {
        final apiService = _RecordingApiService();
        final repository = ProductRepository(apiService);

        final result = await repository.fetchProduct(productId);

        expect(result.isSuccess, isFalse);
        expect(result.error, 'Invalid product ID.');
        expect(apiService.lastGetEndpoint, isNull);
      });
    }

    test('propagates API service failures', () async {
      final repository = ProductRepository(
        _RecordingApiService(getError: 'Network unavailable'),
      );

      final result = await repository.fetchProduct('requested-product');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Network unavailable');
    });

    test('returns a safe failure when the API service throws', () async {
      final repository = ProductRepository(
        _RecordingApiService(getException: StateError('Request failed')),
      );

      final result = await repository.fetchProduct('requested-product');

      expect(result.isSuccess, isFalse);
      expect(result.error, 'We couldn’t load this listing.');
    });

    final invalidResponses = <String, dynamic>{
      'failed response': {'success': false},
      'missing success confirmation': {
        'data': _productJson(id: 'requested-product'),
      },
      'missing response': null,
      'non-map response': 'invalid',
      'missing product': {'success': true},
      'non-map product': {'success': true, 'data': <dynamic>[]},
      'malformed product': {
        'success': true,
        'data': {'id': 'requested-product'},
      },
      'non-text description': {
        'success': true,
        'data': {..._productJson(id: 'requested-product'), 'description': 123},
      },
      'different listing': {
        'success': true,
        'data': _productJson(id: 'different-product'),
      },
    };

    for (final response in invalidResponses.entries) {
      test('rejects a ${response.key}', () async {
        final repository = ProductRepository(
          _RecordingApiService(getValue: response.value),
        );

        final result = await repository.fetchProduct('requested-product');

        expect(result.isSuccess, isFalse);
        expect(result.value, isNull);
        expect(result.error, 'We couldn’t load this listing.');
      });
    }
  });

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
          'data': {'liked': true, 'likes': 2},
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
      expect(result.value!.liked, isTrue);
      expect(result.value!.likes, 2);
    });

    test('unlikes a product through the same API endpoint', () async {
      final apiService = _RecordingApiService(
        postValue: const {
          'success': true,
          'data': {'liked': false, 'likes': 0},
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
      expect(result.value!.liked, isFalse);
      expect(result.value!.likes, 0);
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
            'data': {'liked': false, 'likes': 0},
          },
        ),
      );

      final result = await repository.likeProduct(_product());

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });

    test('rejects a response without an authoritative like count', () async {
      final repository = ProductRepository(
        _RecordingApiService(
          postValue: const {
            'success': true,
            'data': {'liked': true},
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
