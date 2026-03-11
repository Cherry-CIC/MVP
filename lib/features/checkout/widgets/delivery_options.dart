// ignore_for_file: unnecessary_const

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_empty_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_error_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_loading_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/price_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:cherry_mvp/features/checkout/widgets/share_location_dialog.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_list_item.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class DeliveryOptions extends StatefulWidget {
  const DeliveryOptions({super.key});

  @override
  State<DeliveryOptions> createState() => _DeliveryOptionsState();
}

class _DeliveryOptionsState extends State<DeliveryOptions> {
  String? _delivery;
  var _deliverExpanded = false;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CheckoutViewModel>();

      if ((vm.deliveryChoice ?? '').isNotEmpty) {
        setState(() {
          _delivery = vm.deliveryChoice;
          _deliverExpanded = _delivery == 'pickup' && vm.selectedInpost != null;
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
    final basket = context.read<CheckoutViewModel>();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          const Divider(height: 32),
          PriceListItem(
            title: const Text(AppStrings.checkoutOrderTotal),
            price: basket.itemTotal,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: Row(
              children: [
                const Text(AppStrings.checkoutSecurityFee),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PurchaseSecurity(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: const Icon(Icons.info, size: 16),
                ),
              ],
            ),
            price: basket.securityFee,
          ),
          const SizedBox(height: 4),
          PriceListItem(
            title: const Text(AppStrings.checkoutPostage),
            price: basket.postage,
          ),
          const SizedBox(height: 8),
          PriceListItem(
            title: Text(
              AppStrings.checkoutTotal,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            price: basket.total,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 16),
          ),
          const Divider(height: 32),
          if (_delivery == 'pickup') ...[
            Text(
              AppStrings.address,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              keyboardType: TextInputType.streetAddress,
              decoration: InputDecoration(
                hintText: AddressConstants.addressHinText,
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
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.postCode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 175,
                      child: TextField(
                        controller: postcodeController,
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          hintText: AddressConstants.postCodeHintText,
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
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.city,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 175,
                      child: TextField(
                        controller: cityController,
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          hintText: AddressConstants.cityHintText,
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: [
                Icon(Icons.check_box_outline_blank, color: AppColors.red),
                Text(
                  AppStrings.useAsDefaultAddress,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],

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
            value: 'pickup',
            groupValue: _delivery,
            onChanged: (value) {
              if (postcodeController.text.isEmpty &&
                  context.read<CheckoutViewModel>().selectedInpost == null) {
                Fluttertoast.showToast(
                  msg: "Postcode required",
                  backgroundColor: AppColors.red,
                  textColor: AppColors.white,
                );
                return;
              }
              setState(() {
                _delivery = value;

                if (context.read<CheckoutViewModel>().selectedInpost != null) {
                  _deliverExpanded = true;
                }
              });
              Provider.of<CheckoutViewModel>(
                context,
                listen: false,
              ).setDeliveryChoice(value ?? '');
              if (context.read<CheckoutViewModel>().selectedInpost == null) {
                showDialog(
                  context: context,
                  builder: (context) => ShareLocationDialog(
                    postcode: postcodeController.text.trim(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          ShippingListItem(
            icon: Icons.home,
            title: AppStrings.checkoutShipToHome,
            subtitle: AppStrings.checkoutHomeSubtitle,
            value: 'home',
            groupValue: _delivery,
            onChanged: (value) {
              setState(() {
                _delivery = value;
                _deliverExpanded = false;
              });
              Provider.of<CheckoutViewModel>(
                context,
                listen: false,
              ).setShowLocker(false);
              Provider.of<CheckoutViewModel>(
                context,
                listen: false,
              ).setDeliveryChoice(value ?? '');
            },
          ),

          // Show pickup points when pickup is selected
          if (_delivery == 'pickup' &&
              context.watch<CheckoutViewModel>().showLocker) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Outlined(
                  child: ListTile(
                    onTap: () =>
                        setState(() => _deliverExpanded = !_deliverExpanded),
                    leading: const Icon(Icons.map),
                    title: const Text(AppStrings.checkoutPickupPoint),
                    trailing: _deliverExpanded
                        ? const Icon(Icons.expand_less)
                        : const Icon(Icons.expand_more),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<CheckoutViewModel>(
                  builder: (context, model, _) {
                    final status = model.status;

                    final inposts = model.nearestInpost;

                    if (status.type == StatusType.loading) {
                      PickupPointsLoadingWidget();
                    } else if (status.type == StatusType.failure) {
                      PickupPointErrorWidget(
                        errorMessage: status.message,
                        onRetry: () => model.fetchNearestInPosts(
                          postcodeController.text.trim(),
                        ),
                      );
                    } else if (status.type == StatusType.success) {
                      if (inposts.isEmpty) {
                        return PickupPointsEmptyWidget();
                      }

                      if (_deliverExpanded) {
                        if (model.selectedInpost != null &&
                            context.watch<CheckoutViewModel>().hasLocker) {
                          // case: locker already selected
                          return Outlined(
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Provider.of<CheckoutViewModel>(
                                        context,
                                        listen: false,
                                      ).setSelectedInpost(null);
                                      Provider.of<CheckoutViewModel>(
                                        context,
                                        listen: false,
                                      ).setDeliveryChoice('');
                                      Provider.of<CheckoutViewModel>(
                                        context,
                                        listen: false,
                                      ).setShowLocker(false);
                                      setState(() {
                                        _delivery = null;
                                      });
                                    },
                                    child: Text("Change pickup point"),
                                  ),
                                ),
                                CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(model.selectedInpost?.name ?? ''),
                                  subtitle: Text(
                                    model.selectedInpost?.address ?? '',
                                  ),
                                  value: true,
                                  onChanged: null,
                                ),
                              ],
                            ),
                          );
                        } else {
                          // case: show list of lockers
                          return Outlined(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: inposts.length,
                              itemBuilder: (context, index) {
                                final data = inposts[index];
                                return Column(
                                  children: [
                                    CheckboxListTile(
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(data.name),
                                      subtitle: Text(data.address),
                                      value:
                                          model.selectedInpost?.id == data.id,
                                      onChanged: (val) {
                                        if (val == true) {
                                          model.setSelectedInpost(data);
                                        }
                                      },
                                    ),
                                    if (index != inposts.length - 1)
                                      const Divider(height: 1),
                                  ],
                                );
                              },
                            ),
                          );
                        }
                      }
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],

          // Show address input field when home delivery is selected
          if (_delivery == 'home') ...[
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
                basket.setShippingAddress(addressDetails);
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
                    selectedType == null
                        ? AppStrings.checkoutChoosePayment
                        : _paymentTypeLabel(selectedType),
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
                      builder: (context) =>
                          const SelectPaymentTypeBottomSheet(),
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
