import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
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
  CharityProfileViewModel({
    required this.args,
    required this.repository,
    this.deletedListings,
    this.pageSize = 20,
  }) {
    deletedListings?.addListener(_onListingsChanged);
  }

  final CharityProfileArgs args;
  final ICharityProfileRepository repository;
  final DeletedListings? deletedListings;
  final int pageSize;

  CharityProfileStatus _status = CharityProfileStatus.initial;
  Charity? _charity;
  List<Product> _products = const [];
  String? _errorMessage;
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _requestSequence = 0;
  bool _disposed = false;

  CharityProfileStatus get status => _status;
  Charity? get charity => _charity ?? args.charity;
  List<Product> get products => _products;
  String? get errorMessage => _errorMessage;
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
    _isLoadingMore = false;
    _charity = args.charity;
    notifyListeners();

    final charityResult = await repository.fetchCharity(
      charityId: args.charityId ?? args.charity?.id,
      charityName: args.charityName ?? args.charity?.name,
    );
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

    _applyInitialProductsResult(resolvedCharity, productsResult);
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
    notifyListeners();

    final result = await repository.fetchProducts(
      currentCharity,
      limit: pageSize,
      cursor: _nextCursor,
    );
    if (_disposed || requestId != _requestSequence) return;

    _isLoadingMore = false;
    if (result.isSuccess && result.value != null) {
      final merged = List<Product>.from(_products);
      final seenIds = merged.map((p) => p.id).toSet();
      for (final product in _filterOwnedVisible(
        result.value!.products,
        currentCharity.id,
      )) {
        if (seenIds.add(product.id)) {
          merged.add(product);
        }
      }
      _products = List.unmodifiable(merged);
      _nextCursor = result.value!.nextCursor;
      _hasMore = result.value!.hasMore;
    }
    notifyListeners();
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
    notifyListeners();
  }

  void _applyInitialProductsResult(
    Charity resolvedCharity,
    Result<CharityProfilePageData> result,
  ) {
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
    _charity = page.charity;
    _products = List.unmodifiable(
      _filterOwnedVisible(page.products, resolvedCharity.id),
    );
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    _status = CharityProfileStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  Iterable<Product> _filterOwnedVisible(
    Iterable<Product> items,
    String charityId,
  ) {
    return items.where(
      (product) =>
          product.charityId == charityId &&
          deletedListings?.contains(product.id) != true,
    );
  }

  void _onListingsChanged() {
    if (_disposed || deletedListings == null) return;
    final filtered = _products
        .where((product) => deletedListings!.contains(product.id) != true)
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
    super.dispose();
  }
}
