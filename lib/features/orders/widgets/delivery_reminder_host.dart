import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_page.dart';
import 'package:cherry_mvp/features/orders/orders_repository.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/delivery_reminder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checks on entry and foregrounding. If another screen is open, wait until
/// the buyer returns before presenting a modal over their home screen.
class DeliveryReminderHost extends StatefulWidget {
  const DeliveryReminderHost({super.key, required this.userId, required this.child});

  final String userId;
  final Widget child;

  @override
  State<DeliveryReminderHost> createState() => _DeliveryReminderHostState();
}

class _DeliveryReminderHostState extends State<DeliveryReminderHost> with WidgetsBindingObserver {
  bool _pending = true;
  int _generation = 0;
  DialogRoute<DeliveryReminderAction>? _dialog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final result = await context.read<IOrdersRepository>().fetchOrders(deliveryRemindersOnly: true);
    if (!mounted || generation != _generation || !result.isSuccess || (result.value?.isEmpty ?? true)) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || generation != _generation) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _pending = true;
      return;
    }

    final key = 'deliveryReminder.${widget.userId}';
    final dismissed = prefs.getStringList(key) ?? const <String>[];
    final now = DateTime.now();
    final eligible = result.value!.where((order) => order.canShowDeliveryReminder(now)).toList();
    final activeIds = eligible.map((order) => order.id).toSet();
    final remembered = dismissed.where(activeIds.contains).toSet();
    eligible.removeWhere((order) => remembered.contains(order.id));
    eligible.sort((a, b) => a.confirmationDeadline!.compareTo(b.confirmationDeadline!));
    if (eligible.isEmpty) return;
    final OrderSummary order = eligible.first;
    final route = DialogRoute<DeliveryReminderAction>(
      context: context,
      builder: (_) => DeliveryReminderDialog(order: order),
    );
    _dialog = route;
    final action = await Navigator.of(context).push(route);
    _dialog = null;
    if (!mounted || action == DeliveryReminderAction.interrupted) return;
    // The preference is local to the buyer and this device. Dismissal is
    // independent of confirming receipt or submitting a dispute.
    remembered.add(order.id);
    await prefs.setStringList(key, remembered.toList());
    if (!mounted || ModalRoute.of(context)?.isCurrent != true || !order.canShowDeliveryReminder(DateTime.now())) return;
    final orders = context.read<OrdersViewModel>();
    if (action == DeliveryReminderAction.view) {
      await OrderActions.viewItem(context, order, orders);
    } else if (action == DeliveryReminderAction.report) {
      await OrderActions.reportProblem(context, order, orders);
    }
  }

  @override
  void dispose() {
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
  Widget build(BuildContext context) => widget.child;
}
