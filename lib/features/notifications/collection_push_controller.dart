import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'collection_notification_inbox.dart';
import 'notification_device_repository.dart';
import 'push_messaging_gateway.dart';

class CollectionPushController extends ChangeNotifier with WidgetsBindingObserver {
  CollectionPushController({
    required this.gateway,
    required this.repository,
    required this.preferences,
    required this.currentUserId,
    required Stream<String?> accountChanges,
    required this.inbox,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.add(accountChanges.distinct().listen(_accountChanged));
    _userId = currentUserId();
    inbox.setUser(_userId);
    if (gateway.supported) {
      _subscriptions.add(gateway.tokenChanges.listen((_) => unawaited(refresh()), onError: (_) {}));
      _subscriptions.add(
        gateway.foregroundMessages.listen((data) => inbox.receive(data, opened: false), onError: (_) {}),
      );
      _subscriptions.add(gateway.openedMessages.listen((data) => inbox.receive(data, opened: true), onError: (_) {}));
      unawaited(_start());
    }
  }
  final PushMessagingGateway gateway;
  final NotificationDeviceRepository repository;
  final SharedPreferences preferences;
  final String? Function() currentUserId;
  final CollectionNotificationInbox inbox;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  static const preferencePrefix = 'collectionPush.';
  static const _ownerKey = '${preferencePrefix}owner';
  static const _tokenKey = '${preferencePrefix}token';
  static const _rotateKey = '${preferencePrefix}rotate';
  String? _userId;
  int _generation = 0;
  bool _disposed = false;
  bool _suspended = false;
  bool _busy = false;
  bool _registered = false;
  PushPermission _permission = PushPermission.notDetermined;
  String? _error;
  Timer? _retry;
  Future<void> _queue = Future.value();
  bool get supported => gateway.supported;
  bool get busy => _busy;
  bool get enabled => _userId != null && preferences.getBool('${preferencePrefix}enabled.$_userId') == true;
  bool get registered => _registered;
  PushPermission get permission => _permission;
  String? get error => _error;

  bool _active(String userId, int generation) =>
      !_disposed && !_suspended && currentUserId() == userId && _userId == userId && _generation == generation;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (_disposed) return;
      try {
        await action();
      } catch (_) {
        _registered = false;
        _error = 'Notifications are unavailable. Please try again.';
        _notify();
      }
    });
    _queue = next;
    return next;
  }

  Future<void> _start() async {
    try {
      await gateway.configure().timeout(const Duration(seconds: 8));
      final initial = await gateway.initialMessage().timeout(const Duration(seconds: 8));
      if (!_disposed && initial != null) inbox.receive(initial, opened: true);
    } catch (_) {}
    if (!_disposed) await refresh();
  }

  void _accountChanged(String? userId) {
    if (_userId == userId) return;
    _generation++;
    _userId = userId;
    _suspended = false;
    _registered = false;
    _error = null;
    _retry?.cancel();
    inbox.setUser(userId);
    unawaited(refresh());
    _notify();
  }

  Future<void> refresh() => _serial(() async {
    if (!supported || _suspended) return;
    final uid = _userId;
    final generation = _generation;
    final owner = preferences.getString(_ownerKey);
    if (preferences.getBool(_rotateKey) == true || (owner != null && owner != uid)) {
      if (!await _resetDevice()) return;
    }
    if (uid == null || !_active(uid, generation)) return;
    _permission = await gateway.permission().timeout(const Duration(seconds: 8));
    if (!_active(uid, generation)) return;
    if (!enabled || _permission != PushPermission.allowed) {
      _registered = false;
      final disconnected = preferences.getString(_tokenKey) == null || await _resetDevice();
      if (disconnected && enabled) {
        _error = 'Notifications are off. You can allow them in your phone settings.';
      }
      _notify();
      return;
    }
    await preferences.setString(_ownerKey, uid);
    final token = await gateway.token().timeout(const Duration(seconds: 8));
    if (!_active(uid, generation)) return;
    if (token == null) {
      _registered = false;
      _error = 'Notifications are still connecting. Your collection reminders are available in cherry.';
      _notify();
      return;
    }
    final previous = preferences.getString(_tokenKey);
    if (previous != null && previous != token) {
      await repository.unregister(userId: uid, token: previous);
      if (!_active(uid, generation)) return;
    }
    // Save before the request so logout can revoke a registration even if the
    // request succeeds after a network timeout.
    await preferences.setString(_tokenKey, token);
    _registered = await repository.register(userId: uid, token: token, platform: gateway.platform);
    if (!_active(uid, generation)) {
      _registered = false;
      return;
    }
    _error = _registered
        ? null
        : 'Notifications could not connect. Please try again. Your reminders still work in cherry.';
    _notify();
  });

  Future<void> setEnabled(bool value) async {
    if (_busy || _userId == null || !supported) return;
    _busy = true;
    _error = null;
    _notify();
    final uid = _userId!;
    final generation = _generation;
    try {
      await _serial(() async {
        if (!_active(uid, generation)) return;
        if (value) {
          _permission = await gateway.permission(request: true);
          if (!_active(uid, generation)) return;
          await preferences.setBool('${preferencePrefix}enabled.$uid', _permission == PushPermission.allowed);
          if (_permission != PushPermission.allowed) {
            _error = 'Notifications are off. You can allow them in your phone settings.';
          }
        } else {
          await preferences.setBool('${preferencePrefix}enabled.$uid', false);
          await _resetDevice();
        }
      });
      if (_active(uid, generation) && enabled) {
        await refresh();
        // APNs registration may arrive after the permission dialogue closes.
        _retry?.cancel();
        if (!_registered) _retry = Timer(const Duration(seconds: 15), () => unawaited(refresh()));
      }
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> _resetDevice() async {
    _registered = false;
    await preferences.setBool(_rotateKey, true);
    final owner = preferences.getString(_ownerKey);
    final token = preferences.getString(_tokenKey);
    if (owner != null && token != null) await repository.unregister(userId: owner, token: token);
    try {
      await gateway.deleteToken().timeout(const Duration(seconds: 8));
      await preferences.remove(_tokenKey);
      await preferences.remove(_ownerKey);
      await preferences.remove(_rotateKey);
      return true;
    } catch (_) {
      _error = 'Notifications could not disconnect. Please reconnect to the internet and try again.';
      _notify();
      return false;
    }
  }

  /// Runs while the old authenticated session can still revoke its token.
  /// Failed offline cleanup is retained and retried before any new registration.
  Future<void> beforeSignOut() async {
    _suspended = true;
    _generation++;
    _retry?.cancel();
    inbox.setUser(null);
    if (supported) {
      await _serial(() async {
        await _resetDevice();
      });
    }
  }

  void afterSignOutAttempt() {
    if (currentUserId() != null) {
      _suspended = false;
      inbox.setUser(currentUserId());
      unawaited(refresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _suspended = false;
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
