import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:cherry_mvp/features/checkout/widgets/price_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_method_dropdown.dart';

class DeliveryOptions extends StatefulWidget {
  const DeliveryOptions({super.key});

  @override
  State<DeliveryOptions> createState() => _DeliveryOptionsState();
}

class _DeliveryOptionsState extends State<DeliveryOptions> {
  var _delivery = DeliveryType.undefined;
  var _pickupExpanded = false;

  // final TextEditingController addressController = TextEditingController();
  // final TextEditingController postcodeController = TextEditingController();
  // final TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CheckoutViewModel>();

      if (vm.deliveryChoice != DeliveryType.undefined) {
        setState(() {
          _delivery = vm.deliveryChoice;
          _pickupExpanded = _delivery == DeliveryType.pickup && vm.selectedInpost != null;
        });
      }
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

          // if (_delivery == 'pickup') ...[
          //   Text(
          //     AppStrings.address,
          //     style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //       color: Theme.of(context).colorScheme.onSurfaceVariant,
          //     ),
          //   ),
          //   const SizedBox(height: 8),
          //   TextField(
          //     controller: addressController,
          //     keyboardType: TextInputType.streetAddress,
          //     decoration: InputDecoration(
          //       hintText: AddressConstants.addressHinText,
          //       border: OutlineInputBorder(
          //         borderSide: BorderSide(
          //           color: Theme.of(context).colorScheme.outline,
          //         ),
          //       ),
          //       enabledBorder: OutlineInputBorder(
          //         borderSide: BorderSide(
          //           color: Theme.of(context).colorScheme.outline,
          //         ),
          //       ),
          //     ),
          //   ),
          //   const SizedBox(height: 8),
          //   Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             AppStrings.postCode,
          //             style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //               color: Theme.of(context).colorScheme.onSurfaceVariant,
          //             ),
          //           ),
          //           const SizedBox(height: 8),
          //           SizedBox(
          //             width: 175,
          //             child: TextField(
          //               controller: postcodeController,
          //               keyboardType: TextInputType.streetAddress,
          //               decoration: InputDecoration(
          //                 hintText: AddressConstants.postCodeHintText,
          //                 border: OutlineInputBorder(
          //                   borderSide: BorderSide(
          //                     color: Theme.of(context).colorScheme.outline,
          //                   ),
          //                 ),
          //                 enabledBorder: OutlineInputBorder(
          //                   borderSide: BorderSide(
          //                     color: Theme.of(context).colorScheme.outline,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             AppStrings.city,
          //             style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //               color: Theme.of(context).colorScheme.onSurfaceVariant,
          //             ),
          //           ),
          //           const SizedBox(height: 8),
          //           SizedBox(
          //             width: 175,
          //             child: TextField(
          //               controller: cityController,
          //               keyboardType: TextInputType.streetAddress,
          //               decoration: InputDecoration(
          //                 hintText: AddressConstants.cityHintText,
          //                 border: OutlineInputBorder(
          //                   borderSide: BorderSide(
          //                     color: Theme.of(context).colorScheme.outline,
          //                   ),
          //                 ),
          //                 enabledBorder: OutlineInputBorder(
          //                   borderSide: BorderSide(
          //                     color: Theme.of(context).colorScheme.outline,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          //   const SizedBox(height: 10),
          //   Row(
          //     spacing: 10,
          //     children: [
          //       Icon(Icons.check_box_outline_blank, color: AppColors.red),
          //       Text(
          //         AppStrings.useAsDefaultAddress,
          //         style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //           color: Theme.of(context).colorScheme.onSurfaceVariant,
          //         ),
          //       ),
          //     ],
          //   ),
          //   const Divider(height: 32),
          // ],
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
            groupValue: _delivery,
            onChanged: (value) async {
              setState(() {
                _delivery = value ?? DeliveryType.undefined;

                if (viewModel.selectedInpost != null) {
                  _pickupExpanded = true;
                }
              });
              viewModel.setDeliveryChoice(value ?? DeliveryType.undefined);
              final pickupPointSelected = await viewModel.showPickupPointSelection();
              if (pickupPointSelected) {
                await viewModel.fetchShippingMethodsForInpost(
                  viewModel.selectedInpost!.id,
                  viewModel.selectedInpost!.postcode,
                  viewModel.selectedInpost!.country,
                );
                viewModel.setShowLocker(true);
              }
            },
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
          if (_delivery == DeliveryType.pickup &&
              selectedInpost != null &&
              context.watch<CheckoutViewModel>().showLocker) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Outlined(
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () async {
                          setState(() => _pickupExpanded = !_pickupExpanded);
                        },
                        leading: const Icon(Icons.map),
                        title: const Text(AppStrings.checkoutPickupPoint),
                        trailing: _pickupExpanded ? const Icon(Icons.expand_less) : const Icon(Icons.expand_more),
                      ),
                      if (_pickupExpanded)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(selectedInpost.name),
                              subtitle: Text(selectedInpost.address),
                              trailing: TextButton(
                                onPressed: () async {
                                  viewModel.setSelectedInpost(null);
                                  // viewModel.setShowLocker(false);
                                  await viewModel.showPickupPointSelection();
                                },
                                child: Text("Change"),
                              ),
                            ),
                            Consumer<CheckoutViewModel>(
                              builder: (context, model, _) {
                                final status = model.status;

                                if (status.type == StatusType.loading) {
                                  return Center(child: CircularProgressIndicator());
                                } else if (status.type == StatusType.failure) {
                                  return Text(status.message ?? 'oopsie');
                                } else if (status.type == StatusType.success &&
                                    viewModel.inpostShippingMethods.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ShippingMethodDropdown(shippingMethods: viewModel.inpostShippingMethods),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Show address input field when home delivery is selected
          if (_delivery == DeliveryType.home) ...[
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
