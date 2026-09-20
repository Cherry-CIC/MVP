import 'dart:convert';

import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _privateMarker = 'PRIVATE_DATA_MUST_NOT_SURVIVE';

class _FakeApiService implements ApiService {
  _FakeApiService(this.response, {this.statusCode, this.throws = false});

  final dynamic response;
  final int? statusCode;
  final bool throws;
  String? lastEndpoint;
  Map<String, dynamic>? lastQueryParameters;
  int calls = 0;

  @override
  Future<Result<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    calls++;
    lastEndpoint = endpoint;
    lastQueryParameters = queryParameters;
    if (throws) throw StateError(_privateMarker);
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
    test('uses the encoded public user endpoint and cursor query', () async {
      const userId = 'user +#?';
      final api = _FakeApiService(_response(userId: userId, nextCursor: 'next-page'));
      final result = await PublicUserProfileRepository(api).fetchProfile(
        ' $userId ',
        limit: 10,
        cursor: ' previous-page ',
      );

      expect(result.isSuccess, isTrue);
      expect(api.lastEndpoint, '/api/users/user%20%2B%23%3F/public-profile');
      expect(api.lastEndpoint, isNot(ApiEndpoints.myProducts));
      expect(api.lastQueryParameters, {'limit': 10, 'cursor': 'previous-page'});
      expect(result.value!.user.id, userId);
      expect(result.value!.products.single.userId, userId);
      expect(result.value!.products.single.price, 12.5);
      expect(result.value!.nextCursor, 'next-page');
      expect(result.value!.hasMore, isTrue);
    });

    test('uses default pagination and omits blank cursors', () async {
      final api = _FakeApiService(_response(products: []));
      final result = await PublicUserProfileRepository(api).fetchProfile('seller', cursor: '  ');

      expect(result.isSuccess, isTrue);
      expect(api.lastQueryParameters, {'limit': 20});
      expect(result.value!.products, isEmpty);
      expect(result.value!.nextCursor, isNull);
      expect(result.value!.hasMore, isFalse);
    });

    test('does not request malformed or anonymised user identifiers', () async {
      for (final userId in ['', '   ', 'bad/id', r'bad\id', '.', '..', 'deleted_user', 'bad\nidentity']) {
        final api = _FakeApiService(_response());
        final result = await PublicUserProfileRepository(api).fetchProfile(userId);
        expect(result.isSuccess, isFalse, reason: userId);
        expect(result.statusCode, 404, reason: userId);
        expect(api.calls, 0, reason: userId);
      }
    });

    test('rejects unbounded page limits before making a request', () async {
      for (final limit in [-1, 0, 51, 1000]) {
        final api = _FakeApiService(_response());
        final result = await PublicUserProfileRepository(api).fetchProfile('seller', limit: limit);
        expect(result.isSuccess, isFalse);
        expect(api.calls, 0);
      }
      for (final limit in [1, 50]) {
        final api = _FakeApiService(_response());
        expect((await PublicUserProfileRepository(api).fetchProfile('seller', limit: limit)).isSuccess, isTrue);
        expect(api.lastQueryParameters!['limit'], limit);
      }
    });

    test('projects public account and listing fields without retaining private relations', () async {
      final response = _response();
      final user = response['data']['user'] as Map<String, dynamic>;
      user.addAll({
        'email': _privateMarker,
        'address': {'postcode': _privateMarker},
        'authentication': {'token': _privateMarker},
        'settings': {'private': _privateMarker},
      });
      final product = response['data']['products'][0] as Map<String, dynamic>;
      product.addAll({
        'user': user,
        'shippingAddress': _privateMarker,
        'authentication': _privateMarker,
        'category': _publicRelation('category')..['private'] = _privateMarker,
        'charity': _publicRelation('charity')..['private'] = _privateMarker,
      });

      final result = await PublicUserProfileRepository(_FakeApiService(response)).fetchProfile('seller');
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

    test('rejects a response for another user rather than displaying it', () async {
      final result = await PublicUserProfileRepository(
        _FakeApiService(_response(userId: 'other')),
      ).fetchProfile('seller');
      expect(result.isSuccess, isFalse);
      expect(result.value, isNull);
    });

    test('excludes wrong owners, inactive, private, missing visibility and unavailable stock', () async {
      final invalidProducts = <dynamic>[
        _product('wrong-owner', userId: 'other'),
        for (final status in ['draft', 'pending', 'removed', 'sold', 'suspended'])
          _product(status)..['status'] = status,
        _product('private')..['visibility'] = 'private',
        _product('missing-visibility')..remove('visibility'),
        _product('no-owner')..remove('userId'),
        _product('sold-out')..['number'] = 0,
        _product('fractional-stock')..['number'] = 1.5,
        _product('valid'),
        _product('valid'),
        'not a product',
      ];
      final result = await PublicUserProfileRepository(
        _FakeApiService(_response(products: invalidProducts)),
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
        _FakeApiService(_response(products: products)),
      ).fetchProfile('seller');

      expect(result.isSuccess, isTrue);
      expect(result.value!.products.map((product) => product.id), ['valid']);
    });

    test('discards non-web images and credential-bearing URLs', () async {
      final response = _response(
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
      response['data']['user']['profileImageUrl'] = 'data:image/png;base64,private';
      final result = await PublicUserProfileRepository(_FakeApiService(response)).fetchProfile('seller');

      expect(result.value!.user.profileImageUrl, isNull);
      expect(result.value!.products.single.productImages, ['https://example.test/item.jpg']);
    });

    test('rejects malformed envelopes, users and pagination', () async {
      final malformed = <dynamic>[
        'not json',
        <String, dynamic>{},
        _response()..['success'] = false,
        _response()..remove('success'),
        _response()..['data'] = [],
        _response()..['meta'] = null,
        _response()..['data']['user'] = null,
        _response()..['data']['user']['username'] = ' ',
        _response()..['data']['user']['profileImageUrl'] = 123,
        _response()..['data']['products'] = {},
        _response()..['meta']['hasMore'] = 'true',
        _response()..['meta']['limit'] = 51,
        _response()..['meta']['limit'] = '20',
        _response()..['meta']['nextCursor'] = 123,
        _response()..['meta'].remove('nextCursor'),
        _response()..['meta']['hasMore'] = true,
        _response(nextCursor: 'next')..['meta']['hasMore'] = false,
      ];
      for (final response in malformed) {
        final result = await PublicUserProfileRepository(_FakeApiService(response)).fetchProfile('seller');
        expect(result.isSuccess, isFalse, reason: '$response');
        expect(result.value, isNull);
        expect(result.error, isNot(contains(_privateMarker)));
      }
    });

    test('rejects a cursor that would repeat the current page', () async {
      final repository = PublicUserProfileRepository(_FakeApiService(_response(nextCursor: 'current')));
      final result = await repository.fetchProfile('seller', cursor: ' current ');
      expect(result.isSuccess, isFalse);
    });

    test('preserves missing and deleted HTTP status without exposing backend errors', () async {
      for (final status in [404, 410]) {
        final result = await PublicUserProfileRepository(
          _FakeApiService(null, statusCode: status),
        ).fetchProfile('seller');
        expect(result.isSuccess, isFalse);
        expect(result.statusCode, status);
        expect(result.error, 'This profile is unavailable.');
      }
    });

    test('uses fixed safe copy for network, service and exception failures', () async {
      for (final api in [
        _FakeApiService(null),
        _FakeApiService(null, statusCode: 500),
        _FakeApiService(null, statusCode: 401),
        _FakeApiService(null, throws: true),
      ]) {
        final result = await PublicUserProfileRepository(api).fetchProfile('seller');
        expect(result.isSuccess, isFalse);
        expect(result.error, 'Could not load this profile. Please try again.');
        expect(result.error, isNot(contains(_privateMarker)));
      }
    });
  });
}

Map<String, dynamic> _response({String userId = 'seller', List<dynamic>? products, String? nextCursor}) {
  return {
    'success': true,
    'data': <String, dynamic>{
      'user': <String, dynamic>{
        'id': userId,
        'username': 'Public seller',
        'profileImageUrl': 'https://example.test/avatar.jpg',
      },
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
  'visibility': 'public',
};

Map<String, dynamic> _publicRelation(String kind) => {
  'id': kind,
  'name': 'Public $kind',
  'imageUrl': 'https://example.test/$kind.jpg',
  'createdAt': '2026-09-01T00:00:00Z',
  'updatedAt': '2026-09-01T00:00:00Z',
};
