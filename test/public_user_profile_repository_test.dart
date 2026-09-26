import 'dart:convert';

import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _privateMarker = 'PRIVATE_DATA_MUST_NOT_SURVIVE';

class _FakeApiService implements ApiService {
  _FakeApiService({
    this.profileResponse,
    this.productsResponse,
    this.profileStatusCode,
    this.productsStatusCode,
    this.throws = false,
  });

  final dynamic profileResponse;
  final dynamic productsResponse;
  final int? profileStatusCode;
  final int? productsStatusCode;
  final bool throws;
  final endpoints = <String>[];
  final queryParameters = <Map<String, dynamic>?>[];

  int get calls => endpoints.length;
  String? get lastEndpoint => endpoints.isEmpty ? null : endpoints.last;
  Map<String, dynamic>? get lastQueryParameters => queryParameters.isEmpty ? null : queryParameters.last;

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    endpoints.add(endpoint);
    this.queryParameters.add(queryParameters);
    if (throws) throw StateError(_privateMarker);

    final isProfile = endpoint.endsWith('/profile');
    final statusCode = isProfile ? profileStatusCode : productsStatusCode;
    final response = isProfile ? profileResponse : productsResponse;
    if (statusCode != null || response == null) {
      return Result.failure(_privateMarker, statusCode: statusCode);
    }
    return Result.success(response as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PublicUserProfileRepository', () {
    test('uses the encoded split profile and products endpoints with cursor query', () async {
      const userId = 'user +#?';
      final api = _FakeApiService(
        profileResponse: _profileResponse(userId: userId),
        productsResponse: _productsResponse(userId: userId, nextCursor: 'next-page'),
      );
      final result = await PublicUserProfileRepository(api).fetchProfile(
        ' $userId ',
        limit: 10,
        cursor: ' previous-page ',
      );

      expect(result.isSuccess, isTrue);
      expect(api.endpoints, [
        '/api/users/user%20%2B%23%3F/profile',
        '/api/users/user%20%2B%23%3F/products',
      ]);
      expect(api.endpoints, isNot(contains(ApiEndpoints.myProducts)));
      expect(api.queryParameters, [
        null,
        {'limit': 10, 'cursor': 'previous-page'},
      ]);
      expect(result.value!.user.id, userId);
      expect(result.value!.products.single.userId, userId);
      expect(result.value!.products.single.price, 12.5);
      expect(result.value!.nextCursor, 'next-page');
      expect(result.value!.hasMore, isTrue);
    });

    test('uses default pagination and omits blank cursors', () async {
      final api = _FakeApiService(
        profileResponse: _profileResponse(),
        productsResponse: _productsResponse(products: []),
      );
      final result = await PublicUserProfileRepository(api).fetchProfile('seller', cursor: '  ');

      expect(result.isSuccess, isTrue);
      expect(api.lastQueryParameters, {'limit': 20});
      expect(result.value!.products, isEmpty);
      expect(result.value!.nextCursor, isNull);
      expect(result.value!.hasMore, isFalse);
    });

    test('does not request malformed or anonymised user identifiers', () async {
      for (final userId in ['', '   ', 'bad/id', r'bad\id', '.', '..', 'deleted_user', 'bad\nidentity']) {
        final api = _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(),
        );
        final result = await PublicUserProfileRepository(api).fetchProfile(userId);
        expect(result.isSuccess, isFalse, reason: userId);
        expect(result.statusCode, 404, reason: userId);
        expect(api.calls, 0, reason: userId);
      }
    });

    test('rejects unbounded page limits before making a request', () async {
      for (final limit in [-1, 0, 51, 1000]) {
        final api = _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(),
        );
        final result = await PublicUserProfileRepository(api).fetchProfile('seller', limit: limit);
        expect(result.isSuccess, isFalse);
        expect(api.calls, 0);
      }
      for (final limit in [1, 50]) {
        final api = _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(),
        );
        expect((await PublicUserProfileRepository(api).fetchProfile('seller', limit: limit)).isSuccess, isTrue);
        expect(api.lastQueryParameters!['limit'], limit);
      }
    });

    test('projects public account and listing fields without retaining private relations', () async {
      final profileResponse = _profileResponse();
      final user = profileResponse['data'] as Map<String, dynamic>;
      user.addAll({
        'email': _privateMarker,
        'address': {'postcode': _privateMarker},
        'authentication': {'token': _privateMarker},
        'settings': {'private': _privateMarker},
      });
      final productsResponse = _productsResponse();
      final product = productsResponse['data']['products'][0] as Map<String, dynamic>;
      product.addAll({
        'user': user,
        'shippingAddress': _privateMarker,
        'authentication': _privateMarker,
        'category': _publicRelation('category')..['private'] = _privateMarker,
        'charity': _publicRelation('charity')..['private'] = _privateMarker,
      });

      final result = await PublicUserProfileRepository(
        _FakeApiService(profileResponse: profileResponse, productsResponse: productsResponse),
      ).fetchProfile('seller');
      final page = result.value!;
      final publicProjection = {
        'id': page.user.id,
        'username': page.user.username,
        'profileImageUrl': page.user.profileImageUrl,
        'products': page.products.map((product) => product.toJson()).toList(),
      };

      expect(result.isSuccess, isTrue);
      expect(page.user.username, 'Public seller');
      expect(page.user.profileImageUrl, 'https://example.test/avatar.jpg');
      expect(page.products.single.charity!.name, 'Public charity');
      expect(page.products.single.category!.name, 'Public category');
      expect(jsonEncode(publicProjection), isNot(contains(_privateMarker)));
      expect(() => page.products.clear(), throwsUnsupportedError);
      expect(() => page.products.single.productImages.clear(), throwsUnsupportedError);
    });

    test('rejects a profile response for another user rather than displaying it', () async {
      final result = await PublicUserProfileRepository(
        _FakeApiService(
          profileResponse: _profileResponse(userId: 'other'),
          productsResponse: _productsResponse(),
        ),
      ).fetchProfile('seller');
      expect(result.isSuccess, isFalse);
      expect(result.value, isNull);
    });

    test('excludes wrong owners, inactive and unavailable stock while accepting backend-filtered products', () async {
      final invalidProducts = <dynamic>[
        _product('wrong-owner', userId: 'other'),
        for (final status in ['draft', 'pending', 'removed', 'sold', 'suspended'])
          _product(status)..['status'] = status,
        _product('no-owner')..remove('userId'),
        _product('sold-out')..['number'] = 0,
        _product('fractional-stock')..['number'] = 1.5,
        _product('valid')..remove('visibility'),
        _product('valid'),
        'not a product',
      ];
      final result = await PublicUserProfileRepository(
        _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(products: invalidProducts),
        ),
      ).fetchProfile('seller');

      expect(result.isSuccess, isTrue);
      expect(result.value!.products.map((product) => product.id), ['valid']);
    });

    test('rejects unsafe prices and incomplete detail or checkout payloads', () async {
      final products = <dynamic>[
        for (final price in [-1, double.infinity, double.nan, 'not a price', null])
          _product('bad-price-$price')..['price'] = price,
        for (final field in [
          'description',
          'quality',
          'size',
          'postageSize',
          'donation',
          'likes',
          'number',
          'product_images',
        ])
          _product('missing-$field')..remove(field),
        _product('negative-fee')..['securityFee'] = -2,
        _product('bad-donation')..['donation'] = double.infinity,
        _product('valid'),
      ];
      final result = await PublicUserProfileRepository(
        _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(products: products),
        ),
      ).fetchProfile('seller');

      expect(result.isSuccess, isTrue);
      expect(result.value!.products.map((product) => product.id), ['valid']);
    });

    test('discards non-web images and credential-bearing URLs', () async {
      final profileResponse = _profileResponse()..['data']['profileImageUrl'] = 'data:image/png;base64,private';
      final productsResponse = _productsResponse(
        products: [
          _product('valid')
            ..['product_images'] = [
              'https://example.test/item.jpg',
              'file:///private/photo.jpg',
              'https://private:password@example.test/photo.jpg',
              'javascript:alert(1)',
              123,
            ],
        ],
      );
      final result = await PublicUserProfileRepository(
        _FakeApiService(profileResponse: profileResponse, productsResponse: productsResponse),
      ).fetchProfile('seller');

      expect(result.value!.user.profileImageUrl, isNull);
      expect(result.value!.products.single.productImages, ['https://example.test/item.jpg']);
    });

    test('rejects malformed profile envelopes and users', () async {
      final malformed = <dynamic>[
        'not json',
        <String, dynamic>{},
        _profileResponse()..['success'] = false,
        _profileResponse()..remove('success'),
        _profileResponse()..['data'] = [],
        _profileResponse()..['data']['id'] = 'other',
        _profileResponse()..['data']['username'] = ' ',
        _profileResponse()..['data']['profileImageUrl'] = 123,
      ];
      for (final response in malformed) {
        final api = _FakeApiService(profileResponse: response, productsResponse: _productsResponse());
        final result = await PublicUserProfileRepository(api).fetchProfile('seller');
        expect(result.isSuccess, isFalse, reason: '$response');
        expect(result.value, isNull);
        expect(result.error, isNot(contains(_privateMarker)));
        expect(api.calls, 1);
      }
    });

    test('rejects malformed product envelopes and pagination', () async {
      final malformed = <dynamic>[
        'not json',
        <String, dynamic>{},
        _productsResponse()..['success'] = false,
        _productsResponse()..remove('success'),
        _productsResponse()..['data'] = [],
        _productsResponse()..['meta'] = null,
        _productsResponse()..['data']['products'] = {},
        _productsResponse()..['meta']['hasMore'] = 'true',
        _productsResponse()..['meta']['limit'] = 51,
        _productsResponse()..['meta']['limit'] = '20',
        _productsResponse()..['meta']['nextCursor'] = 123,
        _productsResponse()..['meta'].remove('nextCursor'),
        _productsResponse()..['meta']['hasMore'] = true,
        _productsResponse(nextCursor: 'next')..['meta']['hasMore'] = false,
      ];
      for (final response in malformed) {
        final result = await PublicUserProfileRepository(
          _FakeApiService(profileResponse: _profileResponse(), productsResponse: response),
        ).fetchProfile('seller');
        expect(result.isSuccess, isFalse, reason: '$response');
        expect(result.value, isNull);
        expect(result.error, isNot(contains(_privateMarker)));
      }
    });

    test('rejects a cursor that would repeat the current page', () async {
      final repository = PublicUserProfileRepository(
        _FakeApiService(
          profileResponse: _profileResponse(),
          productsResponse: _productsResponse(nextCursor: 'current'),
        ),
      );
      final result = await repository.fetchProfile('seller', cursor: ' current ');
      expect(result.isSuccess, isFalse);
    });

    test('preserves missing and deleted HTTP status without exposing backend errors', () async {
      for (final status in [404, 410]) {
        final profileResult = await PublicUserProfileRepository(
          _FakeApiService(profileStatusCode: status, productsResponse: _productsResponse()),
        ).fetchProfile('seller');
        expect(profileResult.isSuccess, isFalse);
        expect(profileResult.statusCode, status);
        expect(profileResult.error, 'This profile is unavailable.');

        final productsResult = await PublicUserProfileRepository(
          _FakeApiService(profileResponse: _profileResponse(), productsStatusCode: status),
        ).fetchProfile('seller');
        expect(productsResult.isSuccess, isFalse);
        expect(productsResult.statusCode, status);
        expect(productsResult.error, 'This profile is unavailable.');
      }
    });

    test('uses fixed safe copy for network, service and exception failures', () async {
      for (final api in [
        _FakeApiService(productsResponse: _productsResponse()),
        _FakeApiService(profileResponse: _profileResponse(), productsStatusCode: 500),
        _FakeApiService(profileStatusCode: 401, productsResponse: _productsResponse()),
        _FakeApiService(profileResponse: _profileResponse(), productsResponse: _productsResponse(), throws: true),
      ]) {
        final result = await PublicUserProfileRepository(api).fetchProfile('seller');
        expect(result.isSuccess, isFalse);
        expect(result.error, 'Could not load this profile. Please try again.');
        expect(result.error, isNot(contains(_privateMarker)));
      }
    });
  });
}

Map<String, dynamic> _profileResponse({String userId = 'seller'}) {
  return {
    'success': true,
    'data': <String, dynamic>{
      'id': userId,
      'username': 'Public seller',
      'profileImageUrl': 'https://example.test/avatar.jpg',
    },
  };
}

Map<String, dynamic> _productsResponse({String userId = 'seller', List<dynamic>? products, String? nextCursor}) {
  return {
    'success': true,
    'data': <String, dynamic>{
      'products': products ?? [_product('listing', userId: userId)],
    },
    'meta': <String, dynamic>{'limit': 20, 'nextCursor': nextCursor, 'hasMore': nextCursor != null},
  };
}

Map<String, dynamic> _product(String id, {String userId = 'seller'}) => {
  'id': id,
  'userId': userId,
  'name': 'Public shirt',
  'description': 'A pre-loved shirt',
  'quality': 'GOOD',
  'product_images': ['https://example.test/item.jpg'],
  'donation': 12.5,
  'price': '12.50',
  'securityFee': 1,
  'likes': 0,
  'number': 1,
  'size': 'M',
  'postageSize': 'small',
  'categoryId': 'category',
  'charityId': 'charity',
  'status': 'active',
};

Map<String, dynamic> _publicRelation(String kind) => {
  'id': kind,
  'name': 'Public $kind',
  'imageUrl': 'https://example.test/$kind.jpg',
  'createdAt': '2026-09-01T00:00:00Z',
  'updatedAt': '2026-09-01T00:00:00Z',
};
