import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';

enum LikedItemsStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

enum LikedItemsTab {
  items,
  charities,
}

class LikedItemsViewModel extends ChangeNotifier {
  LikedItemsViewModel({
    required this.productRepository,
    required this.productViewModel,
    this.deletedListings,
  }) {
    _accountStateVersion = productViewModel.accountStateVersion;
    productViewModel.addListener(_handleProductStateChange);
    deletedListings?.addListener(_removeDeletedListings);
  }

  final ProductRepository productRepository;
  final ProductViewModel productViewModel;
  final DeletedListings? deletedListings;
  late int _accountStateVersion;
  int _requestSequence = 0;
  int _charitiesRequestSequence = 0;
  bool _disposed = false;

  LikedItemsTab _selectedTab = LikedItemsTab.items;
  LikedItemsStatus _status = LikedItemsStatus.initial;
  List<Product> _products = const [];
  String? _errorMessage;

  LikedItemsStatus _charitiesStatus = LikedItemsStatus.initial;
  List<Charity> _charities = const [];
  String? _charitiesErrorMessage;

  LikedItemsTab get selectedTab => _selectedTab;
  LikedItemsStatus get status => _status;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;

  LikedItemsStatus get charitiesStatus => _charitiesStatus;
  List<Charity> get charities => _charities;
  String? get charitiesErrorMessage => _charitiesErrorMessage;

  void selectTab(LikedItemsTab tab) {
    if (_disposed || _selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();

    if (tab == LikedItemsTab.charities &&
        _charitiesStatus == LikedItemsStatus.initial) {
      unawaited(loadLikedCharities());
    } else if (tab == LikedItemsTab.items &&
        _status == LikedItemsStatus.initial) {
      unawaited(loadLikedProducts());
    }
  }

  Future<void> loadLikedProducts() async {
    if (_disposed) return;
    final request = ++_requestSequence;
    final accountStateVersion = productViewModel.accountStateVersion;
    _accountStateVersion = accountStateVersion;
    _status = LikedItemsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await productRepository.fetchLikedProducts();

    if (_disposed || request != _requestSequence) return;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return;
    }

    if (!result.isSuccess) {
      _products = const [];
      _status = LikedItemsStatus.error;
      _errorMessage = result.error ?? 'We couldn’t load your liked items.';
      notifyListeners();
      return;
    }

    _products = _mergeProducts(
      result.value ?? const [],
      productViewModel.cachedLikedProducts,
    );
    productViewModel.cacheLikedProducts(_products);
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    notifyListeners();
  }

  Future<bool> unlikeProduct(Product product) async {
    if (_disposed) return false;
    if (!_products.any((item) => item.id == product.id)) {
      return true;
    }

    final accountStateVersion = productViewModel.accountStateVersion;
    final result = await productViewModel.setProductLiked(product, false);
    if (_disposed) return false;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return false;
    }

    if (_isDeleted(product.id)) return true;

    if (!result.isSuccess) {
      _errorMessage = result.error ?? 'Unable to remove this liked item.';
      notifyListeners();
      return false;
    }

    // A deletion may have changed the list while the unlike request was pending.
    _products = List.unmodifiable(_products.where((item) => item.id != product.id));
    _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> loadLikedCharities() async {
    if (_disposed) return;
    final request = ++_charitiesRequestSequence;
    final accountStateVersion = productViewModel.accountStateVersion;
    final startRevision = productViewModel.charityMutationSequence;
    final fetchSequence = productViewModel.beginLikedCharitiesFetch();
    _accountStateVersion = accountStateVersion;
    _charitiesStatus = LikedItemsStatus.loading;
    _charitiesErrorMessage = null;
    notifyListeners();

    final result = await productRepository.fetchLikedCharities();

    if (_disposed || request != _charitiesRequestSequence) return;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return;
    }

    if (!result.isSuccess) {
      _charities = const [];
      _charitiesStatus = LikedItemsStatus.error;
      _charitiesErrorMessage =
          result.error ?? 'We couldn’t load your liked charities.';
      notifyListeners();
      return;
    }

    final fetchedCharities = result.value ?? const <Charity>[];
    productViewModel.reconcileLikedCharities(
      fetchedCharities,
      sinceMutationRevision: startRevision,
      fetchSequence: fetchSequence,
    );
    _charities = List<Charity>.unmodifiable(
      productViewModel.cachedLikedCharities,
    );
    _charitiesStatus =
        _charities.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    notifyListeners();
  }

  Future<bool> unlikeCharity(Charity charity) async {
    if (_disposed) return false;
    final resolvedTargetKey = _charityIdentityKey(charity);
    if (!_charities.any((item) => _charityIdentityKey(item) == resolvedTargetKey)) {
      return true;
    }

    final accountStateVersion = productViewModel.accountStateVersion;
    final result = await productViewModel.setCharityLiked(charity, false);
    if (_disposed) return false;
    if (!productViewModel.isAccountStateCurrent(accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return false;
    }

    if (!result.isSuccess) {
      _charitiesErrorMessage =
          result.error ?? 'Unable to remove this liked charity.';
      notifyListeners();
      return false;
    }

    _charities = List.unmodifiable(
      _charities.where((item) => _charityIdentityKey(item) != resolvedTargetKey),
    );
    _charitiesStatus =
        _charities.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    _charitiesErrorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> retry() {
    if (_selectedTab == LikedItemsTab.charities) {
      return loadLikedCharities();
    }
    return loadLikedProducts();
  }

  Future<void> retryCharities() {
    return loadLikedCharities();
  }

  void _clearProductsAfterAccountChange() {
    if (_disposed) return;
    _requestSequence++;
    _charitiesRequestSequence++;
    _accountStateVersion = productViewModel.accountStateVersion;
    _products = const [];
    _status = _selectedTab == LikedItemsTab.items
        ? LikedItemsStatus.empty
        : LikedItemsStatus.initial;
    _errorMessage = null;
    _charities = const [];
    _charitiesStatus = _selectedTab == LikedItemsTab.charities
        ? LikedItemsStatus.empty
        : LikedItemsStatus.initial;
    _charitiesErrorMessage = null;
    notifyListeners();
  }

  void _handleProductStateChange() {
    if (_disposed) return;
    if (!productViewModel.isAccountStateCurrent(_accountStateVersion)) {
      _clearProductsAfterAccountChange();
      return;
    }
    _removeDeletedListings();
    _syncCharitiesFromSharedState();
  }

  void _syncCharitiesFromSharedState() {
    if (_charitiesStatus != LikedItemsStatus.loaded &&
        _charitiesStatus != LikedItemsStatus.empty) {
      return;
    }

    final synced = List<Charity>.unmodifiable(
      productViewModel.cachedLikedCharities,
    );
    if (listEquals(synced, _charities)) {
      return;
    }

    _charities = synced;
    _charitiesStatus =
        _charities.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    notifyListeners();
  }

  String _charityIdentityKey(Charity charity) {
    final resolvedId = productViewModel.resolveCharityId(
      charity.id,
      charityName: charity.name,
    );
    if (resolvedId.isNotEmpty) {
      return resolvedId;
    }
    final normalizedName = DiscoverRepository.normalizeCharityName(charity.name);
    return normalizedName.isNotEmpty ? normalizedName : charity.id.trim();
  }

  List<Product> _mergeProducts(
    List<Product> primaryProducts,
    List<Product> cachedProducts,
  ) {
    final products = <Product>[];
    final seenProductIds = <String>{};

    for (final product in [...primaryProducts, ...cachedProducts]) {
      if (_isDeleted(product.id) || product.id.trim().isEmpty || !seenProductIds.add(product.id)) {
        continue;
      }
      products.add(product);
    }

    return List.unmodifiable(products);
  }

  bool _isDeleted(String id) => deletedListings?.contains(id) == true || productViewModel.isProductDeleted(id);

  void _removeDeletedListings() {
    if (_disposed) return;
    final products = _products.where((product) => !_isDeleted(product.id)).toList(growable: false);
    if (products.length == _products.length) return;
    _products = List.unmodifiable(products);
    if (_status == LikedItemsStatus.loaded || _status == LikedItemsStatus.empty) {
      _status = _products.isEmpty ? LikedItemsStatus.empty : LikedItemsStatus.loaded;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestSequence++;
    _charitiesRequestSequence++;
    productViewModel.removeListener(_handleProductStateChange);
    deletedListings?.removeListener(_removeDeletedListings);
    super.dispose();
  }
}
