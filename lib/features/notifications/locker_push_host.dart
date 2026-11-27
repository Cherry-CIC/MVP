import 'dart:async';

import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/notifications/push_messaging_gateway.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LockerPushHost extends StatefulWidget {
  const LockerPushHost({
    super.key,
    required this.gateway,
    required this.userId,
    required this.foregroundAlertsEnabled,
    required this.child,
  });

  final PushMessagingGateway gateway;
  final String userId;
  final bool Function() foregroundAlertsEnabled;
  final Widget child;

  @override
  State<LockerPushHost> createState() => _LockerPushHostState();
}

class _LockerPushHostState extends State<LockerPushHost> {
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _shown = <String>{};
  final _opened = <String>{};
  late final FirebaseAuth _auth;
  ScaffoldMessengerState? _bannerHost;
  MaterialPageRoute<void>? _orderRoute;
  int _session = 0;

  bool _isActive(int session) => mounted && _session == session && _auth.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _auth = context.read<FirebaseAuth>();
    _subscriptions.add(
      _auth.authStateChanges().listen((user) {
        if (user?.uid != widget.userId) {
          _session++;
          _dismiss();
        }
      }),
    );
    _subscriptions.add(widget.gateway.foregroundMessages.listen((data) => _receive(data, tapped: false)));
    _subscriptions.add(widget.gateway.openedMessages.listen((data) => _receive(data, tapped: true)));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final session = _session;
      try {
        final data = await widget.gateway.initialMessage();
        if (data != null && _isActive(session)) await _receive(data, tapped: true);
      } catch (_) {
        // Messaging can be unavailable on a device without Google Play services.
      }
    });
  }

  // Bound de-duplication to this signed-in session. A foreground banner may
  // still be opened by an intentional tap on the same notification.
  bool _remember(Set<String> seen, String id) {
    if (!seen.add(id)) return false;
    if (seen.length > 100) seen.remove(seen.first);
    return true;
  }

  Future<void> _receive(Map<String, dynamic> data, {required bool tapped}) async {
    final orderId = data['entityId'];
    final id = data['notificationId'];
    final session = _session;
    if (!_isActive(session) ||
        data['notificationType'] != 'locker_ready' ||
        data['entityType'] != 'order' ||
        orderId is! String ||
        orderId.trim().isEmpty ||
        orderId.length > 1500 ||
        orderId == '.' ||
        orderId == '..' ||
        orderId.contains('/') ||
        id is! String ||
        id.trim().isEmpty ||
        id.length > 128) {
      return;
    }

    if (tapped) {
      if (_remember(_opened, id)) _open(orderId, session);
      return;
    }
    if (!widget.foregroundAlertsEnabled() || _opened.contains(id) || !_remember(_shown, id)) return;
    final lookup = await _readOrder(orderId, session);
    if (!mounted ||
        !_isActive(session) ||
        !widget.foregroundAlertsEnabled() ||
        _opened.contains(id) ||
        lookup.value?.awaitingPickup != true) {
      return;
    }
    _hideBanner();
    final host = ScaffoldMessenger.of(context);
    _bannerHost = host;
    host.showMaterialBanner(
      MaterialBanner(
        content: Semantics(liveRegion: true, child: const Text('Your parcel is ready to collect.')),
        actions: [
          TextButton(onPressed: _hideBanner, child: const Text('Dismiss')),
          TextButton(
            onPressed: () {
              if (_isActive(session) && _remember(_opened, id)) _open(orderId, session);
            },
            child: const Text('View order'),
          ),
        ],
      ),
    );
  }

  Future<Result<_BuyerOrder>> _readOrder(String orderId, int session) async {
    if (!_isActive(session)) return Result.failure('Order unavailable');
    try {
      final result = await context.read<ApiService>().get<dynamic>(ApiEndpoints.buyerOrder(orderId));
      if (!_isActive(session) || !result.isSuccess) {
        return Result.failure('Could not load order', statusCode: result.statusCode);
      }
      final response = result.value;
      final data = response is Map && response['success'] == true ? response['data'] : null;
      final json = data is Map ? data['order'] : null;
      final summary = OrderSummary.tryFromOrderJson(json);
      if (json is! Map || summary == null || summary.id != orderId || json['userId'] != widget.userId) {
        return Result.failure('Order unavailable', statusCode: 404);
      }
      final shipment = json['shipment'];
      final point = shipment is Map ? shipment['pickupPoint'] : null;
      final name = point is Map ? point['name'] : null;
      final awaitingPickup =
          summary.deliveryState == 'shipped' &&
          json['paymentStatus'] == 'succeeded' &&
          json['deliveryType'] == 'pickup_point' &&
          shipment is Map &&
          shipment['status'] == 'en_route';
      return Result.success(_BuyerOrder(summary, awaitingPickup, name is String ? name.trim() : ''));
    } catch (_) {
      return Result.failure('Could not load order');
    }
  }

  void _open(String orderId, int session) {
    _hideBanner();
    final navigator = Navigator.of(context);
    final previous = _orderRoute;
    if (previous != null && previous.isActive) navigator.removeRoute(previous);
    final route = MaterialPageRoute<void>(
      builder: (_) => _NotificationOrderPage(load: () => _readOrder(orderId, session)),
    );
    _orderRoute = route;
    unawaited(
      navigator.push(route).whenComplete(() {
        if (_orderRoute == route) _orderRoute = null;
      }),
    );
  }

  void _hideBanner() {
    final host = _bannerHost;
    _bannerHost = null;
    if (host != null && host.mounted) host.removeCurrentMaterialBanner();
  }

  void _dismiss() {
    final route = _orderRoute;
    final bannerHost = _bannerHost;
    _orderRoute = null;
    _bannerHost = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bannerHost != null && bannerHost.mounted) bannerHost.removeCurrentMaterialBanner();
      if (route != null && route.isActive) route.navigator?.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _BuyerOrder {
  const _BuyerOrder(this.summary, this.awaitingPickup, this.point);
  final OrderSummary summary;
  final bool awaitingPickup;
  final String point;
}

class _NotificationOrderPage extends StatefulWidget {
  const _NotificationOrderPage({required this.load});
  final Future<Result<_BuyerOrder>> Function() load;

  @override
  State<_NotificationOrderPage> createState() => _NotificationOrderPageState();
}

class _NotificationOrderPageState extends State<_NotificationOrderPage> {
  late Future<Result<_BuyerOrder>> _order = widget.load();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your order')),
    body: SafeArea(
      child: FutureBuilder<Result<_BuyerOrder>>(
        future: _order,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading your order'));
          }
          final result = snapshot.data;
          final order = result?.value;
          if (order == null) {
            final unavailable = [401, 403, 404].contains(result?.statusCode);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(unavailable ? 'This order is unavailable for this account.' : 'Could not load your order.'),
                    if (!unavailable)
                      TextButton(
                        onPressed: () {
                          final next = widget.load();
                          setState(() { _order = next; });
                        },
                        child: const Text('Try again'),
                      ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(order.summary.productName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SelectableText('Order reference: ${order.summary.id}'),
              const SizedBox(height: 16),
              if (order.awaitingPickup) ...[
                if (order.point.isNotEmpty) Text('Collection point: ${order.point}'),
                const Text('Check your InPost email for your collection code and the latest collection instructions.'),
              ] else if (order.summary.deliveryLabel.isNotEmpty)
                Text(order.summary.deliveryLabel),
            ],
          );
        },
      ),
    ),
  );
}
