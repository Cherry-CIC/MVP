import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/models/pickup_point.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_empty_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_error_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_loading_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/price_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_list_item.dart';

class DeliveryOptions extends StatefulWidget {
  const DeliveryOptions({super.key});

  @override
  State<DeliveryOptions> createState() => _DeliveryOptionsState();
}

class _DeliveryOptionsState extends State<DeliveryOptions> {
  String _paymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.card:
        return AppStrings.paymentMethodsCard;
      case PaymentType.google:
        return AppStrings.paymentMethodsGooglePay;
      case PaymentType.apple:
        return AppStrings.paymentMethodsApplePay;
    }
  }

  Future<void> _selectPickupDelivery(CheckoutViewModel model) async {
    if (!model.isShippingAddressConfirmed || !model.hasShippingAddress) {
      Fluttertoast.showToast(
        msg: AppStrings.checkoutAddressRequired,
        backgroundColor: AppColors.red,
        textColor: AppColors.white,
      );
      return;
    }

    model.setDeliveryChoice(CheckoutViewModel.pickupPointDeliveryChoice);
    await model.fetchPickupPointsForShippingAddress();

    if (!mounted ||
        !model.isPickupPointDelivery ||
        model.status.type != StatusType.success ||
        model.pickupPoints.isEmpty) {
      return;
    }

    await _showPickupPointPicker(model);
  }

  Future<void> _showPickupPointPicker(CheckoutViewModel model) async {
    final selected = await showModalBottomSheet<PickupPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PickupPointPickerSheet(
          addressLabel: model.formattedShippingAddress,
          pickupPoints: model.pickupPoints,
          selectedPickupPoint: model.selectedPickupPoint,
        );
      },
    );

    if (selected != null) {
      model.setSelectedPickupPoint(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CheckoutViewModel>();
    final deliveryChoice = model.deliveryChoice;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          const Divider(height: 32),
          PriceListItem(
            title: const Text(AppStrings.checkoutOrderTotal),
            price: model.itemTotal,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: Row(
              children: [
                const Text(AppStrings.checkoutSecurityFee),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.read<CheckoutViewModel>().showPurchaseSecurity(),
                  child: const Icon(Icons.info, size: 16),
                ),
              ],
            ),
            price: model.securityFee,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: const Text(AppStrings.checkoutPostage),
            price: model.postage,
          ),
          const SizedBox(height: 8),
          PriceListItem(
            title: Text(
              AppStrings.checkoutTotal,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            price: model.total,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 16),
          ),
          const Divider(height: 32),
          Text(
            AppStrings.address,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ShippingAddressWidget(
            onAddressSelected: (PlaceDetails addressDetails) async {
              model.setShippingAddress(addressDetails);
              if (model.isPickupPointDelivery) {
                await model.fetchPickupPointsForShippingAddress();
              }
            },
          ),
          const Divider(height: 32),
          Text(
            AppStrings.checkoutDeliveryOption,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ShippingListItem(
            icon: Icons.location_on,
            title: AppStrings.checkoutShipToPickup,
            subtitle: AppStrings.checkoutPickupSubtitle,
            value: CheckoutViewModel.pickupPointDeliveryChoice,
            groupValue: deliveryChoice,
            onChanged: (_) => _selectPickupDelivery(model),
          ),
          const SizedBox(height: 8),
          ShippingListItem(
            icon: Icons.home,
            title: AppStrings.checkoutShipToHome,
            subtitle: AppStrings.checkoutHomeSubtitle,
            value: CheckoutViewModel.homeDeliveryChoice,
            groupValue: deliveryChoice,
            onChanged: (value) {
              model.setDeliveryChoice(value ?? '');
            },
          ),
          if (model.isPickupPointDelivery) ...[
            const SizedBox(height: 16),
            _PickupPointSelectionSection(
              model: model,
              onChoose: () async {
                if (model.pickupPoints.isEmpty) {
                  await model.fetchPickupPointsForShippingAddress();
                }
                if (!mounted ||
                    !model.isPickupPointDelivery ||
                    model.status.type != StatusType.success ||
                    model.pickupPoints.isEmpty) {
                  return;
                }
                await _showPickupPointPicker(model);
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppStrings.checkoutPayment,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<CheckoutViewModel>(
            builder: (context, model, _) {
              final selectedType = model.selectedPaymentType;
              return Outlined(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.credit_card),
                  title: Text(
                    selectedType == null ? AppStrings.checkoutChoosePayment : _paymentTypeLabel(selectedType),
                  ),
                  subtitle: selectedType == null
                      ? Text(
                          AppStrings.paymentMethodsChoose,
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await showModalBottomSheet<PaymentType>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const SelectPaymentTypeBottomSheet(),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _PickupPointSelectionSection extends StatelessWidget {
  final CheckoutViewModel model;
  final Future<void> Function() onChoose;

  const _PickupPointSelectionSection({
    required this.model,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.checkoutPickupPointDetails,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (model.status.type == StatusType.loading) {
      return const Outlined(child: PickupPointsLoadingWidget());
    }

    if (model.status.type == StatusType.failure) {
      return Outlined(
        child: PickupPointErrorWidget(
          errorMessage: model.status.message,
          onRetry: () {
            model.fetchPickupPointsForShippingAddress();
          },
        ),
      );
    }

    if (model.status.type == StatusType.success && model.pickupPoints.isEmpty) {
      return const Outlined(child: PickupPointsEmptyWidget());
    }

    final selected = model.selectedPickupPoint;
    if (selected != null) {
      return Outlined(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            Icons.map_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(selected.name),
          subtitle: Text(selected.displayAddress),
          trailing: TextButton(
            onPressed: () {
              onChoose();
            },
            child: const Text(AppStrings.checkoutChangePickupPoint),
          ),
          onTap: () {
            onChoose();
          },
        ),
      );
    }

    return Outlined(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.map_outlined),
        title: const Text(AppStrings.checkoutChoosePickupPoint),
        subtitle: model.pickupPoints.isEmpty ? null : Text('${model.pickupPoints.length} pick-up points nearby'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          onChoose();
        },
      ),
    );
  }
}

class PickupPointPickerSheet extends StatelessWidget {
  final String addressLabel;
  final List<PickupPoint> pickupPoints;
  final PickupPoint? selectedPickupPoint;

  const PickupPointPickerSheet({
    super.key,
    required this.addressLabel,
    required this.pickupPoints,
    required this.selectedPickupPoint,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: AppStrings.back,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.checkoutChoosePickupPoint,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          addressLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 16),
                  itemCount: pickupPoints.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final point = pickupPoints[index];
                    final isSelected = selectedPickupPoint?.id == point.id;
                    return _PickupPointListItem(
                      point: point,
                      isSelected: isSelected,
                      onTap: () => Navigator.pop(context, point),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupPointListItem extends StatelessWidget {
  final PickupPoint point;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickupPointListItem({
    required this.point,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailText = [
      if ((point.carrier ?? '').isNotEmpty) point.carrier!,
      if (point.distanceLabel.isNotEmpty) point.distanceLabel,
      if (point.openUpcomingWeek) 'Open this week',
    ].join(' | ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.displayAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (detailText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detailText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
