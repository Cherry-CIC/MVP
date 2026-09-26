import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:flutter/foundation.dart';

enum PublicProfileStatus { loading, ready, unavailable, error }

/// Each public-profile route owns its state; it never reads the signed-in profile.
class PublicUserProfileViewModel extends ChangeNotifier {
  final String userId;
  final IPublicUserProfileRepository repository;

  PublicUserProfileViewModel({required this.userId, required this.repository});

  PublicProfileStatus _status = PublicProfileStatus.loading;
  PublicUser? _user;
  List<Product> _products = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _disposed = false;
  int _requestSequence = 0;

  PublicProfileStatus get status => _status;
  PublicUser? get user => _user;
  List<Product> get products => List.unmodifiable(_products);
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get loadMoreFailed => _loadMoreFailed;

  Future<void> loadProfile() async {
    if (_disposed) return;
    final request = ++_requestSequence;
    _clearProfile();
    _status = PublicProfileStatus.loading;
    notifyListeners();

    try {
      final result = await repository.fetchProfile(userId);
      if (!_isCurrent(request)) return;
      if (result.isSuccess && result.value != null) {
        _applyPage(result.value!);
        _status = PublicProfileStatus.ready;
      } else {
        _status = _isUnavailable(result.statusCode) ? PublicProfileStatus.unavailable : PublicProfileStatus.error;
      }
    } catch (_) {
      if (!_isCurrent(request)) return;
      _status = PublicProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_disposed || _status != PublicProfileStatus.ready || _isLoadingMore || !_hasMore) return;
    final cursor = _nextCursor;
    if (cursor == null) return;
    final request = _requestSequence;
    _isLoadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();

    try {
      final result = await repository.fetchProfile(userId, cursor: cursor);
      if (!_isCurrent(request)) return;
      if (result.isSuccess && result.value != null) {
        _applyPage(result.value!, append: true);
        // A repeated cursor must not cause endless requests for the same page.
        if (_nextCursor == cursor) {
          _hasMore = false;
          _nextCursor = null;
        }
      } else if (_isUnavailable(result.statusCode)) {
        _clearProfile();
        _status = PublicProfileStatus.unavailable;
      } else {
        _loadMoreFailed = true;
      }
    } catch (_) {
      if (!_isCurrent(request)) return;
      _loadMoreFailed = true;
    }
    if (!_isCurrent(request)) return;
    _isLoadingMore = false;
    notifyListeners();
  }

  void _applyPage(PublicUserProfilePage page, {bool append = false}) {
    _user = page.user;
    final seenIds = <String>{};
    _products = [
      if (append) ..._products,
      ...page.products,
    ].where((product) => seenIds.add(product.id)).toList(growable: false);
    final cursor = page.nextCursor?.trim();
    _nextCursor = cursor == null || cursor.isEmpty ? null : cursor;
    _hasMore = page.hasMore && _nextCursor != null;
  }

  void _clearProfile() {
    _user = null;
    _products = const [];
    _nextCursor = null;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreFailed = false;
  }

  bool _isCurrent(int request) => !_disposed && request == _requestSequence;

  bool _isUnavailable(int? statusCode) => statusCode == 404 || statusCode == 410;

  @override
  void dispose() {
    _disposed = true;
    _requestSequence++;
    super.dispose();
  }
}
