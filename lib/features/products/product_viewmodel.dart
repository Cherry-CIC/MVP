import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/products/blocked_users.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/safety_repository.dart';

class ProductViewModel extends ChangeNotifier {
  Product? _product;

  // Centralized tracker: Map<ProductID, IsLiked>
  final Map<String, bool> _likedProducts = {};
  final Map<String, Product> _likedProductCache = {};
  final Map<String, int> _likeCountOverrides = {};
  final Set<String> _pendingLikeUpdates = {};

  // Centralized tracker for charities: Map<CharityID, IsLiked>
  final Map<String, bool> _likedCharities = {};
  final Map<String, Charity> _likedCharityCache = {};
  final Map<String, int> _charityLikeCountOverrides = {};
  final Map<String, Charity> _knownCharitiesById = {};
  final Map<String, Charity> _knownCharitiesByNormalizedName = {};
  final Set<String> _pendingCharityLikeUpdates = {};
  int _charityMutationSequence = 0;
  final Map<String, int> _charityMutationRevisions = {};
  int _likedCharitiesFetchSequence = 0;
  int _appliedLikedCharitiesFetchSequence = 0;

  final Set<String> _pendingSafetyActions = {};
  final String? Function() _currentUserIdProvider;
  int _accountStateVersion = 0;
  bool _accountOwnerInitialised = false;
  String? _accountOwnerId;
  Future<Result<void>>? _likedProductsHydration;
  int? _likedProductsHydrationVersion;
  Future<Result<void>>? _likedCharitiesHydration;
  int? _likedCharitiesHydrationVersion;
  Future<Result<void>>? _charitiesHydration;
  int? _charitiesHydrationVersion;
  bool _accountChangeNotificationPending = false;
  bool _disposed = false;

  Product? get product => _product;

  final ProductRepository productRepository;
  final SafetyRepository? safetyRepository;
  final NavigationProvider navigator;
  final DeletedListings? deletedListings;
  final BlockedUsers? blockedUsers;

  ProductViewModel({
    required this.productRepository,
    required this.navigator,
    this.safetyRepository,
    this.deletedListings,
    this.blockedUsers,
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? _unauthenticatedUserId {
    deletedListings?.addListener(_removeDeletedListings);
    blockedUsers?.addListener(_removeBlockedUsers);
  }

  static String? _unauthenticatedUserId() => null;

  int get accountStateVersion {
    _ensureCurrentAccount();
    return _accountStateVersion;
  }

  bool isAccountStateCurrent(int version) {
    if (_disposed) return false;
    _ensureCurrentAccount();
    return version == _accountStateVersion;
  }

  bool isOwnProduct(Product product) {
    _ensureCurrentAccount();
    final currentUserId = _accountOwnerId;
    return currentUserId != null && currentUserId.isNotEmpty && product.userId == currentUserId;
  }

  // Check if a specific product is liked
  bool isProductLiked(String productId) {
    _ensureCurrentAccount();
    if (isProductDeleted(productId)) return false;
    return _likedProducts[productId] ?? false;
  }

  bool isLikeUpdatePending(String productId) {
    _ensureCurrentAccount();
    return _pendingLikeUpdates.contains(productId);
  }

  bool isSafetyActionPending(String key) {
    _ensureCurrentAccount();
    return _pendingSafetyActions.contains(key);
  }

  List<Product> get cachedLikedProducts {
    _ensureCurrentAccount();
    final products = <Product>[];
    for (final entry in _likedProductCache.entries) {
      if (_likedProducts[entry.key] == true && !isProductHidden(entry.value)) {
        products.add(entry.value);
      }
    }
    return List.unmodifiable(products);
  }

  // Get dynamic count for a product
  int getLikesCount(Product product) {
    _ensureCurrentAccount();
    if (isProductDeleted(product.id)) return 0;
    return _likeCountOverrides[product.id] ?? product.likes;
  }

  int get charityMutationSequence {
    _ensureCurrentAccount();
    return _charityMutationSequence;
  }

  int beginLikedCharitiesFetch() {
    _ensureCurrentAccount();
    return ++_likedCharitiesFetchSequence;
  }

  bool hasCharityMutatedSince(
    String charityId,
    int sinceRevision, {
    String? charityName,
  }) {
    _ensureCurrentAccount();
    final resolvedId = resolveCharityId(charityId, charityName: charityName);
    final resolvedRevision = _charityMutationRevisions[resolvedId] ?? 0;
    final rawRevision = _charityMutationRevisions[charityId.trim()] ?? 0;
    return resolvedRevision > sinceRevision || rawRevision > sinceRevision;
  }

  String resolveCharityId(String? charityId, {String? charityName}) {
    final trimmedId = charityId?.trim() ?? '';
    if (trimmedId.isNotEmpty && _knownCharitiesById.containsKey(trimmedId)) {
      return trimmedId;
    }

    final trimmedName = charityName?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      final normalized = DiscoverRepository.normalizeCharityName(trimmedName);
      final knownByName = _knownCharitiesByNormalizedName[normalized];
      if (knownByName != null && knownByName.id.trim().isNotEmpty) {
        return knownByName.id.trim();
      }
    }

    if (trimmedId.isNotEmpty) {
      return trimmedId;
    }

    if (trimmedName.isNotEmpty) {
      final discoverMatch = DiscoverRepository().findCharity(name: trimmedName);
      if (discoverMatch?.id != null && discoverMatch!.id!.trim().isNotEmpty) {
        return discoverMatch.id!.trim();
      }
      return DiscoverRepository.normalizeCharityName(trimmedName);
    }

    return '';
  }

  bool isCharityLiked(String charityId, {String? charityName}) {
    _ensureCurrentAccount();
    final resolvedId = resolveCharityId(charityId, charityName: charityName);
    if (resolvedId.isNotEmpty && _likedCharities[resolvedId] == true) {
      return true;
    }
    final trimmedId = charityId.trim();
    if (trimmedId.isNotEmpty && _likedCharities[trimmedId] == true) {
      return true;
    }
    return false;
  }

  bool isCharityLikeUpdatePending(String charityId, {String? charityName}) {
    _ensureCurrentAccount();
    final resolvedId = resolveCharityId(charityId, charityName: charityName);
    return _pendingCharityLikeUpdates.contains(resolvedId) ||
        _pendingCharityLikeUpdates.contains(charityId.trim());
  }

  int getCharityLikesCount(
    String charityId, {
    String? charityName,
    int fallback = 0,
  }) {
    _ensureCurrentAccount();
    final resolvedId = resolveCharityId(charityId, charityName: charityName);
    final trimmedId = charityId.trim();
    return _charityLikeCountOverrides[resolvedId] ??
        _charityLikeCountOverrides[trimmedId] ??
        _knownCharitiesById[resolvedId]?.likes ??
        _knownCharitiesById[trimmedId]?.likes ??
        fallback;
  }

  List<Charity> get cachedLikedCharities {
    _ensureCurrentAccount();
    final charities = <Charity>[];
    for (final entry in _likedCharityCache.entries) {
      if (_likedCharities[entry.key] == true) {
        final count = _charityLikeCountOverrides[entry.key] ?? entry.value.likes;
        charities.add(entry.value.copyWith(likes: count));
      }
    }
    return List.unmodifiable(charities);
  }

  Future<Result<void>> hydrateCharities() {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final pendingHydration = _charitiesHydration;
    if (pendingHydration != null &&
        _charitiesHydrationVersion == accountStateVersion) {
      return pendingHydration;
    }

    final hydration = _hydrateCharities(accountStateVersion);
    _charitiesHydration = hydration;
    _charitiesHydrationVersion = accountStateVersion;
    return hydration;
  }

  Future<Result<void>> _hydrateCharities(int accountStateVersion) async {
    final startRevision = _charityMutationSequence;
    try {
      final result = await productRepository.fetchCharities();
      if (!isAccountStateCurrent(accountStateVersion)) {
        return Result.failure('Unable to load charities.');
      }
      if (!result.isSuccess) {
        return Result.failure(result.error ?? 'Unable to load charities.');
      }

      cacheCharities(
        result.value ?? const [],
        sinceMutationRevision: startRevision,
      );
      return Result.success(null);
    } finally {
      if (_charitiesHydrationVersion == accountStateVersion) {
        _charitiesHydration = null;
        _charitiesHydrationVersion = null;
      }
    }
  }

  Future<Result<void>> hydrateLikedCharities() {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final pendingHydration = _likedCharitiesHydration;
    if (pendingHydration != null &&
        _likedCharitiesHydrationVersion == accountStateVersion) {
      return pendingHydration;
    }

    final hydration = _hydrateLikedCharities(accountStateVersion);
    _likedCharitiesHydration = hydration;
    _likedCharitiesHydrationVersion = accountStateVersion;
    return hydration;
  }

  Future<Result<void>> _hydrateLikedCharities(int accountStateVersion) async {
    final startRevision = _charityMutationSequence;
    final fetchSequence = beginLikedCharitiesFetch();
    try {
      final result = await productRepository.fetchLikedCharities();
      if (!isAccountStateCurrent(accountStateVersion)) {
        return Result.failure('Unable to restore liked charities.');
      }

      if (!result.isSuccess) {
        return Result.failure(result.error ?? 'Unable to restore liked charities.');
      }

      reconcileLikedCharities(
        result.value ?? const <Charity>[],
        sinceMutationRevision: startRevision,
        fetchSequence: fetchSequence,
      );
      return Result.success(null);
    } finally {
      if (_likedCharitiesHydrationVersion == accountStateVersion) {
        _likedCharitiesHydration = null;
        _likedCharitiesHydrationVersion = null;
      }
    }
  }

  void _clearCachedLikedCharitiesState({bool notify = true}) {
    if (_likedCharities.isEmpty && _likedCharityCache.isEmpty) {
      return;
    }

    _likedCharities.clear();
    _likedCharityCache.clear();
    if (notify) {
      notifyListeners();
    }
  }

  Future<Result<void>> hydrateLikedProducts() {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final pendingHydration = _likedProductsHydration;
    if (pendingHydration != null && _likedProductsHydrationVersion == accountStateVersion) {
      return pendingHydration;
    }

    final hydration = _hydrateLikedProducts(accountStateVersion);
    _likedProductsHydration = hydration;
    _likedProductsHydrationVersion = accountStateVersion;
    return hydration;
  }

  Future<Result<void>> _hydrateLikedProducts(int accountStateVersion) async {
    try {
      _clearCachedLikedState();

      final blockedHydration = blockedUsers?.ensureHydrated();
      final result = await productRepository.fetchLikedProducts();
      if (blockedHydration != null) {
        await blockedHydration;
      }
      if (!isAccountStateCurrent(accountStateVersion)) {
        return Result.failure('Unable to restore liked items.');
      }

      if (!result.isSuccess) {
        return Result.failure(result.error ?? 'Unable to restore liked items.');
      }

      cacheLikedProducts(result.value ?? const []);
      return Result.success(null);
    } finally {
      if (_likedProductsHydrationVersion == accountStateVersion) {
        _likedProductsHydration = null;
        _likedProductsHydrationVersion = null;
      }
    }
  }

  void _clearCachedLikedState() {
    if (_likedProducts.isEmpty && _likedProductCache.isEmpty) {
      return;
    }

    _likedProducts.clear();
    _likedProductCache.clear();
    notifyListeners();
  }

  void setProduct(Product product) {
    if (_disposed || isProductHidden(product)) return;
    _product = product;
    notifyListeners();
  }

  void applyListingUpdate(Product product) {
    if (_disposed || isProductHidden(product)) return;
    if (_product?.id == product.id) {
      _product = product;
      notifyListeners();
    }
  }

  Future<Result<bool>> toggleLike(Product product) async {
    _ensureCurrentAccount();
    final String id = product.id;
    final bool currentStatus = _likedProducts[id] ?? false;

    return setProductLiked(product, !currentStatus);
  }

  Future<Result<bool>> setProductLiked(Product product, bool liked) async {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final id = product.id;
    if (_disposed ||
        isProductHidden(product) ||
        id.trim().isEmpty ||
        _pendingLikeUpdates.contains(id) ||
        (liked && isOwnProduct(product))) {
      return Result.failure('Unable to update this liked item.');
    }

    _pendingLikeUpdates.add(id);
    notifyListeners();

    final result = liked ? await productRepository.likeProduct(product) : await productRepository.unlikeProduct(id);

    if (!isAccountStateCurrent(accountStateVersion)) {
      return Result.failure('Unable to update this liked item.');
    }
    if (isProductHidden(product)) {
      _pendingLikeUpdates.remove(id);
      notifyListeners();
      return Result.failure('Unable to update this liked item.');
    }

    _pendingLikeUpdates.remove(id);

    final update = result.value;
    if (result.isSuccess && update != null && update.liked == liked) {
      _likedProducts[id] = update.liked;
      _likeCountOverrides[id] = update.likes;
      if (update.liked) {
        _likedProductCache[id] = product;
      } else {
        _likedProductCache.remove(id);
      }
      notifyListeners();
      return Result.success(update.liked);
    }

    notifyListeners();
    return Result.failure(result.error ?? 'Unable to update this liked item.');
  }

  Future<Result<bool>> toggleCharityLike(Charity charity) async {
    _ensureCurrentAccount();
    final resolvedId = resolveCharityId(charity.id, charityName: charity.name);
    final currentStatus = isCharityLiked(resolvedId, charityName: charity.name);

    return setCharityLiked(
      charity.copyWith(id: resolvedId.isNotEmpty ? resolvedId : charity.id),
      !currentStatus,
    );
  }

  Future<Result<bool>> setCharityLiked(Charity charity, bool liked) async {
    _ensureCurrentAccount();
    final accountStateVersion = _accountStateVersion;
    final id = resolveCharityId(charity.id, charityName: charity.name);
    if (_disposed ||
        id.trim().isEmpty ||
        _pendingCharityLikeUpdates.contains(id)) {
      return Result.failure('Unable to update this liked charity.');
    }

    final resolvedCharity = charity.copyWith(id: id);
    _pendingCharityLikeUpdates.add(id);
    notifyListeners();

    final result = liked
        ? await productRepository.likeCharity(resolvedCharity)
        : await productRepository.unlikeCharity(id);

    if (!isAccountStateCurrent(accountStateVersion)) {
      return Result.failure('Unable to update this liked charity.');
    }

    _pendingCharityLikeUpdates.remove(id);

    final update = result.value;
    if (result.isSuccess && update != null && update.liked == liked) {
      final updatedCharity = (update.charity ?? resolvedCharity).copyWith(
        id: id,
        name: resolvedCharity.name.trim().isNotEmpty
            ? resolvedCharity.name
            : update.charity?.name,
        likes: update.likes,
      );
      _registerKnownCharity(updatedCharity);
      _charityMutationRevisions[id] = ++_charityMutationSequence;
      _likedCharities[id] = update.liked;
      _charityLikeCountOverrides[id] = update.likes;
      if (update.liked) {
        _likedCharityCache[id] = updatedCharity;
      } else {
        _likedCharityCache.remove(id);
      }
      notifyListeners();
      return Result.success(update.liked);
    }

    notifyListeners();
    return Result.failure(result.error ?? 'Unable to update this liked charity.');
  }

  Future<Result<void>> reportProduct(
    Product product, {
    required String reason,
    String? message,
  }) {
    return _runSafetyAction(
      'report-product:${product.id}',
      () => _requireSafetyRepository().submitReport(
        targetType: ReportTargetType.product,
        targetId: product.id,
        reason: reason,
        message: message,
      ),
    );
  }

  Future<Result<void>> reportSeller(
    String sellerId, {
    required String reason,
    String? message,
  }) {
    return _runSafetyAction(
      'report-seller:$sellerId',
      () => _requireSafetyRepository().submitReport(
        targetType: ReportTargetType.user,
        targetId: sellerId,
        reason: reason,
        message: message,
      ),
    );
  }

  Future<Result<void>> blockSeller(String sellerId) async {
    final cleanSellerId = sellerId.trim();
    final result = await _runSafetyAction(
      'block-seller:$cleanSellerId',
      () => _requireSafetyRepository().blockUser(cleanSellerId),
    );
    if (result.isSuccess && cleanSellerId.isNotEmpty) {
      blockedUsers?.add(cleanSellerId);
    }
    return result;
  }

  /// Submits an abuse or accuracy report against [charityId].
  Future<Result<void>> reportCharity(
    String charityId, {
    required String reason,
    String? message,
  }) {
    return _runSafetyAction(
      'report-charity:$charityId',
      () => _requireSafetyRepository().submitReport(
        targetType: ReportTargetType.charity,
        targetId: charityId,
        reason: reason,
        message: message,
      ),
    );
  }

  /// Blocks [charityId] for the current user account.
  Future<Result<void>> blockCharity(String charityId) {
    return _runSafetyAction(
      'block-charity:$charityId',
      () => _requireSafetyRepository().blockCharity(charityId),
    );
  }

  Future<Result<void>> _runSafetyAction(
    String key,
    Future<Result<void>> Function() action,
  ) async {
    _ensureCurrentAccount();
    if (_pendingSafetyActions.contains(key)) {
      return Result.failure('Please wait for the current action to finish.');
    }

    _pendingSafetyActions.add(key);
    notifyListeners();

    final accountStateVersion = _accountStateVersion;
    try {
      final result = await action();
      if (!isAccountStateCurrent(accountStateVersion)) {
        return Result.failure('Please try again.');
      }
      return result;
    } catch (_) {
      return Result.failure('Please try again.');
    } finally {
      if (isAccountStateCurrent(accountStateVersion)) {
        _pendingSafetyActions.remove(key);
        notifyListeners();
      }
    }
  }

  SafetyRepository _requireSafetyRepository() {
    final repository = safetyRepository;
    if (repository == null) {
      throw StateError('SafetyRepository is not configured.');
    }
    return repository;
  }

  void setCachedLikeState(String productId, bool liked) {
    _ensureCurrentAccount();
    if (_disposed || isProductDeleted(productId) || productId.trim().isEmpty) {
      return;
    }

    _likedProducts[productId] = liked;
    if (!liked) {
      _likedProductCache.remove(productId);
    }
    notifyListeners();
  }

  void cacheLikedProducts(Iterable<Product> products) {
    if (_disposed) return;
    _ensureCurrentAccount();
    var changed = false;

    for (final product in products) {
      if (isProductHidden(product) || product.id.trim().isEmpty) {
        continue;
      }

      if (_likedProducts[product.id] != true) {
        _likedProducts[product.id] = true;
        changed = true;
      }

      if (_likedProductCache[product.id] != product) {
        _likedProductCache[product.id] = product;
        changed = true;
      }

      if (_likeCountOverrides[product.id] != product.likes) {
        _likeCountOverrides[product.id] = product.likes;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _registerKnownCharity(Charity charity) {
    final trimmedId = charity.id.trim();
    if (trimmedId.isEmpty) return;
    _knownCharitiesById[trimmedId] = charity;
    final normalizedName = DiscoverRepository.normalizeCharityName(charity.name);
    if (normalizedName.isNotEmpty) {
      _knownCharitiesByNormalizedName[normalizedName] = charity;
    }
  }

  void cacheCharities(
    Iterable<Charity> charities, {
    int? sinceMutationRevision,
  }) {
    if (_disposed) return;
    _ensureCurrentAccount();
    var changed = false;

    for (final charity in charities) {
      final id = charity.id.trim();
      if (id.isEmpty) continue;
      final previous = _knownCharitiesById[id];
      final mutatedSinceStart =
          sinceMutationRevision != null &&
          (_charityMutationRevisions[id] ?? 0) > sinceMutationRevision;
      if (mutatedSinceStart) {
        final preservedCount =
            _charityLikeCountOverrides[id] ?? previous?.likes ?? charity.likes;
        _registerKnownCharity(charity.copyWith(likes: preservedCount));
        continue;
      }
      _registerKnownCharity(charity);
      if (previous?.likes != charity.likes ||
          _charityLikeCountOverrides[id] != charity.likes) {
        _charityLikeCountOverrides[id] = charity.likes;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  bool reconcileLikedCharities(
    Iterable<Charity> fetchedCharities, {
    int? sinceMutationRevision,
    int? fetchSequence,
  }) {
    if (_disposed) return false;
    _ensureCurrentAccount();

    if (fetchSequence != null &&
        fetchSequence < _appliedLikedCharitiesFetchSequence) {
      return false;
    }
    if (fetchSequence != null) {
      _appliedLikedCharitiesFetchSequence = fetchSequence;
    }

    final mutatedIds = sinceMutationRevision == null
        ? const <String>{}
        : <String>{
            for (final entry in _charityMutationRevisions.entries)
              if (entry.value > sinceMutationRevision) entry.key,
          };
    final preservedLikedState = <String, bool>{
      for (final id in mutatedIds)
        if (_likedCharities.containsKey(id)) id: _likedCharities[id]!,
    };
    final preservedLikedCache = <String, Charity>{
      for (final id in mutatedIds)
        if (_likedCharityCache.containsKey(id)) id: _likedCharityCache[id]!,
    };

    _clearCachedLikedCharitiesState(notify: false);

    final seenIds = <String>{};
    for (final charity in fetchedCharities) {
      final id = charity.id.trim();
      if (id.isEmpty || !seenIds.add(id)) continue;
      if (mutatedIds.contains(id)) {
        final preservedCount =
            _charityLikeCountOverrides[id] ??
            _knownCharitiesById[id]?.likes ??
            charity.likes;
        _registerKnownCharity(charity.copyWith(likes: preservedCount));
        continue;
      }
      _registerKnownCharity(charity);
      _likedCharities[id] = true;
      _likedCharityCache[id] = charity;
      _charityLikeCountOverrides[id] = charity.likes;
    }

    for (final id in mutatedIds) {
      final liked = preservedLikedState[id];
      if (liked != null) {
        _likedCharities[id] = liked;
        if (liked) {
          final cached = preservedLikedCache[id] ?? _knownCharitiesById[id];
          if (cached != null) {
            _likedCharityCache[id] = cached;
          }
        }
      }
    }

    notifyListeners();
    return true;
  }

  void cacheLikedCharities(
    Iterable<Charity> charities, {
    int? sinceMutationRevision,
  }) {
    if (_disposed) return;
    _ensureCurrentAccount();
    var changed = false;

    for (final charity in charities) {
      final id = charity.id.trim();
      if (id.isEmpty) {
        continue;
      }

      final mutatedSinceStart =
          sinceMutationRevision != null &&
          (_charityMutationRevisions[id] ?? 0) > sinceMutationRevision;
      if (mutatedSinceStart) {
        continue;
      }

      _registerKnownCharity(charity);

      if (_likedCharities[id] != true) {
        _likedCharities[id] = true;
        changed = true;
      }

      if (_likedCharityCache[id] != charity) {
        _likedCharityCache[id] = charity;
        changed = true;
      }

      if (_charityLikeCountOverrides[id] != charity.likes) {
        _charityLikeCountOverrides[id] = charity.likes;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void reconcileProductCounts(Iterable<Product> products) {
    var changed = false;

    for (final product in products) {
      if (_likeCountOverrides.remove(product.id) != null) {
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void clearUserState() {
    if (_disposed) {
      return;
    }

    _resetAccountState(_currentUserIdProvider());
    blockedUsers?.clear();
    _accountChangeNotificationPending = false;
    notifyListeners();
  }

  void _ensureCurrentAccount() {
    final currentUserId = _currentUserIdProvider();
    if (!_accountOwnerInitialised) {
      _accountOwnerId = currentUserId;
      _accountOwnerInitialised = true;
      return;
    }

    if (_accountOwnerId != currentUserId) {
      _resetAccountState(currentUserId);
      _scheduleAccountChangeNotification();
    }
  }

  void _scheduleAccountChangeNotification() {
    if (_accountChangeNotificationPending || _disposed) {
      return;
    }

    _accountChangeNotificationPending = true;
    Future<void>.microtask(() {
      if (!_accountChangeNotificationPending || _disposed) {
        return;
      }

      _accountChangeNotificationPending = false;
      notifyListeners();
    });
  }

  void _resetAccountState(String? currentUserId) {
    _likedProducts.clear();
    _likedProductCache.clear();
    _pendingLikeUpdates.clear();
    _likedCharities.clear();
    _likedCharityCache.clear();
    _pendingCharityLikeUpdates.clear();
    _charityMutationRevisions.clear();
    _charityMutationSequence += 1;
    _likedCharitiesFetchSequence = 0;
    _appliedLikedCharitiesFetchSequence = 0;
    _pendingSafetyActions.clear();
    _likedProductsHydration = null;
    _likedProductsHydrationVersion = null;
    _likedCharitiesHydration = null;
    _likedCharitiesHydrationVersion = null;
    _charitiesHydration = null;
    _charitiesHydrationVersion = null;
    _accountOwnerId = currentUserId;
    _accountOwnerInitialised = true;
    _accountStateVersion += 1;
  }

  // For the Product Page (the currently active product)
  bool get isCurrentProductLiked => _product != null && isProductLiked(_product!.id);
  int get currentProductLikesCount => _product == null ? 0 : getLikesCount(_product!);

  Future<void> showPurchaseSecurity() async {
    await navigator.showPurchaseSecurity();
  }

  void goToProductPage(Product product) async {
    if (_disposed || isProductHidden(product)) return;
    setProduct(product);
    await navigator.navigateTo(AppRoutes.product, arguments: product);
  }

  bool isProductDeleted(String productId) => deletedListings?.contains(productId) == true;

  bool isSellerBlocked(String? userId) => blockedUsers?.contains(userId) == true;

  bool isProductHidden(Product product) => isProductDeleted(product.id) || isSellerBlocked(product.userId);

  void _removeDeletedListings() {
    if (_disposed) return;
    var changed = false;
    if (_product != null && isProductDeleted(_product!.id)) {
      _product = null;
      changed = true;
    }
    for (final id in {
      ..._likedProducts.keys,
      ..._likedProductCache.keys,
      ..._likeCountOverrides.keys,
      ..._pendingLikeUpdates,
    }) {
      if (!isProductDeleted(id)) continue;
      _likedProducts.remove(id);
      _likedProductCache.remove(id);
      _likeCountOverrides.remove(id);
      _pendingLikeUpdates.remove(id);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _removeBlockedUsers() {
    if (_disposed) return;
    var changed = false;
    if (_product != null && isSellerBlocked(_product!.userId)) {
      _product = null;
      changed = true;
    }
    final blockedProductIds = <String>[
      for (final entry in _likedProductCache.entries)
        if (isSellerBlocked(entry.value.userId)) entry.key,
    ];
    for (final id in blockedProductIds) {
      _likedProducts.remove(id);
      _likedProductCache.remove(id);
      _likeCountOverrides.remove(id);
      _pendingLikeUpdates.remove(id);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _accountChangeNotificationPending = false;
    deletedListings?.removeListener(_removeDeletedListings);
    blockedUsers?.removeListener(_removeBlockedUsers);
    super.dispose();
  }
}
