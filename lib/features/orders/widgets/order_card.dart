import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/order_currency_formatter.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final OrderSummary order;

  const OrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final priceLabel = OrderCurrencyFormatter.formatItemPrice(order) ?? AppStrings.myOrdersPriceUnavailable;
    final statusLabel = OrderStatusFormatter.labelFor(order);
    final sizeLabel = order.size.trim().isEmpty ? AppStrings.myOrdersSizeUnavailable : order.size.trim();

    return Semantics(
      container: true,
      label:
          '${order.productName}. Size $sizeLabel. '
          '$priceLabel. $statusLabel.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useFlexibleLayout = constraints.maxWidth < 340 || textScale > 1.3;
            final imageSize = useFlexibleLayout ? 112.0 : (constraints.maxWidth * 0.36).clamp(120.0, 144.0).toDouble();

            if (useFlexibleLayout) {
              return _FlexibleOrderLayout(
                order: order,
                imageSize: imageSize,
                sizeLabel: sizeLabel,
                priceLabel: priceLabel,
                statusLabel: statusLabel,
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderImage(order: order, size: imageSize),
                const SizedBox(width: 16),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: imageSize),
                    child: _OrderDetails(
                      order: order,
                      sizeLabel: sizeLabel,
                      priceLabel: priceLabel,
                      statusLabel: statusLabel,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FlexibleOrderLayout extends StatelessWidget {
  final OrderSummary order;
  final double imageSize;
  final String sizeLabel;
  final String priceLabel;
  final String statusLabel;

  const _FlexibleOrderLayout({
    required this.order,
    required this.imageSize,
    required this.sizeLabel,
    required this.priceLabel,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderImage(order: order, size: imageSize),
            const SizedBox(width: 16),
            Expanded(
              child: _ProductIdentity(
                order: order,
                sizeLabel: sizeLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _PriceLabel(label: priceLabel)),
            const SizedBox(width: 12),
            Flexible(child: _StatusBadge(label: statusLabel)),
          ],
        ),
      ],
    );
  }
}

class _OrderDetails extends StatelessWidget {
  final OrderSummary order;
  final String sizeLabel;
  final String priceLabel;
  final String statusLabel;

  const _OrderDetails({
    required this.order,
    required this.sizeLabel,
    required this.priceLabel,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductIdentity(order: order, sizeLabel: sizeLabel),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _PriceLabel(label: priceLabel)),
            const SizedBox(width: 8),
            Flexible(child: _StatusBadge(label: statusLabel)),
          ],
        ),
      ],
    );
  }
}

class _ProductIdentity extends StatelessWidget {
  final OrderSummary order;
  final String sizeLabel;

  const _ProductIdentity({
    required this.order,
    required this.sizeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.productName,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 2),
        Text(
          sizeLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: order.size.trim().isEmpty
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PriceLabel extends StatelessWidget {
  final String label;

  const _PriceLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: label == AppStrings.myOrdersPriceUnavailable
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderImage extends StatelessWidget {
  final OrderSummary order;
  final double size;

  const _OrderImage({
    required this.order,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ProductImage(imageUrl: order.imageUrl),
              Positioned(
                left: 4,
                bottom: 4,
                child: _CharityLogo(imageUrl: order.charityLogoUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _ProductImagePlaceholder();
    }

    return ImageProviderHelper.buildImage(
      imagePath: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorWidget: const _ProductImagePlaceholder(),
      loadingWidget: const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CharityLogo extends StatelessWidget {
  final String imageUrl;

  const _CharityLogo({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: imageUrl.trim().isEmpty
          ? Icon(
              Icons.volunteer_activism_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : ImageProviderHelper.buildImage(
              imagePath: imageUrl,
              fit: BoxFit.contain,
              errorWidget: Icon(
                Icons.volunteer_activism_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

class OrderStatusFormatter {
  const OrderStatusFormatter._();

  static String labelFor(OrderSummary order) {
    final backendLabel = order.deliveryLabel.trim();
    if (backendLabel.isNotEmpty) {
      return backendLabel;
    }

    final state = order.deliveryState.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

    return switch (state) {
      'pending' || 'preparing' || 'processing' => 'Preparing',
      'dispatched' || 'shipped' || 'in_transit' => 'On the way',
      'out_for_delivery' => 'Out for delivery',
      'delivered' => 'Delivered',
      'cancelled' || 'canceled' => 'Cancelled',
      'returned' => 'Returned',
      'refunded' => 'Refunded',
      _ => AppStrings.myOrdersStatusUnavailable,
    };
  }
}
