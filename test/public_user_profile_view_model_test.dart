import 'dart:async';

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/public_profile_fixtures.dart';

void main() {
  PublicUserProfileViewModel model(FakePublicProfileRepository repository) {
    final viewModel = PublicUserProfileViewModel(userId: 'seller', repository: repository);
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test('loads the requested public user and treats no listings as an available profile', () async {
    final repository = FakePublicProfileRepository((userId, _) => Result.success(publicProfilePage(userId: userId)));
    final viewModel = model(repository);
    expect(viewModel.status, PublicProfileStatus.loading);
    await viewModel.loadProfile();
    expect(viewModel.status, PublicProfileStatus.ready);
    expect(viewModel.user!.id, 'seller');
    expect(viewModel.products, isEmpty);
    expect(repository.calls.single.userId, 'seller');
  });

  test('distinguishes unavailable users from temporary or authentication failures', () async {
    for (final status in [404, 410, 401, 403, 429, 500, null]) {
      final viewModel = model(FakePublicProfileRepository((_, _) => Result.failure('private', statusCode: status)));
      await viewModel.loadProfile();
      expect(
        viewModel.status,
        [404, 410].contains(status) ? PublicProfileStatus.unavailable : PublicProfileStatus.error,
      );
      expect(viewModel.user, isNull);
    }
  });

  test('pagination deduplicates listings, sends the cursor and prevents concurrent loads', () async {
    final pending = Completer<Result<PublicUserProfilePage>>();
    final repository = FakePublicProfileRepository(
      (_, cursor) => cursor == null
          ? Result.success(publicProfilePage(products: [publicProfileProduct('one')], cursor: 'next'))
          : pending.future,
    );
    final viewModel = model(repository);
    await viewModel.loadProfile();
    final loading = viewModel.loadMore();
    await viewModel.loadMore();
    expect(viewModel.isLoadingMore, isTrue);
    expect(repository.calls.length, 2);
    expect(repository.calls.last.cursor, 'next');
    pending.complete(
      Result.success(publicProfilePage(products: [publicProfileProduct('one'), publicProfileProduct('two')])),
    );
    await loading;
    expect(viewModel.products.map((p) => p.id), ['one', 'two']);
    expect(viewModel.hasMore, isFalse);
    expect(viewModel.isLoadingMore, isFalse);
    expect(() => viewModel.products.clear(), throwsUnsupportedError);
  });

  test('failed next page keeps visible listings and can be retried', () async {
    var fail = true;
    final viewModel = model(
      FakePublicProfileRepository(
        (_, cursor) => cursor == null
            ? Result.success(publicProfilePage(products: [publicProfileProduct('one')], cursor: 'next'))
            : fail
            ? Result.failure('network')
            : Result.success(publicProfilePage(products: [publicProfileProduct('two')])),
      ),
    );
    await viewModel.loadProfile();
    await viewModel.loadMore();
    expect(viewModel.products.single.id, 'one');
    expect(viewModel.loadMoreFailed, isTrue);
    fail = false;
    await viewModel.loadMore();
    expect(viewModel.products.length, 2);
    expect(viewModel.loadMoreFailed, isFalse);
  });

  test('unavailable account on a later page clears the user and earlier listings', () async {
    final viewModel = model(
      FakePublicProfileRepository(
        (_, cursor) => cursor == null
            ? Result.success(publicProfilePage(products: [publicProfileProduct('one')], cursor: 'next'))
            : Result.failure('unavailable', statusCode: 410),
      ),
    );
    await viewModel.loadProfile();
    await viewModel.loadMore();
    expect(viewModel.status, PublicProfileStatus.unavailable);
    expect(viewModel.user, isNull);
    expect(viewModel.products, isEmpty);
    expect(viewModel.hasMore, isFalse);
  });

  test('refresh replaces old data and ignores an earlier pagination response', () async {
    final pending = Completer<Result<PublicUserProfilePage>>();
    var initialCalls = 0;
    final viewModel = model(
      FakePublicProfileRepository((_, cursor) {
        if (cursor != null) return pending.future;
        initialCalls++;
        return Result.success(
          publicProfilePage(products: [publicProfileProduct('first-$initialCalls')], cursor: 'next'),
        );
      }),
    );
    await viewModel.loadProfile();
    final loadMore = viewModel.loadMore();
    await viewModel.loadProfile();
    pending.complete(Result.success(publicProfilePage(products: [publicProfileProduct('stale')])));
    await loadMore;
    expect(viewModel.products.single.id, 'first-2');
    expect(viewModel.hasMore, isTrue);
    expect(viewModel.isLoadingMore, isFalse);
  });

  test('a repeated cursor stops pagination', () async {
    final repository = FakePublicProfileRepository((_, _) => Result.success(publicProfilePage(cursor: 'same')));
    final viewModel = model(repository);
    await viewModel.loadProfile();
    await viewModel.loadMore();
    await viewModel.loadMore();
    expect(viewModel.hasMore, isFalse);
    expect(repository.calls.length, 2);
  });

  test('closing the route ignores late responses and makes no further requests', () async {
    final pending = Completer<Result<PublicUserProfilePage>>();
    final repository = FakePublicProfileRepository((_, _) => pending.future);
    final viewModel = PublicUserProfileViewModel(userId: 'seller', repository: repository);
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final loading = viewModel.loadProfile();
    viewModel.dispose();
    pending.complete(Result.success(publicProfilePage()));
    await loading;
    await viewModel.loadProfile();
    expect(notifications, 1);
    expect(viewModel.user, isNull);
    expect(repository.calls.length, 1);
  });
}
