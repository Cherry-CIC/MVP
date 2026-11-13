import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubGetApiService implements ApiService {
  _StubGetApiService(this.responses);

  final Map<String, Result<dynamic>> responses;
  final List<String> requestedEndpoints = [];

  @override
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requestedEndpoints.add(endpoint);
    final response = responses[endpoint];
    if (response == null) {
      return Result.failure('Not found', statusCode: 404);
    }
    if (!response.isSuccess) {
      return Result.failure(
        response.error ?? 'Error',
        statusCode: response.statusCode,
      );
    }
    return Result.success(response.value as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _productJson({
  required String id,
  required String name,
  required String charityId,
  String status = 'active',
  int number = 1,
}) => {
  'id': id,
  'userId': 'seller-1',
  'name': name,
  'description': 'Description for $name',
  'quality': 'Great',
  'product_images': [AppImages.product1],
  'donation': 3.0,
  'price': 3.0,
  'securityFee': 0.30,
  'likes': 3,
  'number': number,
  'size': 'M',
  'postageSize': 'small',
  'charityId': charityId,
  'status': status,
};

void main() {
  test('parses charity metadata with image_url and Firestore timestamps', () async {
    final api = _StubGetApiService({
      ApiEndpoints.charityById('dogs-trust'): Result.success({
        'success': true,
        'data': {
          'id': 'dogs-trust',
          'name': 'Dogs Trust',
          'image_url': AppImages.mind,
          'description': 'Dogs Trust mission',
          'createdAt': {'_seconds': 1704067200, '_nanoseconds': 0},
          'updatedAt': '2026-01-01T00:00:00.000Z',
        },
      }),
    });

    final repo = CharityProfileRepository(api);
    final result = await repo.fetchCharity(charityId: 'dogs-trust');

    expect(result.isSuccess, isTrue);
    expect(result.value?.id, 'dogs-trust');
    expect(result.value?.name, 'Dogs Trust');
    expect(result.value?.imageUrl, AppImages.mind);
    expect(result.value?.description, 'Dogs Trust mission');
  });

  test('resolves charity by name when only charityName is available', () async {
    final api = _StubGetApiService({
      ApiEndpoints.charities: Result.success({
        'success': true,
        'data': [
          {
            'id': 'mind-uk',
            'name': 'Mind',
            'imageUrl': AppImages.mind,
          },
          {
            'id': 'dogs-trust',
            'name': 'Dogs Trust',
            'image_url': AppImages.wwf,
            'description': 'Helping every dog.',
          },
        ],
      }),
    });

    final repo = CharityProfileRepository(api);
    final result = await repo.fetchCharity(charityName: ' dogs   trust ');

    expect(result.isSuccess, isTrue);
    expect(result.value?.id, 'dogs-trust');
    expect(result.value?.description, 'Helping every dog.');
  });

  test('filters fetchProducts strictly by charityId, active status, and pagination metadata', () async {
    final charity = Charity(
      id: 'dogs-trust',
      name: 'Dogs Trust',
      imageUrl: AppImages.mind,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final api = _StubGetApiService({
      '${ApiEndpoints.charityProducts('dogs-trust')}?limit=20': Result.success({
        'success': true,
        'data': {
          'products': [
            _productJson(id: 'p-dogs', name: 'Dogs Jacket', charityId: 'dogs-trust'),
            _productJson(id: 'p-mind', name: 'Mind Scarf', charityId: 'mind-uk'),
            _productJson(id: 'p-sold', name: 'Sold Tee', charityId: 'dogs-trust', status: 'sold'),
            _productJson(id: 'p-zero', name: 'Empty Tee', charityId: 'dogs-trust', number: 0),
          ],
        },
        'meta': {
          'limit': 20,
          'nextCursor': 'cursor-page-2',
          'hasMore': true,
        },
      }),
    });

    final repo = CharityProfileRepository(api);
    final result = await repo.fetchProducts(charity);

    expect(result.isSuccess, isTrue);
    expect(result.value?.products.map((p) => p.id), ['p-dogs']);
    expect(result.value?.nextCursor, 'cursor-page-2');
    expect(result.value?.hasMore, isTrue);
  });

  test('falls back to productsWithDetails when /api/charities/:id/products route is 404', () async {
    final charity = Charity(
      id: 'dogs-trust',
      name: 'Dogs Trust',
      imageUrl: AppImages.mind,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final api = _StubGetApiService({
      '${ApiEndpoints.charityProducts('dogs-trust')}?limit=20': Result.failure(
        'Cannot GET /api/charities/dogs-trust/products',
        statusCode: 404,
      ),
      '${ApiEndpoints.productsWithDetails}?limit=50': Result.success({
        'success': true,
        'data': {
          'products': [
            _productJson(id: 'p-dogs-fallback', name: 'Fallback Item', charityId: 'dogs-trust'),
            _productJson(id: 'p-other-fallback', name: 'Other Charity Item', charityId: 'wwf'),
          ],
        },
        'meta': {
          'limit': 50,
          'nextCursor': null,
          'hasMore': false,
        },
      }),
    });

    final repo = CharityProfileRepository(api);
    final result = await repo.fetchProducts(charity);

    expect(result.isSuccess, isTrue);
    expect(result.value?.products.map((p) => p.id), ['p-dogs-fallback']);
    expect(api.requestedEndpoints, [
      '${ApiEndpoints.charityProducts('dogs-trust')}?limit=20',
      '${ApiEndpoints.productsWithDetails}?limit=50',
    ]);
  });

  test('resolveDescription prefers API description, then DiscoverRepository, then default text', () {
    final withDesc = Charity(
      id: 'c1',
      name: 'British Red Cross',
      imageUrl: AppImages.mind,
      description: 'Official Firebase description',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final withoutDesc = Charity(
      id: 'c2',
      name: 'British Red Cross',
      imageUrl: AppImages.mind,
      description: '   ',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    final unknownCharity = Charity(
      id: 'c3',
      name: 'Unknown Charity',
      imageUrl: AppImages.mind,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

    expect(
      CharityProfileRepository.resolveDescription(withDesc),
      'Official Firebase description',
    );
    expect(
      CharityProfileRepository.resolveDescription(withoutDesc),
      DiscoverRepository().descriptionForCharityName('British Red Cross'),
    );
    expect(
      CharityProfileRepository.resolveDescription(unknownCharity),
      AppStrings.charityProfileNoDescription,
    );
  });
}
