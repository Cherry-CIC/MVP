import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/products/blocked_users.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:flutter/foundation.dart';

enum CharityProfileStatus {
  initial,
  loading,
  loaded,
  unavailable,
  blocked,
  error,
}

/// Manages loading, pagination, and safety state for a single charity profile.
class CharityProfileViewModel extends ChangeNotifier {
  static const int _maxAutoAdvanceEmptyPages = 4;

  CharityProfileViewModel({
    required this.args,
    required this.repository,
    this.deletedListings,
    this.blockedUsers,
    this.pageSize = 20,
  }) {
    deletedListings?.addListener(_onListingsChanged);
    blockedUsers?.addListener(_onListingsChanged);
  }

  final CharityProfileArgs args;
  final ICharityProfileRepository repository;
  final DeletedListings? deletedListings;
  final BlockedUsers? blockedUsers;
  final int pageSize;

  CharityProfileStatus _status = CharityProfileStatus.initial;
  Charity? _charity;
  List<Product> _products = const [];
  String? _errorMessage;
  String? _loadMoreErrorMessage;
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _requestSequence = 0;
  bool _disposed = false;

  CharityProfileStatus get status => _status;
  Charity? get charity => _charity ?? args.charity;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;
  String? get loadMoreErrorMessage => _loadMoreErrorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  String get displayName {
    final name = charity?.name.trim() ?? args.charityName?.trim() ?? '';
    return name.isEmpty ? AppStrings.charityProfileTitle : name;
  }

  String get displayImageUrl {
    final url = charity?.imageUrl.trim() ?? args.charityImageUrl?.trim() ?? '';
    return url;
  }

  String get displayDescription => CharityProfileRepository.resolveDescription(
    charity,
    fallbackName: args.charityName ?? args.charity?.name,
  );

  Charity? get headerCharity {
    final current = charity;
    if (current != null) return current;
    final id = CharityProfileArgs.safeIdentifier(args.charityId) ?? '';
    final name = args.charityName?.trim() ?? '';
    final image = args.charityImageUrl?.trim() ?? '';
    if (name.isEmpty && image.isEmpty) return null;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return Charity(
      id: id,
      name: name,
      imageUrl: image,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  Future<void> loadInitial() async {
    if (_disposed || _status == CharityProfileStatus.blocked) return;
    final requestId = ++_requestSequence;
    _status = CharityProfileStatus.loading;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    _isLoadingMore = false;
    _charity = args.charity;
    notifyListeners();

    final blockedHydration = blockedUsers?.ensureHydrated();
    final charityResult = await repository.fetchCharity(
      charityId: args.charityId ?? args.charity?.id,
      charityName: args.charityName ?? args.charity?.name,
    );
    if (blockedHydration != null) {
      await blockedHydration;
    }
    if (_disposed || requestId != _requestSequence) return;

    final resolvedCharity = charityResult.value ?? args.charity;
    if (!charityResult.isSuccess && resolvedCharity == null) {
      _charity = null;
      _products = const [];
      _nextCursor = null;
      _hasMore = false;
      _status = charityResult.statusCode == 404 || charityResult.statusCode == 410
          ? CharityProfileStatus.unavailable
          : CharityProfileStatus.error;
      _errorMessage = _status == CharityProfileStatus.unavailable
          ? AppStrings.charityProfileUnavailable
          : AppStrings.charityProfileLoadError;
      notifyListeners();
      return;
    }

    if (resolvedCharity == null ||
        CharityProfileArgs.safeIdentifier(resolvedCharity.id) == null) {
      _status = CharityProfileStatus.unavailable;
      _errorMessage = AppStrings.charityProfileUnavailable;
      notifyListeners();
      return;
    }

    _charity = resolvedCharity;

    final productsResult = await repository.fetchProducts(
      resolvedCharity,
      limit: pageSize,
    );
    if (_disposed || requestId != _requestSequence) return;

    await _applyInitialProductsResult(
      requestId: requestId,
      resolvedCharity: resolvedCharity,
      result: productsResult,
    );
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    if (_disposed ||
        _status != CharityProfileStatus.loaded ||
        _isLoadingMore ||
        !_hasMore ||
        _nextCursor == null ||
        charity == null) {
      return;
    }

    final currentCharity = charity!;
    final requestId = _requestSequence;
    _isLoadingMore = true;
    _loadMoreErrorMessage = null;
    notifyListeners();

    final merged = List<Product>.from(_products);
    final seenIds = merged.map((p) => p.id).toSet();
    await _fetchPagesUntilVisible(
      requestId: requestId,
      startingCharity: currentCharity,
      targetCharityId: currentCharity.id,
      merged: merged,
      seenIds: seenIds,
      startingCursor: _nextCursor,
      requireProgress: true,
    );
  }

  void markBlocked() {
    if (_disposed) return;
    _requestSequence++;
    _status = CharityProfileStatus.blocked;
    _products = const [];
    _nextCursor = null;
    _hasMore = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    notifyListeners();
  }

  Future<void> _applyInitialProductsResult({
    required int requestId,
    required Charity resolvedCharity,
    required Result<CharityProfilePageData> result,
  }) async {
    if (!result.isSuccess || result.value == null) {
      _products = const [];
      _nextCursor = null;
      _hasMore = false;
      _status = result.statusCode == 404 || result.statusCode == 410
          ? CharityProfileStatus.unavailable
          : CharityProfileStatus.error;
      _errorMessage = _status == CharityProfileStatus.unavailable
          ? AppStrings.charityProfileUnavailable
          : AppStrings.charityProfileLoadError;
      notifyListeners();
      return;
    }

    final page = result.value!;
    final merged = <Product>[];
    final seenIds = <String>{};
    _appendVisibleProducts(
      merged,
      seenIds,
      page.products,
      resolvedCharity.id,
    );

    if (merged.isEmpty && page.hasMore && page.nextCursor != null) {
      await _fetchPagesUntilVisible(
        requestId: requestId,
        startingCharity: page.charity,
        targetCharityId: resolvedCharity.id,
        merged: merged,
        seenIds: seenIds,
        startingCursor: page.nextCursor,
        requireProgress: false,
      );
      return;
    }

    _charity = page.charity;
    _products = List.unmodifiable(merged);
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    _status = CharityProfileStatus.loaded;
    _errorMessage = null;
    _loadMoreErrorMessage = null;
    notifyListeners();
  }

  Future<void> _fetchPagesUntilVisible({
    required int requestId,
    required Charity startingCharity,
    required String targetCharityId,
    required List<Product> merged,
    required Set<String> seenIds,
    required String? startingCursor,
    required bool requireProgress,
  }) async {
    var currentCharity = startingCharity;
    var cursor = startingCursor;
    var hasMore = cursor != null;
    var addedAny = false;
    var attempts = 0;
    final maxAttempts = _maxAutoAdvanceEmptyPages + (requireProgress ? 1 : 0);

    while (cursor != null && attempts < maxAttempts) {
      attempts++;
      final requestedCursor = cursor;
      try {
        final result = await repository.fetchProducts(
          currentCharity,
          limit: pageSize,
          cursor: requestedCursor,
        );
        if (_disposed || requestId != _requestSequence) return;

        if (!result.isSuccess || result.value == null) {
          _commitPagedState(
            charity: currentCharity,
            merged: merged,
            nextCursor: requestedCursor,
            hasMore: true,
            loadMoreErrorMessage: AppStrings.profileListingsLoadMoreFailed,
          );
          return;
        }

        final page = result.value!;
        currentCharity = page.charity;
        if (_appendVisibleProducts(
          merged,
          seenIds,
          page.products,
          targetCharityId,
        )) {
          addedAny = true;
        }
        hasMore = page.hasMore;
        cursor = page.nextCursor;

        if (!hasMore || cursor == null || cursor == requestedCursor) {
          hasMore = false;
          cursor = null;
          break;
        }

        if (requireProgress ? addedAny : merged.isNotEmpty) {
          break;
        }
      } catch (_) {
        if (_disposed || requestId != _requestSequence) return;
        _commitPagedState(
          charity: currentCharity,
          merged: merged,
          nextCursor: requestedCursor,
          hasMore: true,
          loadMoreErrorMessage: AppStrings.profileListingsLoadMoreFailed,
        );
        return;
      }
    }

    _commitPagedState(
      charity: currentCharity,
      merged: merged,
      nextCursor: cursor,
      hasMore: hasMore,
      loadMoreErrorMessage: null,
    );
  }

  void _commitPagedState({
    required Charity charity,
    required List<Product> merged,
    required String? nextCursor,
    required bool hasMore,
    required String? loadMoreErrorMessage,
  }) {
    final visible = _filterOwnedVisible(merged, charity.id).toList(growable: false);
    _charity = charity;
    _products = List.unmodifiable(visible);
    _nextCursor = nextCursor;
    _hasMore = hasMore;
    _status = CharityProfileStatus.loaded;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreErrorMessage = loadMoreErrorMessage;
    notifyListeners();
  }

  bool _appendVisibleProducts(
    List<Product> target,
    Set<String> seenIds,
    Iterable<Product> items,
    String charityId,
  ) {
    var added = false;
    for (final product in _filterOwnedVisible(items, charityId)) {
      if (seenIds.add(product.id)) {
        target.add(product);
        added = true;
      }
    }
    return added;
  }

  Iterable<Product> _filterOwnedVisible(
    Iterable<Product> items,
    String charityId,
  ) {
    return items.where(
      (product) =>
          product.charityId == charityId &&
          deletedListings?.contains(product.id) != true &&
          blockedUsers?.contains(product.userId) != true,
    );
  }

  void _onListingsChanged() {
    if (_disposed || (deletedListings == null && blockedUsers == null)) return;
    final filtered = _products
        .where(
          (product) =>
              deletedListings?.contains(product.id) != true &&
              blockedUsers?.contains(product.userId) != true,
        )
        .toList(growable: false);
    if (filtered.length != _products.length) {
      _products = List.unmodifiable(filtered);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    deletedListings?.removeListener(_onListingsChanged);
    blockedUsers?.removeListener(_onListingsChanged);
    super.dispose();
  }
}
