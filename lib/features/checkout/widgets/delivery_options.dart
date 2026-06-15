import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
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
  // final TextEditingController addressController = TextEditingController();
  // final TextEditingController postcodeController = TextEditingController();
  // final TextEditingController cityController = TextEditingController();
  final TextEditingController _mobilePhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<CheckoutViewModel>();
      final profile = await vm.fetchUserProfile();
      if (!mounted) return;
      final mobilePhone = profile?.phoneNumber ?? '';
      _mobilePhoneController.text = mobilePhone;
      vm.setMobilePhoneNumber(mobilePhone);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<CheckoutViewModel>();
    final selectedInpost = context.watch<CheckoutViewModel>().selectedInpost;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          const Divider(height: 32),
          PriceListItem(
            title: const Text(AppStrings.checkoutOrderTotal),
            price: viewModel.itemTotal,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: Row(
              children: [
                const Text(AppStrings.checkoutSecurityFee),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => viewModel.showPurchaseSecurity(),
                  child: const Icon(Icons.info, size: 16),
                ),
              ],
            ),
            price: viewModel.securityFee,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: const Text(AppStrings.checkoutPostage),
            price: viewModel.postage,
          ),
          const SizedBox(height: 8),
          PriceListItem(
            title: Text(
              AppStrings.checkoutTotal,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            price: viewModel.total,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 16),
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
            value: DeliveryType.pickup,
            groupValue: viewModel.deliveryChoice,
            onChanged: (_) {},
          ),
          // const SizedBox(height: 8),
          // ShippingListItem(
          //   icon: Icons.home,
          //   title: AppStrings.checkoutShipToHome,
          //   subtitle: AppStrings.checkoutHomeSubtitle,
          //   value: 'home',
          //   groupValue: _delivery,
          //   onChanged: (value) {
          //     setState(() {
          //       _delivery = value;
          //       _deliverExpanded = false;
          //     });
          //     Provider.of<CheckoutViewModel>(
          //       context,
          //       listen: false,
          //     ).setShowLocker(false);
          //     Provider.of<CheckoutViewModel>(
          //       context,
          //       listen: false,
          //     ).setDeliveryChoice(value ?? '');
          //   },
          // ),

          // Show pickup points when pickup is selected
          const Divider(height: 32),
          Text(
            AppStrings.checkoutDeliveryDetails,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Outlined(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ListTile(
                      onTap: () async {
                        final pickupPointSelected = await viewModel.showPickupPointSelection();
                        if (!mounted) return;
                        if (pickupPointSelected && viewModel.selectedInpost != null) {
                          await viewModel.fetchShippingMethodsForInpost();
                        }
                      },
                      leading: const Icon(Icons.map),
                      title: selectedInpost != null
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 10,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 255, 204, 5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.all(6),
                                  child: SvgPicture.asset(
                                    AppImages.inpostLogo,
                                    height: 25,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${selectedInpost.name} ${AppStrings.checkoutLocker}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${AppStrings.currencySymbol}${(viewModel.selectedInpostShippingMethod?.pricePence ?? 0) / 100}',
                                  style: TextStyle(color: AppColors.primaryAction),
                                ),
                              ],
                            )
                          : Text(AppStrings.checkoutChoosePickupPoint),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    if (viewModel.deliveryChoice == DeliveryType.pickup && selectedInpost != null) ...[
                      ListTile(
                        titleTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.store_outlined, size: 20),
                            Expanded(
                              child: Text(
                                viewModel.pickupBuilding,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          spacing: 8,
                          children: [
                            Icon(Icons.location_on_outlined, size: 20),
                            Expanded(
                              child: Text(
                                viewModel.pickupAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            AppStrings.mobilePhoneNumber,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mobilePhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: AddressConstants.mobilePhoneHintText,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            onTapUpOutside: (_) {
              viewModel.setMobilePhoneNumber(_mobilePhoneController.text);
              FocusManager.instance.primaryFocus?.unfocus();
            },
            onSubmitted: (value) => viewModel.setMobilePhoneNumber(value),
          ),
          // Show address input field when home delivery is selected
          if (viewModel.deliveryChoice == DeliveryType.home) ...[
            const SizedBox(height: 16),
            Text(
              AddressConstants.deliveryAddressTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ShippingAddressWidget(
              onAddressSelected: (PlaceDetails addressDetails) {
                // Save the selected address to the CheckoutViewModel
                viewModel.setShippingAddress(addressDetails);
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppStrings.checkoutPayment,
            style: TextStyle(
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
