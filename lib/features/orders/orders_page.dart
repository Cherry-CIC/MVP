import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
import 'package:cherry_mvp/features/orders/widgets/confirm_item_dialog.dart';
import 'package:cherry_mvp/features/orders/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyOrdersPage extends StatefulWidget {
  final VoidCallback onBack;

  const MyOrdersPage({
    super.key,
    required this.onBack,
  });

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  OrdersViewModel? _viewModel;
  bool _hasInitialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<OrdersViewModel>();

    if (!_hasInitialised) {
      _hasInitialised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel?.loadOrders();
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.clearOrders(notify: false);
    super.dispose();
  }

  Future<void> _handleOrderTap(BuildContext context, OrderSummary order) async {
    final state = order.deliveryState.trim().toLowerCase();
    if (state != 'awaiting_confirmation' && state != 'delivered') {
      return;
    }

    final action = await showDialog<ConfirmItemAction>(
      context: context,
      builder: (dialogContext) => ConfirmItemDialog(order: order),
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == ConfirmItemAction.dispute) {
      await _openDisputeDialog(context, order);
      return;
    }

    final result = await _viewModel?.confirmOrderReceived(order.id);
    if (!mounted) {
      return;
    }

    if (result?.isSuccess == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt confirmed')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result?.error ?? 'Could not confirm this item')),
    );
  }

  Future<void> _openDisputeDialog(BuildContext context, OrderSummary order) async {
    final result = await showDialog<_DisputeChoice>(
      context: context,
      builder: (dialogContext) => _DisputeDialog(order: order),
    );

    if (!mounted || result == null) {
      return;
    }

    final submitResult = await _viewModel?.submitOrderDispute(
      order.id,
      reason: result.reason,
      message: result.message,
    );
    if (!mounted) {
      return;
    }

    if (submitResult?.isSuccess == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispute submitted')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(submitResult?.error ?? 'Could not submit the dispute')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          AppStrings.myOrdersTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<OrdersViewModel>(
          builder: (context, viewModel, _) {
            if ((viewModel.status.type == StatusType.uninitialized || viewModel.status.type == StatusType.loading) &&
                viewModel.orders.isEmpty) {
              return const _OrdersLoading();
            }

            if (viewModel.status.type == StatusType.failure && viewModel.orders.isEmpty) {
              return _OrdersFailure(
                onRetry: viewModel.retryLoad,
              );
            }

            if (viewModel.status.type == StatusType.success && viewModel.orders.isEmpty) {
              return _OrdersEmpty(
                onRefresh: viewModel.refreshOrders,
              );
            }

            return _OrdersList(viewModel: viewModel);
          },
        ),
      ),
    );
  }
}

class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.myOrdersLoading,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _OrdersFailure extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _OrdersFailure({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.myOrdersLoadFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  final RefreshCallback onRefresh;

  const _OrdersEmpty({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.myOrdersEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final OrdersViewModel viewModel;

  const _OrdersList({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final hasRefreshError = viewModel.refreshError != null;
    final awaitingConfirmationOrders = viewModel.orders
        .where((order) => order.deliveryState.trim().toLowerCase() == 'awaiting_confirmation')
        .toList(growable: false);
    final otherOrders = viewModel.orders
        .where((order) => order.deliveryState.trim().toLowerCase() != 'awaiting_confirmation')
        .toList(growable: false);
    final children = <Widget>[
      if (hasRefreshError) _RefreshFailure(onRetry: viewModel.refreshOrders),
      if (awaitingConfirmationOrders.isNotEmpty) ...[
        const _OrderSectionHeader(title: AppStrings.myOrdersAwaitingConfirmation),
        ...awaitingConfirmationOrders.map(
          (order) => _OrderListItem(order: order, viewModel: viewModel),
        ),
      ],
      if (otherOrders.isNotEmpty) ...[
        const _OrderSectionHeader(title: AppStrings.myOrdersOther),
        ...otherOrders.map(
          (order) => _OrderListItem(order: order, viewModel: viewModel),
        ),
      ],
    ];

    return RefreshIndicator(
      onRefresh: viewModel.refreshOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _OrderSectionHeader extends StatelessWidget {
  final String title;

  const _OrderSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _OrderListItem extends StatelessWidget {
  final OrderSummary order;
  final OrdersViewModel viewModel;

  const _OrderListItem({
    required this.order,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      key: ValueKey(order.id),
      order: order,
      onTap: () => _OrdersListState.handleOrderAction(context, order, viewModel),
    );
  }
}

class _DisputeChoice {
  final String reason;
  final String message;

  const _DisputeChoice({required this.reason, required this.message});
}

class _DisputeDialog extends StatefulWidget {
  final OrderSummary order;

  const _DisputeDialog({required this.order});

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  String _reason = 'wrong_item';
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raise dispute'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _reason,
              items: const [
                DropdownMenuItem(value: 'wrong_item', child: Text('Wrong item')),
                DropdownMenuItem(value: 'item_not_as_described', child: Text('Item not as described')),
                DropdownMenuItem(value: 'item_arrived_damaged', child: Text('Item arrived damaged')),
                DropdownMenuItem(value: 'something_else', child: Text('Something else')),
              ],
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tell us what went wrong',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _DisputeChoice(
              reason: _reason,
              message: _messageController.text,
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _OrdersListState {
  static Future<void> handleOrderAction(
    BuildContext context,
    OrderSummary order,
    OrdersViewModel viewModel,
  ) async {
    final state = order.deliveryState.trim().toLowerCase();
    if (state != 'awaiting_confirmation' && state != 'delivered') {
      return;
    }

    final action = await showDialog<ConfirmItemAction>(
      context: context,
      builder: (dialogContext) => ConfirmItemDialog(order: order),
    );
    if (action == null) {
      return;
    }

    if (action == ConfirmItemAction.dispute) {
      final disputeChoice = await showDialog<_DisputeChoice>(
        context: context,
        builder: (dialogContext) => _DisputeDialog(order: order),
      );
      if (disputeChoice == null) {
        return;
      }

      final disputeResult = await viewModel.submitOrderDispute(
        order.id,
        reason: disputeChoice.reason,
        message: disputeChoice.message,
      );
      if (!context.mounted) {
        return;
      }
      if (disputeResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute submitted')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(disputeResult.error ?? 'Could not submit the dispute'),
        ),
      );
      return;
    }

    final confirmResult = await viewModel.confirmOrderReceived(order.id);
    if (!context.mounted) {
      return;
    }
    if (confirmResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt confirmed')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(confirmResult.error ?? 'Could not confirm this item')),
    );
  }
}

class _RefreshFailure extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _RefreshFailure({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.myOrdersRefreshFailed,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
