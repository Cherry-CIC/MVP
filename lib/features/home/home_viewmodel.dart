import 'dart:async';

import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/search/recent_searches_store.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:flutter/cupertino.dart';

class HomeViewModel extends ChangeNotifier {
  static const int defaultPageSize = 20;
  static const Duration searchDebounceDuration = Duration(milliseconds: 400);
  static const Duration loadMoreRetryBackoff = Duration(seconds: 3);

  final IHomeRepository homeRepository;
  final void Function(Iterable<Product>)? onProductsLoaded;
  final DeletedListings? deletedListings;
  final RecentSearchesStore _recentSearchesStore;

  HomeViewModel({
    required this.homeRepository,
    this.onProductsLoaded,
    this.deletedListings,
    RecentSearchesStore? recentSearchesStore,
  }) : _recentSearchesStore = recentSearchesStore ?? RecentSearchesStore.inMemory() {
    _recentSearches = _recentSearchesStore.load();
    deletedListings?.addListener(_removeDeletedListings);
  }

  // Private variables
  Status _status = Status.uninitialized;
  Status _searchStatus = Status.uninitialized;
  List<Product> _homeProducts = [];
  List<Product> _searchProducts = [];
  List<String> _recentSearches = const [];
  String? _nextCursor;
  String? _searchNextCursor;
  bool _hasMore = false;
  bool _searchHasMore = false;
  bool _isLoadingMore = false;
  bool _isLoadingMoreSearch = false;
  bool _isRefreshing = false;
  Category? _homeCategory;
  String _searchText = '';
  String _searchQuery = '';
  Category? _searchCategory;
  String? _searchLoadMoreError;
  Timer? _searchDebounce;
  DateTime? _homeLoadMoreRetryAt;
  int _homeRequestSequence = 0;
  int _searchRequestSequence = 0;
  bool _disposed = false;

  // Public getters
  Status get status => _status;
  List<Product> get products => _homeProducts;
  List<Product> get searchProducts => _searchProducts;
  List<String> get recentSearches => _recentSearches;
  String? get nextCursor => _nextCursor;
  String? get searchNextCursor => _searchNextCursor;
  bool get hasMore => _hasMore;
  bool get searchHasMore => _searchHasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  bool get isRefreshing => _isRefreshing;
  Category? get homeCategory => _homeCategory;
  String get searchText => _searchText;
  String get searchQuery => _searchQuery;
  Status get searchStatus => _searchStatus;
  Category? get searchCategory => _searchCategory;
  String? get searchLoadMoreError => _searchLoadMoreError;
  bool get hasActiveSearch => _searchText.isNotEmpty || _searchCategory != null;
  bool get isSearchLoading => _searchStatus.type == StatusType.loading;
  bool get isSearchEmpty =>
      hasActiveSearch && _searchStatus.type == StatusType.success && _searchProducts.isEmpty && !_searchHasMore;

  Future<void> selectHomeCategory(Category? category) async {
    if (_disposed || category?.id == _homeCategory?.id) return;
    _homeCategory = category;
    await _fetchHomeFirstPage(clearProducts: true);
  }

  void loadRecentSearches() {
    if (_disposed) return;
    final loaded = _recentSearchesStore.load();
    if (_recentSearches.length == loaded.length &&
        _recentSearches.indexed.every((e) => loaded[e.$1] == e.$2)) {
      return;
    }
    _recentSearches = loaded;
    notifyListeners();
  }

  Future<void> recordRecentSearch(String query) async {
    if (_disposed) return;
    final normalized = RecentSearchesStore.normalize(query);
    if (normalized.isEmpty) return;
    _recentSearches = List<String>.unmodifiable(
      <String>[
        normalized,
        ..._recentSearches.where((entry) => entry.toLowerCase() != normalized.toLowerCase()),
      ].take(RecentSearchesStore.maxEntries),
    );
    notifyListeners();
    final persisted = await _recentSearchesStore.add(normalized);
    if (!_disposed) {
      _recentSearches = persisted;
      notifyListeners();
    }
  }

  Future<void> removeRecentSearch(String query) async {
    if (_disposed) return;
    final normalized = RecentSearchesStore.normalize(query).toLowerCase();
    _recentSearches = List<String>.unmodifiable(
      _recentSearches.where((entry) => entry.toLowerCase() != normalized),
    );
    notifyListeners();
    final persisted = await _recentSearchesStore.remove(query);
    if (!_disposed) {
      _recentSearches = persisted;
      notifyListeners();
    }
  }

  Future<void> clearRecentSearches() async {
    if (_disposed) return;
    _recentSearches = const [];
    notifyListeners();
    await _recentSearchesStore.clear();
  }

  Future<void> submitSearch(String query) async {
    if (_disposed) return;
    final normalized = RecentSearchesStore.normalize(query);
    _searchText = normalized;
    _prepareSearch();
    if (normalized.isNotEmpty) {
      unawaited(recordRecentSearch(normalized));
    }
    if (hasActiveSearch) {
      await _runSearch(normalized);
    }
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (_disposed) return;
    if (!forceRefresh && _homeProducts.isNotEmpty && _status.type == StatusType.success) {
      return;
    }

    await _fetchHomeFirstPage(clearProducts: _homeProducts.isEmpty || forceRefresh);
  }

  Future<void> refreshProducts() async {
    await _fetchHomeFirstPage(clearProducts: false);
  }

  /// Recheck both visible feeds while retaining surviving home cards on failure.
  Future<void> refreshAfterListingDeletion() async {
    if (_disposed) return;
    _searchDebounce?.cancel();
    final query = _searchText;
    await Future.wait([
      refreshProducts(),
      if (hasActiveSearch) _runSearch(query),
    ]);
  }

  /// Discard pre-edit cards and requests before loading the latest listing data.
  Future<void> refreshAfterListingEdit() async {
    if (_disposed) return;
    _searchDebounce?.cancel();
    final query = _searchText;
    _searchRequestSequence++;
    _searchProducts = const [];
    _searchNextCursor = null;
    _searchHasMore = false;
    _isLoadingMoreSearch = false;
    _searchQuery = query;
    _searchStatus = hasActiveSearch ? Status.loading : Status.uninitialized;
    _searchLoadMoreError = null;
    _isRefreshing = false;

    await Future.wait([
      _fetchHomeFirstPage(clearProducts: true),
      if (hasActiveSearch) _runSearch(query),
    ]);
  }

  void updateSearchText(String query) {
    if (_disposed) return;
    final normalizedQuery = query.trim();
    if (normalizedQuery == _searchText) return;
    _searchText = normalizedQuery;
    _prepareSearch();
    if (!hasActiveSearch) return;

    _searchDebounce = Timer(searchDebounceDuration, () {
      _runSearch(normalizedQuery);
    });
  }

  Future<void> selectSearchCategory(Category? category) async {
    if (_disposed || category?.id == _searchCategory?.id) return;
    _searchCategory = category;
    _prepareSearch();
    if (hasActiveSearch) await _runSearch(_searchText);
  }

  Future<void> retrySearch() async {
    if (_disposed || !hasActiveSearch) return;
    await _runSearch(_searchText);
  }

  void clearSearch() {
    if (_disposed) return;
    _searchText = '';
    _searchCategory = null;
    _prepareSearch();
  }

  // Invalidate previous requests immediately, including during the typing delay.
  void _prepareSearch() {
    _searchDebounce?.cancel();
    _searchRequestSequence++;
    _searchQuery = _searchText;
    _searchProducts = const [];
    _searchNextCursor = null;
    _searchHasMore = false;
    _isLoadingMoreSearch = false;
    _searchLoadMoreError = null;
    _searchStatus = hasActiveSearch ? Status.loading : Status.uninitialized;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    if (_disposed || _isLoadingMore || !_hasMore || _nextCursor == null) {
      return;
    }

    final retryAt = _homeLoadMoreRetryAt;
    if (retryAt != null && DateTime.now().isBefore(retryAt)) {
      return;
    }

    final requestId = _homeRequestSequence;
    final categoryId = _homeCategory?.id;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        cursor: _nextCursor,
        categoryId: categoryId,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _homeRequestSequence) {
          return;
        }
        final page = result.value!;
        final existingIds = _homeProducts.map((product) => product.id).toSet();
        final visibleProducts = _visibleProducts(page.products);
        final newProducts = visibleProducts.where((product) => !existingIds.contains(product.id));
        _homeProducts = [..._homeProducts, ...newProducts];
        onProductsLoaded?.call(visibleProducts);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _homeLoadMoreRetryAt = null;
      } else {
        SafeLog.event(
          AppLogEvent.homeProductsLoadFailed,
          level: SafeLogLevel.warning,
        );
        _homeLoadMoreRetryAt = DateTime.now().add(loadMoreRetryBackoff);
      }
    } catch (_) {
      SafeLog.event(
        AppLogEvent.homeProductsLoadFailed,
        level: SafeLogLevel.severe,
      );
      _homeLoadMoreRetryAt = DateTime.now().add(loadMoreRetryBackoff);
    }

    if (requestId != _homeRequestSequence) {
      return;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMoreSearchProducts() async {
    if (_disposed || _isLoadingMoreSearch || !_searchHasMore || _searchNextCursor == null || !hasActiveSearch) {
      return;
    }

    final requestId = _searchRequestSequence;
    _isLoadingMoreSearch = true;
    _searchLoadMoreError = null;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        cursor: _searchNextCursor,
        search: _searchQuery,
        categoryId: _searchCategory?.id,
      );

      if (requestId != _searchRequestSequence) return;

      if (result.isSuccess && result.value != null) {
        final page = result.value!;
        final existingIds = _searchProducts.map((product) => product.id).toSet();
        final visibleProducts = _visibleProducts(page.products);
        final newProducts = visibleProducts.where((product) => !existingIds.contains(product.id));
        _searchProducts = [..._searchProducts, ...newProducts];
        onProductsLoaded?.call(visibleProducts);
        _searchNextCursor = page.nextCursor;
        _searchHasMore = page.hasMore;
      } else {
        _searchLoadMoreError = 'Could not load more items. Please try again.';
        SafeLog.event(
          AppLogEvent.homeSearchFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      if (requestId != _searchRequestSequence) return;
      _searchLoadMoreError = 'Could not load more items. Please try again.';
      SafeLog.event(
        AppLogEvent.homeSearchFailed,
        level: SafeLogLevel.severe,
      );
    }

    if (requestId != _searchRequestSequence) {
      return;
    }
    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  Future<void> _fetchHomeFirstPage({required bool clearProducts}) async {
    if (_disposed) return;
    final requestId = ++_homeRequestSequence;
    final categoryId = _homeCategory?.id;
    _isLoadingMore = false;
    if (clearProducts) {
      _homeProducts = const [];
      _status = Status.loading;
    } else if (_homeProducts.isEmpty) {
      _status = Status.loading;
    } else {
      _isRefreshing = true;
    }
    _nextCursor = null;
    _hasMore = false;
    _homeLoadMoreRetryAt = null;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        categoryId: categoryId,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _homeRequestSequence) {
          return;
        }
        final page = result.value!;
        _homeProducts = _visibleProducts(page.products);
        onProductsLoaded?.call(_homeProducts);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _status = Status.success;
      } else {
        if (requestId != _homeRequestSequence) {
          return;
        }
        SafeLog.event(
          AppLogEvent.homeProductsLoadFailed,
          level: SafeLogLevel.warning,
        );
        if (_homeProducts.isEmpty) {
          _status = Status.failure(result.error ?? 'Failed to load products');
        } else {
          _status = Status.success;
        }
      }
    } catch (_) {
      if (requestId != _homeRequestSequence) {
        return;
      }
      SafeLog.event(
        AppLogEvent.homeProductsLoadFailed,
        level: SafeLogLevel.severe,
      );
      if (_homeProducts.isEmpty) {
        _status = Status.failure('Failed to load products');
      } else {
        _status = Status.success;
      }
    }

    if (requestId != _homeRequestSequence) {
      return;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _runSearch(String query) async {
    if (_disposed || query != _searchText || !hasActiveSearch) return;

    _prepareSearch();
    final requestId = _searchRequestSequence;
    final categoryId = _searchCategory?.id;

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        search: query,
        categoryId: categoryId,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _searchRequestSequence || query != _searchText) {
          return;
        }
        final page = result.value!;
        _searchProducts = _visibleProducts(page.products);
        onProductsLoaded?.call(_searchProducts);
        _searchNextCursor = page.nextCursor;
        _searchHasMore = page.hasMore;
        _searchStatus = Status.success;
      } else {
        if (requestId != _searchRequestSequence || query != _searchText) {
          return;
        }
        SafeLog.event(
          AppLogEvent.homeSearchFailed,
          level: SafeLogLevel.warning,
        );
        _searchProducts = const [];
        _searchStatus = Status.failure(result.error ?? 'Failed to search products');
      }
    } catch (_) {
      if (requestId != _searchRequestSequence || query != _searchText) {
        return;
      }
      SafeLog.event(
        AppLogEvent.homeSearchFailed,
        level: SafeLogLevel.severe,
      );
      _searchProducts = const [];
      _searchStatus = Status.failure('Failed to search products');
    }

    if (requestId != _searchRequestSequence || query != _searchText) {
      return;
    }
    notifyListeners();
  }

  List<Product> _visibleProducts(Iterable<Product> products) =>
      products.where((product) => deletedListings?.contains(product.id) != true).toList(growable: false);

  void _removeDeletedListings() {
    if (_disposed) return;
    final homeProducts = _visibleProducts(_homeProducts);
    final searchProducts = _visibleProducts(_searchProducts);
    if (homeProducts.length == _homeProducts.length && searchProducts.length == _searchProducts.length) return;
    _homeProducts = homeProducts;
    _searchProducts = searchProducts;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _homeRequestSequence++;
    _searchRequestSequence++;
    _searchDebounce?.cancel();
    deletedListings?.removeListener(_removeDeletedListings);
    super.dispose();
  }
}
