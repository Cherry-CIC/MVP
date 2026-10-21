import 'dart:async';

import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter/foundation.dart';

enum DeleteListingOutcome {
  deleted,
  notFound,
  notOwner,
  paymentPending,
  hasSales,
  reviewRequired,
  unauthenticated,
  uncertain,
  accountChanged,
  unavailable,
  alreadyPending;

  bool get removed => this == deleted || this == notFound;
  bool get canRetry => this == uncertain || this == paymentPending;

  String get message => switch (this) {
    deleted => 'Listing deleted',
    notFound => 'This listing is no longer available.',
    notOwner => 'Only the owner can delete this listing. Its details will be refreshed.',
    paymentPending => 'A payment is in progress. Please try again once it has finished.',
    hasSales => 'This listing cannot be deleted because it may need to be kept for purchase records.',
    reviewRequired => 'This listing needs to be reviewed before it can be deleted.',
    unauthenticated => 'Please sign in again before deleting this listing.',
    uncertain => 'We could not confirm whether this listing was deleted. Please try again to check.',
    accountChanged => 'Your account changed. Reopen the listing before trying again.',
    unavailable => 'This listing cannot be deleted at the moment.',
    alreadyPending => 'Please wait for the current deletion to finish.',
  };
}

/// Captured when opening an action, not after a confirmation or network wait.
class ListingActionSession {
  const ListingActionSession(this.userId, this.revision);
  final String? userId;
  final int revision;
}

class DeleteListingViewModel extends ChangeNotifier {
  DeleteListingViewModel({
    required this.repository,
    required this.deletedListings,
    required String? Function() currentUserId,
    Stream<String?>? accountChanges,
    this.onAccountChanged,
  }) : _readUserId = currentUserId,
       _accountId = currentUserId() {
    _accountSubscription = accountChanges?.listen(_updateAccount);
  }

  final ProductRepository repository;
  final DeletedListings deletedListings;
  final String? Function() _readUserId;
  final VoidCallback? onAccountChanged;
  StreamSubscription<String?>? _accountSubscription;
  final Set<String> _pending = {};
  String? _accountId;
  int _revision = 0;
  bool _disposed = false;
  bool _notificationScheduled = false;

  ListingActionSession get session {
    _updateAccount(_readUserId());
    return ListingActionSession(_accountId, _revision);
  }

  bool isCurrent(ListingActionSession value) {
    final current = session;
    return !_disposed && value.userId == current.userId && value.revision == current.revision;
  }

  bool owns(String? ownerId) {
    final uid = session.userId;
    return uid != null && uid.isNotEmpty && ownerId == uid;
  }

  bool isPending(String id) => _pending.contains(id);

  bool canDelete(String id, {required String? ownerId, required bool knownSold}) =>
      owns(ownerId) && !knownSold && !deletedListings.contains(id);

  Future<DeleteListingOutcome> delete(
    String id, {
    required String ownerId,
    required bool knownSold,
    required ListingActionSession actionSession,
  }) async {
    if (!isCurrent(actionSession)) return DeleteListingOutcome.accountChanged;
    if (!canDelete(id, ownerId: ownerId, knownSold: knownSold)) return DeleteListingOutcome.unavailable;
    if (!_pending.add(id)) return DeleteListingOutcome.alreadyPending;
    notifyListeners();
    try {
      final result = await repository.deleteProduct(id);
      if (!isCurrent(actionSession)) return DeleteListingOutcome.accountChanged;
      final DeleteListingOutcome outcome;
      if (result.isSuccess) {
        outcome = DeleteListingOutcome.deleted;
      } else {
        outcome = switch ((result.statusCode, result.errorCode)) {
          (401, _) => DeleteListingOutcome.unauthenticated,
          (403, 'LISTING_NOT_OWNER') => DeleteListingOutcome.notOwner,
          (404, 'LISTING_NOT_FOUND') => DeleteListingOutcome.notFound,
          (409, 'LISTING_PAYMENT_PENDING') => DeleteListingOutcome.paymentPending,
          (409, 'LISTING_HAS_SALES') => DeleteListingOutcome.hasSales,
          (409, 'LISTING_REVIEW_REQUIRED') => DeleteListingOutcome.reviewRequired,
          _ => DeleteListingOutcome.uncertain,
        };
      }
      // A GET 404 is deliberately insufficient: hidden listings can return it.
      if (outcome.removed) deletedListings.add(id);
      return outcome;
    } catch (_) {
      return isCurrent(actionSession) ? DeleteListingOutcome.uncertain : DeleteListingOutcome.accountChanged;
    } finally {
      _pending.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  void _updateAccount(String? uid) {
    if (_disposed || _accountId == uid) return;
    _accountId = uid;
    _revision++;
    // Ownership may be checked while building a menu. Notify after that build.
    if (_notificationScheduled) return;
    _notificationScheduled = true;
    scheduleMicrotask(() {
      _notificationScheduled = false;
      if (_disposed) return;
      onAccountChanged?.call();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _accountSubscription?.cancel();
    super.dispose();
  }
}
