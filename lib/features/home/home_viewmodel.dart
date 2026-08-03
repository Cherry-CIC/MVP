import 'dart:async';

import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';

class HomeViewModel extends ChangeNotifier {
  static const int defaultPageSize = 20;
  static const Duration searchDebounceDuration = Duration(milliseconds: 400);
  static const Duration loadMoreRetryBackoff = Duration(seconds: 3);

  final _log = Logger('HomeViewModel');
  final IHomeRepository homeRepository;
  final void Function(Iterable<Product>)? onProductsLoaded;

  HomeViewModel({required this.homeRepository, this.onProductsLoaded});

  // Private variables
  Status _status = Status.uninitialized;
  Status _searchStatus = Status.uninitialized;
  List<Product> _homeProducts = [];
  List<Product> _searchProducts = [];
  String? _nextCursor;
  String? _searchNextCursor;
  bool _hasMore = false;
  bool _searchHasMore = false;
  bool _isLoadingMore = false;
  bool _isLoadingMoreSearch = false;
  bool _isRefreshing = false;
  String _searchText = '';
  String _searchQuery = '';
  Timer? _searchDebounce;
  DateTime? _homeLoadMoreRetryAt;
  int _homeRequestSequence = 0;
  int _searchRequestSequence = 0;

  // Public getters
  Status get status => _status;
  List<Product> get products => _homeProducts;
  List<Product> get searchProducts => _searchProducts;
  String? get nextCursor => _nextCursor;
  String? get searchNextCursor => _searchNextCursor;
  bool get hasMore => _hasMore;
  bool get searchHasMore => _searchHasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  bool get isRefreshing => _isRefreshing;
  String get searchText => _searchText;
  String get searchQuery => _searchQuery;
  Status get searchStatus => _searchStatus;
  bool get hasActiveSearch => _searchText.isNotEmpty || _searchQuery.isNotEmpty;
  bool get isSearchLoading => _searchStatus.type == StatusType.loading;
  bool get isSearchEmpty =>
      _searchQuery.isNotEmpty && _searchStatus.type == StatusType.success && _searchProducts.isEmpty;

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _homeProducts.isNotEmpty && _status.type == StatusType.success) {
      return;
    }

    await _fetchHomeFirstPage(clearProducts: _homeProducts.isEmpty || forceRefresh);
  }

  Future<void> refreshProducts() async {
    await _fetchHomeFirstPage(clearProducts: false);
  }

  void updateSearchText(String query) {
    final normalizedQuery = query.trim();
    _searchText = normalizedQuery;
    _searchDebounce?.cancel();

    if (normalizedQuery.isEmpty) {
      clearSearch();
      return;
    }

    _searchStatus = Status.loading;
    notifyListeners();

    _searchDebounce = Timer(searchDebounceDuration, () {
      _runSearch(normalizedQuery);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchText = '';
    _searchQuery = '';
    _searchProducts = const [];
    _searchNextCursor = null;
    _searchHasMore = false;
    _isLoadingMoreSearch = false;
    _searchStatus = Status.uninitialized;
    _searchRequestSequence++;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) {
      return;
    }

    final retryAt = _homeLoadMoreRetryAt;
    if (retryAt != null && DateTime.now().isBefore(retryAt)) {
      return;
    }

    final requestId = _homeRequestSequence;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        cursor: _nextCursor,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _homeRequestSequence) {
          return;
        }
        final page = result.value!;
        final existingIds = _homeProducts.map((product) => product.id).toSet();
        final newProducts = page.products.where((product) => !existingIds.contains(product.id));
        _homeProducts = [..._homeProducts, ...newProducts];
        onProductsLoaded?.call(page.products);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _homeLoadMoreRetryAt = null;
      } else {
        _log.warning('Load more products failed! ${result.error}');
        _homeLoadMoreRetryAt = DateTime.now().add(loadMoreRetryBackoff);
      }
    } catch (e) {
      _log.severe('Load more products error: $e');
      _homeLoadMoreRetryAt = DateTime.now().add(loadMoreRetryBackoff);
    }

    if (requestId != _homeRequestSequence) {
      return;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMoreSearchProducts() async {
    if (_isLoadingMoreSearch || !_searchHasMore || _searchNextCursor == null || _searchQuery.isEmpty) {
      return;
    }

    final requestId = _searchRequestSequence;
    _isLoadingMoreSearch = true;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        cursor: _searchNextCursor,
        search: _searchQuery,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _searchRequestSequence) {
          return;
        }
        final page = result.value!;
        final existingIds = _searchProducts.map((product) => product.id).toSet();
        final newProducts = page.products.where((product) => !existingIds.contains(product.id));
        _searchProducts = [..._searchProducts, ...newProducts];
        onProductsLoaded?.call(page.products);
        _searchNextCursor = page.nextCursor;
        _searchHasMore = page.hasMore;
      } else {
        _log.warning('Load more search products failed! ${result.error}');
      }
    } catch (e) {
      _log.severe('Load more search products error: $e');
    }

    if (requestId != _searchRequestSequence) {
      return;
    }
    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  Future<void> _fetchHomeFirstPage({required bool clearProducts}) async {
    final requestId = ++_homeRequestSequence;
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
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _homeRequestSequence) {
          return;
        }
        final page = result.value!;
        _homeProducts = page.products;
        onProductsLoaded?.call(page.products);
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _status = Status.success;
      } else {
        if (requestId != _homeRequestSequence) {
          return;
        }
        _log.warning('Fetch products failed! ${result.error}');
        if (_homeProducts.isEmpty) {
          _status = Status.failure(result.error ?? 'Failed to load products');
        } else {
          _status = Status.success;
        }
      }
    } catch (e) {
      if (requestId != _homeRequestSequence) {
        return;
      }
      _log.severe('Fetch products error: $e');
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
    if (query != _searchText) {
      return;
    }

    final requestId = ++_searchRequestSequence;
    _searchQuery = query;
    _searchProducts = const [];
    _searchNextCursor = null;
    _searchHasMore = false;
    _isLoadingMoreSearch = false;
    _searchStatus = Status.loading;
    notifyListeners();

    try {
      final result = await homeRepository.fetchProducts(
        limit: defaultPageSize,
        search: query,
      );

      if (result.isSuccess && result.value != null) {
        if (requestId != _searchRequestSequence || query != _searchText) {
          return;
        }
        final page = result.value!;
        _searchProducts = page.products;
        onProductsLoaded?.call(page.products);
        _searchNextCursor = page.nextCursor;
        _searchHasMore = page.hasMore;
        _searchStatus = Status.success;
      } else {
        if (requestId != _searchRequestSequence || query != _searchText) {
          return;
        }
        _log.warning('Search products failed! ${result.error}');
        _searchProducts = const [];
        _searchStatus = Status.failure(result.error ?? 'Failed to search products');
      }
    } catch (e) {
      if (requestId != _searchRequestSequence || query != _searchText) {
        return;
      }
      _log.severe('Search products error: $e');
      _searchProducts = const [];
      _searchStatus = Status.failure('Failed to search products');
    }

    if (requestId != _searchRequestSequence || query != _searchText) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
