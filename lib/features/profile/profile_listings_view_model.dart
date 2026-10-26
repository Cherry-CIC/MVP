import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:flutter/foundation.dart';

class ProfileListingsViewModel extends ChangeNotifier {
  static const int defaultPageSize = 20;

  final IProfileListingsRepository repository;
  final DeletedListings? deletedListings;
  final String? Function()? _currentUserIdProvider;
  String? _accountOwnerId;

  ProfileListingsViewModel({
    required this.repository,
    this.deletedListings,
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider,
       _accountOwnerId = currentUserIdProvider?.call() {
    deletedListings?.addListener(_removeDeletedListings);
  }

  Status _status = Status.uninitialized;
  List<SellerListing> _listings = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isFirstPageLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasLoadMoreError = false;
  bool _hasRefreshError = false;
  bool _disposed = false;
  int _requestSequence = 0;

  Status get status => _status;
  List<SellerListing> get listings => List.unmodifiable(_listings);
  bool get hasMore => _hasMore;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasLoadMoreError => _hasLoadMoreError;
  bool get hasRefreshError => _hasRefreshError;
  String? get accountOwnerId => _accountOwnerId;

  /// Called on authentication changes as well as before applying a response.
  void updateCurrentAccount() {
    if (_disposed || _currentUserIdProvider == null) return;
    final currentUserId = _currentUserIdProvider();
    if (_accountOwnerId == currentUserId) return;
    _accountOwnerId = currentUserId;
    clearListings();
  }

  Future<void> loadInitialListings() async {
    await _fetchFirstPage(clearListings: true);
  }

  Future<void> refreshListings() async {
    await _fetchFirstPage(clearListings: false, supersedeInFlight: true);
  }

  /// An edited listing must not retain its old card if the refresh fails.
  Future<void> refreshAfterListingEdit() async {
    _isRefreshing = false;
    await _fetchFirstPage(clearListings: true, supersedeInFlight: true);
  }

  Future<void> retryInitialLoad() async {
    await _fetchFirstPage(clearListings: true);
  }

  Future<void> loadMoreListings({bool retry = false}) async {
    updateCurrentAccount();
    if (_disposed || (_currentUserIdProvider != null && _accountOwnerId == null)) return;
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

      if (!_isCurrent(requestId)) {
        return;
      }

      if (result.isSuccess && result.value != null) {
        final page = result.value!;
        final seenIds = _listings.map((listing) => listing.id).toSet();
        final newListings = page.listings.where(
          (listing) => deletedListings?.contains(listing.id) != true && seenIds.add(listing.id),
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
      if (_isCurrent(requestId)) {
        _hasLoadMoreError = true;
      }
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.severe,
      );
    } finally {
      if (_isCurrent(requestId)) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoadMore() async {
    await loadMoreListings(retry: true);
  }

  void clearListings({bool notify = true}) {
    if (_disposed) return;
    _requestSequence++;
    _status = Status.uninitialized;
    _listings = const [];
    _nextCursor = null;
    _hasMore = false;
    _isFirstPageLoading = false;
    _isRefreshing = false;
    _isLoadingMore = false;
    _hasLoadMoreError = false;
    _hasRefreshError = false;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _fetchFirstPage({required bool clearListings, bool supersedeInFlight = false}) async {
    updateCurrentAccount();
    if (_disposed || (_currentUserIdProvider != null && _accountOwnerId == null)) return;
    // A refresh after posting must replace any request started before the post.
    if (_isFirstPageLoading && !supersedeInFlight) {
      return;
    }

    final requestId = ++_requestSequence;
    _isFirstPageLoading = true;
    _isLoadingMore = false;
    _hasLoadMoreError = false;
    _hasRefreshError = false;

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

      if (!_isCurrent(requestId)) {
        return;
      }

      if (result.isSuccess && result.value != null) {
        final page = result.value!;
        _listings = _deduplicate(page.listings);
        _setPagination(page);
        _status = Status.success;
      } else {
        _hasRefreshError = !clearListings;
        if (_listings.isEmpty) {
          _status = Status.failure(
            result.error ?? 'Could not load your listings',
          );
        }
      }
    } catch (_) {
      if (_isCurrent(requestId)) {
        _hasRefreshError = !clearListings;
        if (_listings.isEmpty) {
          _status = Status.failure('Could not load your listings');
        }
      }
      SafeLog.event(
        AppLogEvent.profileListingsLoadFailed,
        level: SafeLogLevel.severe,
      );
    } finally {
      if (_isCurrent(requestId)) {
        _isFirstPageLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  List<SellerListing> _deduplicate(List<SellerListing> listings) {
    final seenIds = <String>{};
    return listings
        .where((listing) => deletedListings?.contains(listing.id) != true && seenIds.add(listing.id))
        .toList(growable: false);
  }

  void _setPagination(ProfileListingsPage page) {
    final cursor = page.nextCursor?.trim();
    _nextCursor = cursor == null || cursor.isEmpty ? null : cursor;
    _hasMore = page.hasMore && _nextCursor != null;
  }

  bool _isCurrent(int requestId) {
    if (_disposed) return false;
    updateCurrentAccount();
    return requestId == _requestSequence;
  }

  void _removeDeletedListings() {
    if (_disposed) return;
    final listings = _deduplicate(_listings);
    if (listings.length == _listings.length) return;
    _listings = listings;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestSequence++;
    deletedListings?.removeListener(_removeDeletedListings);
    super.dispose();
  }
}
