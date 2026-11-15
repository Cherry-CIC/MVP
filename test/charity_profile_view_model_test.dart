import 'dart:async';

import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_view_model.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:flutter_test/flutter_test.dart';

Charity _charity({
  String id = 'dogs-trust',
  String name = 'Dogs Trust',
  String? description = 'Dogs Trust cares for dogs.',
}) => Charity(
  id: id,
  name: name,
  imageUrl: AppImages.mind,
  description: description,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

Product _product(String id, String charityId, Charity? charity) => Product(
  id: id,
  userId: 'seller-1',
  name: 'Product $id',
  description: 'Desc $id',
  quality: 'Great',
  productImages: const [AppImages.product1],
  donation: 3,
  price: 3,
  securityFee: 0.3,
  likes: 3,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  charityId: charityId,
  charity: charity,
);

class _FakeCharityProfileRepository implements ICharityProfileRepository {
  _FakeCharityProfileRepository({
    required this.onFetchCharity,
    required this.onFetchProducts,
  });

  final Future<Result<Charity>> Function({
    String? charityId,
    String? charityName,
  }) onFetchCharity;
  final Future<Result<CharityProfilePageData>> Function(
    Charity charity, {
    int limit,
    String? cursor,
  }) onFetchProducts;

  @override
  Future<Result<Charity>> fetchCharity({
    String? charityId,
    String? charityName,
  }) => onFetchCharity(charityId: charityId, charityName: charityName);

  @override
  Future<Result<CharityProfilePageData>> fetchProducts(
    Charity charity, {
    int limit = 20,
    String? cursor,
  }) => onFetchProducts(charity, limit: limit, cursor: cursor);
}

void main() {
  test('isolates listings to target charity, removes deleted items, and paginates', () async {
    final dogs = _charity();
    final deletedListings = DeletedListings();
    final p1 = _product('p1', 'dogs-trust', dogs);
    final wrongCharity = _product('p-wrong', 'other-charity', null);
    final p2 = _product('p2', 'dogs-trust', dogs);

    final repo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async => Result.success(dogs),
      onFetchProducts: (charity, {limit = 20, cursor}) async {
        if (cursor == null) {
          return Result.success(
            CharityProfilePageData(
              charity: charity,
              products: [p1, wrongCharity],
              nextCursor: 'page-2',
              hasMore: true,
            ),
          );
        }
        return Result.success(
          CharityProfilePageData(
            charity: charity,
            products: [p1, p2],
            nextCursor: null,
            hasMore: false,
          ),
        );
      },
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityId: 'dogs-trust'),
      repository: repo,
      deletedListings: deletedListings,
    );

    await vm.loadInitial();
    expect(vm.status, CharityProfileStatus.loaded);
    expect(vm.products.map((p) => p.id), ['p1']);
    expect(vm.hasMore, isTrue);

    await vm.loadMore();
    expect(vm.products.map((p) => p.id), ['p1', 'p2']);
    expect(vm.hasMore, isFalse);

    deletedListings.add('p1');
    expect(vm.products.map((p) => p.id), ['p2']);

    vm.markBlocked();
    expect(vm.status, CharityProfileStatus.blocked);
    expect(vm.products, isEmpty);

    await vm.refresh();
    expect(vm.status, CharityProfileStatus.blocked);
    expect(vm.products, isEmpty);
  });

  test('transitions to unavailable on 404 without initial charity', () async {
    final repo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async =>
          Result.failure('Unavailable', statusCode: 404),
      onFetchProducts: (charity, {limit = 20, cursor}) async =>
          Result.failure('Unavailable', statusCode: 404),
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityId: 'missing-id'),
      repository: repo,
    );

    await vm.loadInitial();
    expect(vm.status, CharityProfileStatus.unavailable);
    expect(vm.products, isEmpty);
  });

  test('retains Discover fallback description when backend lookup returns 404 for a named charity', () async {
    final repo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async =>
          Result.failure('Unavailable', statusCode: 404),
      onFetchProducts: (charity, {limit = 20, cursor}) async =>
          Result.failure('Unavailable', statusCode: 404),
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityName: 'West London NHS Charity'),
      repository: repo,
    );

    await vm.loadInitial();
    expect(vm.status, CharityProfileStatus.unavailable);
    expect(
      vm.displayDescription,
      contains('West London NHS Charity raises funds'),
    );
  });

  test('sets and clears loadMoreErrorMessage while preserving products and cursor for retry', () async {
    final dogs = _charity();
    final p1 = _product('p1', 'dogs-trust', dogs);
    final p2 = _product('p2', 'dogs-trust', dogs);
    var page2Attempts = 0;
    Completer<Result<CharityProfilePageData>>? retryCompleter;

    final repo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async => Result.success(dogs),
      onFetchProducts: (charity, {limit = 20, cursor}) async {
        if (cursor == null) {
          return Result.success(
            CharityProfilePageData(
              charity: charity,
              products: [p1],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          );
        }
        page2Attempts++;
        if (page2Attempts == 1) {
          return Result.failure('Network error');
        }
        return retryCompleter!.future;
      },
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityId: 'dogs-trust'),
      repository: repo,
    );

    await vm.loadInitial();
    expect(vm.products.map((p) => p.id), ['p1']);
    expect(vm.loadMoreErrorMessage, isNull);

    await vm.loadMore();
    expect(vm.status, CharityProfileStatus.loaded);
    expect(vm.isLoadingMore, isFalse);
    expect(vm.products.map((p) => p.id), ['p1']);
    expect(vm.hasMore, isTrue);
    expect(vm.loadMoreErrorMessage, AppStrings.profileListingsLoadMoreFailed);

    retryCompleter = Completer<Result<CharityProfilePageData>>();
    final retryFuture = vm.loadMore();
    expect(vm.isLoadingMore, isTrue);
    expect(vm.loadMoreErrorMessage, isNull);

    retryCompleter.complete(
      Result.success(
        CharityProfilePageData(
          charity: dogs,
          products: [p2],
          nextCursor: null,
          hasMore: false,
        ),
      ),
    );
    await retryFuture;

    expect(vm.isLoadingMore, isFalse);
    expect(vm.loadMoreErrorMessage, isNull);
    expect(vm.hasMore, isFalse);
    expect(vm.products.map((p) => p.id), ['p1', 'p2']);
  });

  test('loadInitial automatically advances through empty filtered pages until visible items are found', () async {
    final dogs = _charity();
    final p1 = _product('p1', 'dogs-trust', dogs);
    final wrongCharity = _product('wrong-1', 'other-charity', null);
    final requestedCursors = <String?>[];

    final repo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async => Result.success(dogs),
      onFetchProducts: (charity, {limit = 20, cursor}) async {
        requestedCursors.add(cursor);
        if (cursor == null) {
          return Result.success(
            CharityProfilePageData(
              charity: charity,
              products: [wrongCharity],
              nextCursor: 'page-2',
              hasMore: true,
            ),
          );
        }
        return Result.success(
          CharityProfilePageData(
            charity: charity,
            products: [p1],
            nextCursor: null,
            hasMore: false,
          ),
        );
      },
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityId: 'dogs-trust'),
      repository: repo,
    );

    await vm.loadInitial();

    expect(requestedCursors, [null, 'page-2']);
    expect(vm.status, CharityProfileStatus.loaded);
    expect(vm.products.map((p) => p.id), ['p1']);
    expect(vm.hasMore, isFalse);
    expect(vm.loadMoreErrorMessage, isNull);
  });

  test('loadInitial stops after bounded empty pages and preserves retry when a skipped page fails', () async {
    final dogs = _charity();
    var cursorCall = 0;

    final failingSkipRepo = _FakeCharityProfileRepository(
      onFetchCharity: ({charityId, charityName}) async => Result.success(dogs),
      onFetchProducts: (charity, {limit = 20, cursor}) async {
        if (cursor == null) {
          return Result.success(
            CharityProfilePageData(
              charity: charity,
              products: const [],
              nextCursor: 'page-2',
              hasMore: true,
            ),
          );
        }
        cursorCall++;
        if (cursorCall == 1) {
          return Result.failure('Network error');
        }
        return Result.success(
          CharityProfilePageData(
            charity: charity,
            products: [_product('p-recovered', 'dogs-trust', dogs)],
            nextCursor: null,
            hasMore: false,
          ),
        );
      },
    );

    final vm = CharityProfileViewModel(
      args: const CharityProfileArgs(charityId: 'dogs-trust'),
      repository: failingSkipRepo,
    );

    await vm.loadInitial();

    expect(vm.status, CharityProfileStatus.loaded);
    expect(vm.products, isEmpty);
    expect(vm.hasMore, isTrue);
    expect(vm.loadMoreErrorMessage, AppStrings.profileListingsLoadMoreFailed);

    await vm.loadMore();

    expect(vm.products.map((p) => p.id), ['p-recovered']);
    expect(vm.hasMore, isFalse);
    expect(vm.loadMoreErrorMessage, isNull);
  });
}
