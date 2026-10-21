import 'dart:async';

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _Repository extends ProductRepository {
  _Repository() : super(const UnexpectedApiService());

  final deletedIds = <String>[];
  Future<Result<void>> Function()? onDelete;

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    deletedIds.add(productId);
    return onDelete == null ? Result<void>.success(null, statusCode: 200) : onDelete!();
  }
}

void main() {
  late _Repository repository;
  late DeletedListings deletedListings;
  late DeleteListingViewModel viewModel;
  late String? userId;

  DeleteListingViewModel createViewModel({
    bool enabled = true,
    Stream<String?>? accountChanges,
    void Function()? onAccountChanged,
  }) => DeleteListingViewModel(
    repository: repository,
    deletedListings: deletedListings,
    currentUserId: () => userId,
    accountChanges: accountChanges,
    onAccountChanged: onAccountChanged,
    enabled: enabled,
  );

  Future<DeleteListingOutcome> submit({
    String ownerId = 'owner',
    bool knownSold = false,
    ListingActionSession? session,
  }) => viewModel.delete(
    'listing',
    ownerId: ownerId,
    knownSold: knownSold,
    actionSession: session ?? viewModel.session,
  );

  setUp(() {
    repository = _Repository();
    deletedListings = DeletedListings();
    userId = 'owner';
    viewModel = createViewModel();
  });

  tearDown(() {
    viewModel.dispose();
    deletedListings.dispose();
  });

  test('deletion is disabled by default, independently of listing ownership', () async {
    viewModel.dispose();
    viewModel = DeleteListingViewModel(
      repository: repository,
      deletedListings: deletedListings,
      currentUserId: () => userId,
    );
    expect(viewModel.enabled, isFalse);
    expect(viewModel.canDelete('listing', ownerId: 'owner', knownSold: false), isFalse);
    expect(await submit(), DeleteListingOutcome.unavailable);
    expect(repository.deletedIds, isEmpty);
  });

  test('only a signed-in owner can delete and known sold listings are blocked', () async {
    expect(viewModel.canDelete('listing', ownerId: 'owner', knownSold: false), isTrue);
    expect(await submit(ownerId: 'someone-else'), DeleteListingOutcome.unavailable);
    expect(await submit(knownSold: true), DeleteListingOutcome.unavailable);
    userId = null;
    expect(await submit(), DeleteListingOutcome.unavailable);
    userId = '';
    expect(viewModel.owns(''), isFalse);
    expect(await submit(ownerId: ''), DeleteListingOutcome.unavailable);
    expect(repository.deletedIds, isEmpty);
    expect(deletedListings.contains('listing'), isFalse);
  });

  test('confirmed deletion records a tombstone and blocks another request', () async {
    expect(await submit(), DeleteListingOutcome.deleted);
    expect(repository.deletedIds, ['listing']);
    expect(deletedListings.contains('listing'), isTrue);
    expect(viewModel.isPending('listing'), isFalse);
    expect(await submit(), DeleteListingOutcome.unavailable);
    expect(repository.deletedIds, ['listing']);
  });

  test('one pending request per listing prevents repeated taps across callers', () async {
    final response = Completer<Result<void>>();
    repository.onDelete = () => response.future;
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final first = submit();
    expect(viewModel.isPending('listing'), isTrue);
    expect(await submit(), DeleteListingOutcome.alreadyPending);
    expect(repository.deletedIds, ['listing']);
    expect(deletedListings.contains('listing'), isFalse);

    response.complete(Result<void>.success(null, statusCode: 200));
    expect(await first, DeleteListingOutcome.deleted);
    expect(viewModel.isPending('listing'), isFalse);
    expect(notifications, 2);
  });

  for (final (status, code, outcome) in [
    (401, null, DeleteListingOutcome.unauthenticated),
    (401, 'UNEXPECTED_CODE', DeleteListingOutcome.unauthenticated),
    (403, 'LISTING_NOT_OWNER', DeleteListingOutcome.notOwner),
    (404, 'LISTING_NOT_FOUND', DeleteListingOutcome.notFound),
    (409, 'LISTING_PAYMENT_PENDING', DeleteListingOutcome.paymentPending),
    (409, 'LISTING_HAS_SALES', DeleteListingOutcome.hasSales),
    (409, 'LISTING_REVIEW_REQUIRED', DeleteListingOutcome.reviewRequired),
    (400, 'INVALID_REQUEST', DeleteListingOutcome.uncertain),
    (403, null, DeleteListingOutcome.uncertain),
    (404, null, DeleteListingOutcome.uncertain),
    (404, 'UNEXPECTED_CODE', DeleteListingOutcome.uncertain),
    (409, 'UNEXPECTED_CODE', DeleteListingOutcome.uncertain),
    (500, null, DeleteListingOutcome.uncertain),
    (503, 'LISTING_NOT_FOUND', DeleteListingOutcome.uncertain),
    (null, null, DeleteListingOutcome.uncertain),
  ]) {
    test('maps DELETE $status / $code to $outcome without trusting error text', () async {
      repository.onDelete = () async => Result<void>.failure(
        'Untrusted backend details',
        statusCode: status,
        errorCode: code,
      );
      expect(await submit(), outcome);
      expect(viewModel.isPending('listing'), isFalse);
      expect(deletedListings.contains('listing'), outcome == DeleteListingOutcome.notFound);
      expect(outcome.message, isNot(contains('Untrusted backend details')));
    });
  }

  test('timeout is uncertain, preserves the listing, and permits a deliberate null-data success retry', () async {
    repository.onDelete = () async => throw TimeoutException('Response lost');
    expect(await submit(), DeleteListingOutcome.uncertain);
    expect(deletedListings.contains('listing'), isFalse);
    expect(viewModel.isPending('listing'), isFalse);

    repository.onDelete = () async => Result<void>.success(null, statusCode: 200);
    expect(await submit(), DeleteListingOutcome.deleted);
    expect(repository.deletedIds, ['listing', 'listing']);
    expect(deletedListings.contains('listing'), isTrue);
  });

  test('an account change before confirmation prevents the request', () async {
    final session = viewModel.session;
    userId = 'another-owner';
    expect(await submit(session: session), DeleteListingOutcome.accountChanged);
    expect(repository.deletedIds, isEmpty);
    expect(deletedListings.contains('listing'), isFalse);
  });

  for (final result in [
    Result<void>.success(null, statusCode: 200),
    Result<void>.failure('Gone', statusCode: 404, errorCode: 'LISTING_NOT_FOUND'),
  ]) {
    test('an account change during ${result.isSuccess ? 'success' : 'not-found'} prevents a tombstone', () async {
      final response = Completer<Result<void>>();
      repository.onDelete = () => response.future;
      final deletion = submit();
      userId = 'another-owner';
      response.complete(result);
      expect(await deletion, DeleteListingOutcome.accountChanged);
      expect(deletedListings.contains('listing'), isFalse);
      expect(viewModel.isPending('listing'), isFalse);
    });
  }

  test('signing out during an exception does not report the previous account result', () async {
    final response = Completer<Result<void>>();
    repository.onDelete = () => response.future;
    final deletion = submit();
    userId = null;
    response.completeError(TimeoutException('Response lost'));
    expect(await deletion, DeleteListingOutcome.accountChanged);
    expect(deletedListings.contains('listing'), isFalse);
  });

  test('account stream invalidates an A to B to A session even when the final ID matches', () async {
    final changes = StreamController<String?>(sync: true);
    addTearDown(changes.close);
    viewModel.dispose();
    var accountChanges = 0;
    viewModel = createViewModel(
      accountChanges: changes.stream,
      onAccountChanged: () => accountChanges++,
    );
    final session = viewModel.session;
    final response = Completer<Result<void>>();
    repository.onDelete = () => response.future;
    final deletion = submit(session: session);
    userId = 'another-owner';
    changes.add(userId);
    userId = 'owner';
    changes.add(userId);
    response.complete(Result<void>.success(null, statusCode: 200));
    expect(await deletion, DeleteListingOutcome.accountChanged);
    expect(viewModel.isCurrent(session), isFalse);
    expect(viewModel.session.userId, 'owner');
    expect(accountChanges, greaterThan(0));
    expect(deletedListings.contains('listing'), isFalse);
  });

  test('disposal while pending suppresses late notifications and tombstones', () async {
    final response = Completer<Result<void>>();
    repository.onDelete = () => response.future;
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final deletion = submit();
    final disposedViewModel = viewModel;
    disposedViewModel.dispose();
    viewModel = createViewModel();
    response.complete(Result<void>.success(null, statusCode: 200));
    expect(await deletion, DeleteListingOutcome.accountChanged);
    expect(notifications, 1);
    expect(deletedListings.contains('listing'), isFalse);
  });
}
