import 'dart:async';

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _QueuedProfileListingsRepository implements IProfileListingsRepository {
  final List<Future<Result<ProfileListingsPage>>> responses;
  final List<String?> requestedCursors = [];

  _QueuedProfileListingsRepository(this.responses);

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) {
    requestedCursors.add(cursor);
    return responses.removeAt(0);
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
  });
}

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
