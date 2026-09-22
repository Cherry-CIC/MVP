import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:flutter/foundation.dart';

class ProfileListingsViewModel extends ChangeNotifier {
  static const int defaultPageSize = 20;

  final IProfileListingsRepository repository;

  ProfileListingsViewModel({
    required this.repository,
  });

  Status _status = Status.uninitialized;
  List<SellerListing> _listings = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isFirstPageLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasLoadMoreError = false;
  int _requestSequence = 0;
  String? _openingListingId;
  String? _openListingError;

  Status get status => _status;
  List<SellerListing> get listings => List.unmodifiable(_listings);
  bool get hasMore => _hasMore;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoadMoreError => _hasLoadMoreError;

  /// Id of the listing whose details are currently being loaded, if any.
  String? get openingListingId => _openingListingId;

  /// Message describing the last failed attempt to open a listing.
  String? get openListingError => _openListingError;

  bool isOpeningListing(String listingId) => _openingListingId == listingId;

  Future<void> loadInitialListings() async {
    await _fetchFirstPage(clearListings: true);
  }

  Future<void> refreshListings() async {
    await _fetchFirstPage(clearListings: false);
  }

  Future<void> retryInitialLoad() async {
    await _fetchFirstPage(clearListings: true);
  }

  Future<void> loadMoreListings({bool retry = false}) async {
    if (_isFirstPageLoading || _isLoadingMore || !_hasMore || _nextCursor == null || (_hasLoadMoreError && !retry)) {
      return;
    }

    final requestId = _requestSequence;
    final cursor = _nextCursor;
    _isLoadingMore = true;
    _hasLoadMoreError = false;
    notifyListeners();

    try {
      final result = await repository.fetchListings(
        limit: defaultPageSize,
        cursor: cursor,
      );

      if (requestId != _requestSequence) {
        return;
      }

      if (result.isSuccess && result.value != null) {
        final page = result.value!;
        final seenIds = _listings.map((listing) => listing.id).toSet();
        final newListings = page.listings.where(
          (listing) => seenIds.add(listing.id),
        );
        _listings = [..._listings, ...newListings];
        _setPagination(page);
      } else {
        _hasLoadMoreError = true;
        SafeLog.event(
          AppLogEvent.profileListingsLoadFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      if (requestId == _requestSequence) {
        _hasLoadMoreError = true;
      }
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.severe,
      );
    } finally {
      if (requestId == _requestSequence) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Loads the full product behind one of the user's own listings.
  ///
  /// Returns `null` when the listing could not be loaded; [openListingError]
  /// then holds a message suitable for showing to the user.
  Future<Product?> openListing(String listingId) async {
    final trimmedId = listingId.trim();
    if (trimmedId.isEmpty || _openingListingId != null) {
      return null;
    }

    final requestId = _requestSequence;
    _openingListingId = trimmedId;
    _openListingError = null;
    notifyListeners();

    try {
      final result = await repository.fetchListingProduct(trimmedId);

      if (requestId != _requestSequence) {
        return null;
      }

      if (result.isSuccess && result.value != null) {
        return result.value;
      }

      _openListingError = result.error ?? 'We could not open this listing.';
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.warning,
      );
      return null;
    } catch (_) {
      if (requestId == _requestSequence) {
        _openListingError = 'We could not open this listing.';
      }
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.severe,
      );
      return null;
    } finally {
      if (_openingListingId == trimmedId) {
        _openingListingId = null;
        notifyListeners();
      }
    }
  }

  void clearOpenListingError() {
    if (_openListingError == null) {
      return;
    }

    _openListingError = null;
    notifyListeners();
  }

  Future<void> retryLoadMore() async {
    await loadMoreListings(retry: true);
  }

  void clearListings({bool notify = true}) {
    _requestSequence++;
    _status = Status.uninitialized;
    _listings = const [];
    _nextCursor = null;
    _hasMore = false;
    _isFirstPageLoading = false;
    _isRefreshing = false;
    _isLoadingMore = false;
    _hasLoadMoreError = false;
    _openingListingId = null;
    _openListingError = null;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _fetchFirstPage({required bool clearListings}) async {
    if (_isFirstPageLoading) {
      return;
    }

    final requestId = ++_requestSequence;
    _isFirstPageLoading = true;
    _isLoadingMore = false;
    _hasLoadMoreError = false;

    if (clearListings) {
      _listings = const [];
      _nextCursor = null;
      _hasMore = false;
      _status = Status.loading;
    } else if (_listings.isEmpty) {
      _status = Status.loading;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final result = await repository.fetchListings(
        limit: defaultPageSize,
      );

      if (requestId != _requestSequence) {
        return;
      }

      if (result.isSuccess && result.value != null) {
        final page = result.value!;
        _listings = _deduplicate(page.listings);
        _setPagination(page);
        _status = Status.success;
      } else if (_listings.isEmpty) {
        _status = Status.failure(
          result.error ?? 'Could not load your listings',
        );
      }
    } catch (_) {
      if (requestId == _requestSequence && _listings.isEmpty) {
        _status = Status.failure('Could not load your listings');
      }
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.severe,
      );
    } finally {
      if (requestId == _requestSequence) {
        _isFirstPageLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  List<SellerListing> _deduplicate(List<SellerListing> listings) {
    final seenIds = <String>{};
    return listings.where((listing) => seenIds.add(listing.id)).toList(growable: false);
  }

  void _setPagination(ProfileListingsPage page) {
    final cursor = page.nextCursor?.trim();
    _nextCursor = cursor == null || cursor.isEmpty ? null : cursor;
    _hasMore = page.hasMore && _nextCursor != null;
  }
}
