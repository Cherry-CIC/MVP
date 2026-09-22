import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _QueuedProfileListingsRepository implements IProfileListingsRepository {
  final List<Future<Result<ProfileListingsPage>>> responses;
  final List<String?> requestedCursors = [];
  final List<String> requestedProductIds = [];
  Future<Result<Product>> Function(String productId)? productResponse;

  _QueuedProfileListingsRepository(this.responses);

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) {
    requestedCursors.add(cursor);
    return responses.removeAt(0);
  }

  @override
  Future<Result<Product>> fetchListingProduct(String productId) {
    requestedProductIds.add(productId);
    final response = productResponse;
    if (response == null) {
      throw StateError('No product response configured');
    }
    return response(productId);
  }
}

void main() {
  group('ProfileListingsViewModel', () {
    test('moves from loading to success on the first page', () async {
      final response = Completer<Result<ProfileListingsPage>>();
      final repository = _QueuedProfileListingsRepository([response.future]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      final request = viewModel.loadInitialListings();

      expect(viewModel.status.type, StatusType.loading);
      expect(viewModel.listings, isEmpty);

      response.complete(
        Result.success(
          _page(
            [_listing('listing-1')],
            nextCursor: 'cursor-2',
            hasMore: true,
          ),
        ),
      );
      await request;

      expect(viewModel.status.type, StatusType.success);
      expect(viewModel.listings.single.id, 'listing-1');
      expect(viewModel.hasMore, isTrue);
    });

    test('exposes an initial request failure', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(Result.failure('technical failure')),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();

      expect(viewModel.status.type, StatusType.failure);
      expect(viewModel.status.message, 'technical failure');
      expect(viewModel.listings, isEmpty);
    });

    test('refresh replaces listings and resets first-page pagination', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('old-listing')],
              nextCursor: 'old-cursor',
              hasMore: true,
            ),
          ),
        ),
        Future.value(
          Result.success(
            _page([_listing('new-listing')]),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      await viewModel.refreshListings();

      expect(
        viewModel.listings.map((listing) => listing.id),
        ['new-listing'],
      );
      expect(viewModel.hasMore, isFalse);
      expect(repository.requestedCursors, [null, null]);
    });

    test('load more appends unique listings and uses the next cursor', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('listing-1')],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          ),
        ),
        Future.value(
          Result.success(
            _page([
              _listing('listing-1'),
              _listing('listing-2'),
              _listing('listing-2'),
            ]),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      await viewModel.loadMoreListings();

      expect(
        viewModel.listings.map((listing) => listing.id),
        ['listing-1', 'listing-2'],
      );
      expect(repository.requestedCursors, [null, 'cursor-2']);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('does not offer pagination without a usable next cursor', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('listing-1')],
              hasMore: true,
            ),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      await viewModel.loadMoreListings();

      expect(viewModel.hasMore, isFalse);
      expect(repository.requestedCursors, [null]);
    });

    test('stale load-more results cannot overwrite a newer refresh', () async {
      final staleLoadMore = Completer<Result<ProfileListingsPage>>();
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('listing-1')],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          ),
        ),
        staleLoadMore.future,
        Future.value(
          Result.success(
            _page([_listing('refreshed-listing')]),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      final loadMoreRequest = viewModel.loadMoreListings();
      await viewModel.refreshListings();
      staleLoadMore.complete(
        Result.success(
          _page([_listing('stale-listing')]),
        ),
      );
      await loadMoreRequest;

      expect(
        viewModel.listings.map((listing) => listing.id),
        ['refreshed-listing'],
      );
    });

    test('load-more failure preserves current listings and can be retried', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('listing-1')],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          ),
        ),
        Future.value(Result.failure('technical failure')),
        Future.value(
          Result.success(
            _page([_listing('listing-2')]),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      await viewModel.loadMoreListings();

      expect(viewModel.listings.single.id, 'listing-1');
      expect(viewModel.hasLoadMoreError, isTrue);
      expect(viewModel.isLoadingMore, isFalse);

      await viewModel.retryLoadMore();

      expect(
        viewModel.listings.map((listing) => listing.id),
        ['listing-1', 'listing-2'],
      );
      expect(viewModel.hasLoadMoreError, isFalse);
    });

    test('failed refresh preserves listings and their pagination state', () async {
      final repository = _QueuedProfileListingsRepository([
        Future.value(
          Result.success(
            _page(
              [_listing('listing-1')],
              nextCursor: 'cursor-2',
              hasMore: true,
            ),
          ),
        ),
        Future.value(Result.failure('technical failure')),
        Future.value(
          Result.success(
            _page([_listing('listing-2')]),
          ),
        ),
      ]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      await viewModel.loadInitialListings();
      await viewModel.refreshListings();

      expect(viewModel.listings.single.id, 'listing-1');
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadMoreListings();

      expect(repository.requestedCursors, [null, null, 'cursor-2']);
      expect(
        viewModel.listings.map((listing) => listing.id),
        ['listing-1', 'listing-2'],
      );
    });

    test('clearing listings prevents an in-flight response restoring account data', () async {
      final response = Completer<Result<ProfileListingsPage>>();
      final repository = _QueuedProfileListingsRepository([response.future]);
      final viewModel = ProfileListingsViewModel(repository: repository);

      final request = viewModel.loadInitialListings();
      viewModel.clearListings(notify: false);
      response.complete(
        Result.success(
          _page([_listing('previous-account-listing')]),
        ),
      );
      await request;

      expect(viewModel.status.type, StatusType.uninitialized);
      expect(viewModel.listings, isEmpty);
    });

    group('openListing', () {
      test('returns the full product and clears the pending state', () async {
        final repository = _QueuedProfileListingsRepository([]);
        final response = Completer<Result<Product>>();
        repository.productResponse = (_) => response.future;
        final viewModel = ProfileListingsViewModel(repository: repository);

        final request = viewModel.openListing('listing-1');

        expect(viewModel.isOpeningListing('listing-1'), isTrue);
        expect(viewModel.isOpeningListing('listing-2'), isFalse);

        response.complete(Result.success(_product));
        final product = await request;

        expect(product?.id, 'product-1');
        expect(repository.requestedProductIds, ['listing-1']);
        expect(viewModel.isOpeningListing('listing-1'), isFalse);
        expect(viewModel.openListingError, isNull);
      });

      test('surfaces a message when the product cannot be loaded', () async {
        final repository = _QueuedProfileListingsRepository([]);
        repository.productResponse = (_) async => Result.failure('Listing is gone.');
        final viewModel = ProfileListingsViewModel(repository: repository);

        final product = await viewModel.openListing('listing-1');

        expect(product, isNull);
        expect(viewModel.openListingError, 'Listing is gone.');
        expect(viewModel.isOpeningListing('listing-1'), isFalse);

        viewModel.clearOpenListingError();
        expect(viewModel.openListingError, isNull);
      });

      test('recovers from a thrown repository error', () async {
        final repository = _QueuedProfileListingsRepository([]);
        repository.productResponse = (_) => Future<Result<Product>>.error(
          StateError('boom'),
        );
        final viewModel = ProfileListingsViewModel(repository: repository);

        final product = await viewModel.openListing('listing-1');

        expect(product, isNull);
        expect(viewModel.openListingError, isNotNull);
        expect(viewModel.isOpeningListing('listing-1'), isFalse);
      });

      test('ignores a second request while one is in flight', () async {
        final repository = _QueuedProfileListingsRepository([]);
        final response = Completer<Result<Product>>();
        repository.productResponse = (_) => response.future;
        final viewModel = ProfileListingsViewModel(repository: repository);

        final first = viewModel.openListing('listing-1');
        expect(await viewModel.openListing('listing-2'), isNull);
        expect(repository.requestedProductIds, ['listing-1']);

        response.complete(Result.success(_product));
        expect((await first)?.id, 'product-1');
      });

      test('ignores a blank listing id', () async {
        final repository = _QueuedProfileListingsRepository([]);
        final viewModel = ProfileListingsViewModel(repository: repository);

        expect(await viewModel.openListing('   '), isNull);
        expect(repository.requestedProductIds, isEmpty);
      });
    });
  });
}

const _product = Product(
  id: 'product-1',
  userId: 'seller-1',
  name: 'Jumper',
  description: 'Blue jumper',
  quality: 'Good',
  productImages: [],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);

SellerListing _listing(String id) {
  return SellerListing(
    id: id,
    name: 'Listing $id',
    imageUrls: const [],
    price: 12.5,
  );
}

ProfileListingsPage _page(
  List<SellerListing> listings, {
  String? nextCursor,
  bool hasMore = false,
}) {
  return ProfileListingsPage(
    listings: listings,
    limit: 20,
    nextCursor: nextCursor,
    hasMore: hasMore,
  );
}
