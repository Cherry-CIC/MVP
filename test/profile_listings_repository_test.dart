import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiService implements ApiService {
  final dynamic response;
  final String? error;

  String? lastEndpoint;
  Map<String, dynamic>? lastQueryParameters;

  _FakeApiService.success(this.response) : error = null;

  _FakeApiService.failure(this.error) : response = null;

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastEndpoint = endpoint;
    lastQueryParameters = queryParameters;

    if (error != null) {
      return Result.failure(error);
    }
    return Result.success(response as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileListingsRepository', () {
    test('uses the authenticated my-products endpoint and parses pagination', () async {
      final apiService = _FakeApiService.success({
        'success': true,
        'data': {
          'products': [
            _listingJson(
              id: 'listing-1',
              price: '12.50',
              imagesKey: 'images',
            ),
          ],
        },
        'meta': {
          'limit': '20',
          'nextCursor': 'cursor-2',
          'hasMore': true,
        },
      });
      final repository = ProfileListingsRepository(apiService);

      final result = await repository.fetchListings(
        limit: 20,
        cursor: ' cursor-1 ',
      );

      expect(result.isSuccess, isTrue);
      expect(apiService.lastEndpoint, ApiEndpoints.myProducts);
      expect(apiService.lastQueryParameters, {
        'limit': 20,
        'cursor': 'cursor-1',
      });
      expect(result.value!.listings, hasLength(1));
      expect(result.value!.listings.single.id, 'listing-1');
      expect(result.value!.listings.single.imageUrls, ['https://example.com/item.jpg']);
      expect(result.value!.listings.single.price, 12.5);
      expect(result.value!.limit, 20);
      expect(result.value!.nextCursor, 'cursor-2');
      expect(result.value!.hasMore, isTrue);
    });

    test('supports legacy data-list responses and omits an empty cursor', () async {
      final apiService = _FakeApiService.success({
        'data': [
          _listingJson(id: 'listing-2'),
        ],
      });
      final repository = ProfileListingsRepository(apiService);

      final result = await repository.fetchListings(cursor: '  ');

      expect(result.isSuccess, isTrue);
      expect(result.value!.listings.single.id, 'listing-2');
      expect(apiService.lastQueryParameters, {'limit': 20});
    });

    test('accepts pagination metadata nested inside data', () async {
      final repository = ProfileListingsRepository(
        _FakeApiService.success({
          'data': {
            'products': [
              _listingJson(id: 'listing-nested-meta'),
            ],
            'meta': {
              'limit': 10,
              'nextCursor': 'nested-cursor',
              'hasMore': true,
            },
          },
        }),
      );

      final result = await repository.fetchListings();

      expect(result.isSuccess, isTrue);
      expect(result.value!.limit, 10);
      expect(result.value!.nextCursor, 'nested-cursor');
      expect(result.value!.hasMore, isTrue);
    });

    test('keeps valid summaries when another product is malformed', () async {
      final repository = ProfileListingsRepository(
        _FakeApiService.success({
          'products': [
            {'name': 'Missing identifier'},
            _listingJson(id: 'listing-3'),
            'not a product',
          ],
        }),
      );

      final result = await repository.fetchListings();

      expect(result.isSuccess, isTrue);
      expect(result.value!.listings, hasLength(1));
      expect(result.value!.listings.single.id, 'listing-3');
    });

    test('returns failure for unsuccessful and malformed envelopes', () async {
      final unsuccessful = ProfileListingsRepository(
        _FakeApiService.success({'success': false}),
      );
      final malformed = ProfileListingsRepository(
        _FakeApiService.success({'message': 'No product data'}),
      );

      expect((await unsuccessful.fetchListings()).isSuccess, isFalse);
      expect((await malformed.fetchListings()).isSuccess, isFalse);
    });

    test('passes through API service failures', () async {
      final repository = ProfileListingsRepository(
        _FakeApiService.failure('technical failure'),
      );

      final result = await repository.fetchListings();

      expect(result.isSuccess, isFalse);
      expect(result.error, 'technical failure');
    });

    test('treats unsafe prices as unavailable', () async {
      final repository = ProfileListingsRepository(
        _FakeApiService.success({
          'data': [
            _listingJson(id: 'negative-price', price: -1),
            _listingJson(id: 'infinite-price', price: double.infinity),
          ],
        }),
      );

      final result = await repository.fetchListings();

      expect(
        result.value!.listings.map((listing) => listing.price),
        [null, null],
      );
    });
  });
}

Map<String, dynamic> _listingJson({
  required String id,
  dynamic price = 12.5,
  String imagesKey = 'product_images',
}) {
  return {
    'id': id,
    'name': 'Example shirt',
    imagesKey: ['https://example.com/item.jpg'],
    'price': price,
  };
}
