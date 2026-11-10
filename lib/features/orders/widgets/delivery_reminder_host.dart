import 'dart:async';

import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_page.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_dialog.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_timer_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cherry_mvp/features/orders/widgets/ready_to_collect_dialog.dart';

/// Checks on entry and foregrounding. If another screen is open, wait until
/// the buyer returns before presenting a modal over their home screen.
class DeliveryReminderHost extends StatefulWidget {
  const DeliveryReminderHost({super.key, required this.userId, required this.builder, this.openLink});

  final String userId;
  final Future<bool> Function(Uri)? openLink;
  final Widget Function(BuildContext context, Widget? timer) builder;

  @override
  State<DeliveryReminderHost> createState() => _DeliveryReminderHostState();
}

class _DeliveryReminderHostState extends State<DeliveryReminderHost> with WidgetsBindingObserver {
  List<OrderSummary> _eligible = [];
  Set<String> _dismissed = {};
  final Set<String> _resolved = {};
  late final StreamSubscription<String> _resolutionSubscription;

  String get _preferenceKey => 'deliveryReminder.${widget.userId}';

  bool _pending = true;
  int _generation = 0;
  DialogRoute<Object>? _dialog;
  OrderSummary? _shownOrder;
  late final Timer _refreshTimer;
  bool _fetching = false;

  String _dismissalId(OrderSummary order) => order.canShowCollectionReminder
      ? 'collection:${order.id}:${order.collectionDeadline!.isAfter(DateTime.now()) ? 'ready' : 'expired'}'
      : order.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          (ModalRoute.of(context)?.isCurrent == true || _dialog?.isCurrent == true)) {
        _check(++_generation);
      }
    });
    _resolutionSubscription = context.read<OrdersViewModel>().resolvedOrders.listen((id) {
      if (mounted) setState(() => _resolved.add(id));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) == true) _scheduleCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _generation++;
      _pending = true;
      final dialog = _dialog;
      if (dialog != null && dialog.isActive) {
        dialog.navigator?.removeRoute(dialog, DeliveryReminderAction.interrupted);
      }
    } else if (state == AppLifecycleState.resumed) {
      _pending = true;
      _scheduleCheck();
    }
  }

  void _scheduleCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _pending &&
          _dialog == null &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _pending = false;
        _check(++_generation);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _check(int generation) async {
    if (_fetching) {
      _pending = true;
      return;
    }
    _fetching = true;
    try {
      final result = await context.read<IOrdersRepository>().fetchOrders(deliveryRemindersOnly: true);
      if (!mounted || generation != _generation || !result.isSuccess) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || generation != _generation) return;
      if (ModalRoute.of(context)?.isCurrent != true && _dialog?.isCurrent != true) {
        _pending = true;
        return;
      }
      final now = DateTime.now();
      final eligible =
          (result.value ?? const <OrderSummary>[])
              .where((order) => order.canShowAnyReminder(now) && !_resolved.contains(order.id))
              .toList()
            ..sort((a, b) => a.reminderDeadline!.compareTo(b.reminderDeadline!));
      final saved = prefs.getStringList(_preferenceKey) ?? const <String>[];
      setState(() {
        _eligible = eligible;
        _dismissed = saved.toSet();
      });
      final shown = _shownOrder;
      if (_dialog != null && shown != null) {
        final latest = eligible.where((order) => order.id == shown.id).firstOrNull;
        if (latest == null ||
            latest.deliveryState != shown.deliveryState ||
            latest.reminderDeadline != shown.reminderDeadline ||
            latest.collectionMapUri != shown.collectionMapUri ||
            latest.trackingUri != shown.trackingUri) {
          _pending = true;
          _dialog!.navigator?.removeRoute(_dialog!, DeliveryReminderAction.interrupted);
        }
        return;
      }
      final unseen = eligible.where((order) => !_dismissed.contains(_dismissalId(order))).firstOrNull;
      if (unseen != null) unawaited(_showReminder(unseen));
    } finally {
      _fetching = false;
      if (mounted && _pending) _scheduleCheck();
    }
  }

  Future<void> _showReminder(OrderSummary order) async {
    final latest = _eligible.where((candidate) => candidate.id == order.id).firstOrNull;
    if (latest == null || latest.deliveryState != order.deliveryState) return;
    order = latest;
    if (_dialog != null ||
        ModalRoute.of(context)?.isCurrent != true ||
        _resolved.contains(order.id) ||
        !order.canShowAnyReminder(DateTime.now())) {
      return;
    }
    final route = DialogRoute<Object>(
      context: context,
      builder: (_) => order.canShowCollectionReminder
          ? ReadyToCollectDialog(
              order: order,
              collectionDeadline: order.collectionDeadline!,
              canOpenMap: order.collectionMapUri != null,
              canTrackParcel: order.trackingUri != null,
            )
          : DeliveryReminderDialog(order: order),
    );
    setState(() {
      _dialog = route;
      _shownOrder = order;
    });
    final action = await Navigator.of(context).push(route);
    if (!mounted) return;
    final dismissalId = _dismissalId(order);
    final remember = action != DeliveryReminderAction.interrupted && !_dismissed.contains(dismissalId);
    setState(() {
      _dialog = null;
      _shownOrder = null;
      if (remember) _dismissed.add(dismissalId);
    });
    if (action == DeliveryReminderAction.interrupted) {
      _scheduleCheck();
      return;
    }
    if (remember) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      await prefs.setStringList(_preferenceKey, _dismissed.toList());
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true || !order.canShowAnyReminder(DateTime.now())) return;
    if (order.canShowCollectionReminder) {
      final uri = action == ReadyToCollectAction.openMap
          ? order.collectionMapUri
          : action == ReadyToCollectAction.trackParcel
          ? order.trackingUri
          : null;
      if (uri != null) {
        bool opened;
        try {
          opened = await (widget.openLink?.call(uri) ?? launchUrl(uri, mode: LaunchMode.externalApplication));
        } catch (_) {
          opened = false;
        }
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open this link. Please try again.'),
              action: SnackBarAction(label: 'Try again', onPressed: () => _showReminder(order)),
            ),
          );
        }
      }
      return;
    }
    final orders = context.read<OrdersViewModel>();
    if (action == DeliveryReminderAction.view) {
      await OrderActions.viewItem(context, order, orders);
    } else if (action == DeliveryReminderAction.report) {
      await OrderActions.reportProblem(context, order, orders);
    }
  }

  @override
  void dispose() {
    _resolutionSubscription.cancel();
    _refreshTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final dialog = _dialog;
    if (dialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (dialog.isActive) dialog.navigator?.removeRoute(dialog, DeliveryReminderAction.interrupted);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final order = _eligible
        .where(
          (order) =>
              _dismissed.contains(order.id) && !_resolved.contains(order.id) && order.canShowDeliveryReminder(now),
        )
        .firstOrNull;

    return widget.builder(
      context,
      order == null || _dialog != null
          ? null
          : DeliveryTimerBubble(
              key: const ValueKey('delivery-timer-bubble'),
              deadline: order.confirmationDeadline!,
              onTap: () => _showReminder(order),
              onExpired: () => setState(() => _eligible.removeWhere((item) => item.id == order.id)),
            ),
    );
  }
}
