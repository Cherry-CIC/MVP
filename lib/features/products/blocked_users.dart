import 'dart:async';

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:flutter/foundation.dart';

/// Tracks seller IDs blocked by the currently signed-in user.
///
/// Hydrates from `/api/blocks` once per account session so blocked sellers stay
/// hidden across refreshes and app restarts, and notifies open views immediately
/// when a seller is blocked during the session.
class BlockedUsers extends ChangeNotifier {
  BlockedUsers({
    this._fetchBlockedUsers,
    this._currentUserIdProvider,
  });

  final Future<Result<Set<String>>> Function()? _fetchBlockedUsers;
  final String? Function()? _currentUserIdProvider;

  final Set<String> _ids = {};
  bool _hydrated = false;
  Future<void>? _pendingHydration;
  int _accountVersion = 0;
  bool _accountOwnerInitialised = false;
  String? _accountOwnerId;
  bool _accountChangeNotificationPending = false;
  bool _disposed = false;

  bool contains(String? userId) {
    _ensureCurrentAccount();
    final id = _normalizeId(userId);
    return id != null && _ids.contains(id);
  }

  Set<String> get ids {
    _ensureCurrentAccount();
    return Set.unmodifiable(_ids);
  }

  bool get isHydrated {
    _ensureCurrentAccount();
    return _hydrated;
  }

  /// Whether blocked-user state is known for the current account.
  ///
  /// Returns `true` when no remote fetcher is configured, when signed out, or
  /// after remote hydration succeeds.
  bool get isAuthoritative {
    _ensureCurrentAccount();
    if (_fetchBlockedUsers == null) return true;
    if (_currentUserIdProvider != null && _normalizeId(_currentUserIdProvider()) == null) {
      return true;
    }
    return _hydrated;
  }

  void add(String userId) {
    if (_disposed) return;
    _ensureCurrentAccount();
    final id = _normalizeId(userId);
    if (id == null || !_ids.add(id)) return;
    notifyListeners();
  }

  /// Ensures blocked users for the signed-in account have been loaded.
  ///
  /// Concurrent calls share the same in-flight request. Failures leave any
  /// locally recorded blocks intact and never block feed loading.
  Future<void> ensureHydrated({bool forceRefresh = false}) {
    if (_disposed) return Future<void>.value();
    _ensureCurrentAccount();

    final fetcher = _fetchBlockedUsers;
    if (fetcher == null) return Future<void>.value();

    if (_currentUserIdProvider != null && _normalizeId(_currentUserIdProvider()) == null) {
      return Future<void>.value();
    }

    if (!forceRefresh && _hydrated) {
      return Future<void>.value();
    }

    final pending = _pendingHydration;
    if (pending != null) {
      return pending;
    }

    final version = _accountVersion;
    final future = _hydrate(fetcher, version, replaceExisting: forceRefresh);
    _pendingHydration = future;
    return future;
  }

  Future<void> _hydrate(
    Future<Result<Set<String>>> Function() fetcher,
    int version, {
    required bool replaceExisting,
  }) async {
    final preExisting = Set<String>.from(_ids);
    try {
      final result = await fetcher();
      if (_disposed) return;
      _ensureCurrentAccount();
      if (version != _accountVersion) return;

      if (result.isSuccess && result.value != null) {
        final fetched = <String>{};
        for (final rawId in result.value!) {
          final id = _normalizeId(rawId);
          if (id != null) {
            fetched.add(id);
          }
        }

        // Preserve any block recorded locally while this fetch was in flight.
        final addedDuringFetch = _ids.difference(preExisting);
        final nextIds = replaceExisting ? {...fetched, ...addedDuringFetch} : {..._ids, ...fetched};
        final changed = !_setEquals(_ids, nextIds);
        if (changed) {
          _ids
            ..clear()
            ..addAll(nextIds);
        }
        _hydrated = true;
        if (changed) {
          notifyListeners();
        }
      }
    } catch (_) {
      // Leave locally recorded blocks intact and allow future retries.
    } finally {
      if (version == _accountVersion) {
        _pendingHydration = null;
      }
    }
  }

  void clear() {
    if (_disposed) return;
    final hadIds = _ids.isNotEmpty;
    _resetAccountState(_normalizeId(_currentUserIdProvider?.call()));
    _accountChangeNotificationPending = false;
    if (hadIds) {
      notifyListeners();
    }
  }

  void _ensureCurrentAccount() {
    final provider = _currentUserIdProvider;
    if (provider == null) return;

    final currentUserId = _normalizeId(provider());
    if (!_accountOwnerInitialised) {
      _accountOwnerId = currentUserId;
      _accountOwnerInitialised = true;
      return;
    }

    if (_accountOwnerId != currentUserId) {
      final hadIds = _ids.isNotEmpty;
      _resetAccountState(currentUserId);
      if (hadIds) {
        _scheduleAccountChangeNotification();
      }
    }
  }

  void _resetAccountState(String? currentUserId) {
    _ids.clear();
    _hydrated = false;
    _pendingHydration = null;
    _accountOwnerId = currentUserId;
    _accountOwnerInitialised = true;
    _accountVersion++;
  }

  void _scheduleAccountChangeNotification() {
    if (_accountChangeNotificationPending || _disposed) return;
    _accountChangeNotificationPending = true;
    Future<void>.microtask(() {
      if (!_accountChangeNotificationPending || _disposed) return;
      _accountChangeNotificationPending = false;
      notifyListeners();
    });
  }

  static String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool _setEquals(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  @override
  void dispose() {
    _disposed = true;
    _accountChangeNotificationPending = false;
    _accountVersion++;
    _pendingHydration = null;
    super.dispose();
  }
}
