import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/orders/orders_view_model.dart';
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

    return RefreshIndicator(
      onRefresh: viewModel.refreshOrders,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: viewModel.orders.length + (hasRefreshError ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (hasRefreshError && index == 0) {
            return _RefreshFailure(onRetry: viewModel.refreshOrders);
          }

          final orderIndex = index - (hasRefreshError ? 1 : 0);
          return OrderCard(
            key: ValueKey(viewModel.orders[orderIndex].id),
            order: viewModel.orders[orderIndex],
          );
        },
      ),
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
