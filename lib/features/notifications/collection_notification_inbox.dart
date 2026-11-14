import 'package:flutter/foundation.dart';

class CollectionNotification {
  const CollectionNotification({required this.orderId, required this.userId, required this.eventId});
  final String orderId;
  final String userId;
  final String eventId;

  static CollectionNotification? parse(Map<String, dynamic> data) {
    String? identifier(String key) {
      final value = data[key];
      if (value is! String || value.isEmpty || value.length > 256 || RegExp(r'[/\\\s\x00-\x1f\x7f]').hasMatch(value)) {
        return null;
      }
      return value;
    }

    if (data['type'] != 'ready_to_collect') return null;
    final order = identifier('orderId');
    final user = identifier('userId');
    final event = identifier('eventId');
    if (order == null || user == null || event == null) return null;
    return CollectionNotification(orderId: order, userId: user, eventId: event);
  }
}

/// Push data is only a refresh hint. Order details and eligibility come from
/// the authenticated orders API, never from the notification payload.
class CollectionNotificationInbox extends ChangeNotifier {
  CollectionNotificationInbox({this.onTapReady});
  final VoidCallback? onTapReady;
  String? _userId;
  CollectionNotification? _pendingTap;
  final Set<String> _seen = {};

  CollectionNotification? pendingFor(String userId) =>
      userId == _userId && _pendingTap?.userId == userId ? _pendingTap : null;

  void setUser(String? userId) {
    final previous = _userId;
    _userId = userId;
    if (previous != null && previous != userId) _pendingTap = null;
    if (_pendingTap != null && userId != null && _pendingTap!.userId != userId) _pendingTap = null;
    if (_pendingTap != null && userId != null) {
      onTapReady?.call();
      notifyListeners();
    }
  }

  void receive(Map<String, dynamic> data, {required bool opened}) {
    final message = CollectionNotification.parse(data);
    if (message == null || (_userId != null && message.userId != _userId)) return;
    if (!opened && _userId == null) return;
    final key = '${message.userId}:${message.eventId}:$opened';
    if (!_seen.add(key)) return;
    if (_seen.length > 100) _seen.remove(_seen.first);
    if (opened) {
      _pendingTap = message;
      if (_userId != null) onTapReady?.call();
    }
    notifyListeners();
  }

  void consume(CollectionNotification message) {
    if (identical(_pendingTap, message)) _pendingTap = null;
  }
}
