// ignore_for_file: unnecessary_const

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:cherry_mvp/features/checkout/widgets/price_list_item.dart';
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
              children: const [
                Text(AppStrings.checkoutSecurityFee),
                SizedBox(width: 4),
                Icon(
                  Icons.info,
                  size: 16,
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 32),
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
              Icon(
                Icons.check_box_outline_blank,
                color: AppColors.red,
              ),
              Text(
                AppStrings.useAsDefaultAddress,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            AppStrings.checkoutDeliveryOption,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      textColor: AppColors.white);
                  return;
                }
                setState(() {
                  _delivery = value;

                  if (context.read<CheckoutViewModel>().selectedInpost !=
                      null) {
                    _deliverExpanded = true;
                  }
                });
                Provider.of<CheckoutViewModel>(context, listen: false)
                    .setDeliveryChoice(value ?? '');
                if (context.read<CheckoutViewModel>().selectedInpost == null) {
                  showDialog(
                    context: context,
                    builder: (context) => ShareLocationDialog(
                        postcode: postcodeController.text.trim()),
                  );
                }
              }),
          const SizedBox(height: 8),
          ShippingListItem(
              icon: Icons.home,
              title: AppStrings.checkoutShipToHome,
              subtitle: AppStrings.checkoutHomeSubtitle,
              value: 'home',
              groupValue: _delivery,
              onChanged: (value) {
                setState(
                  () {
                    _delivery = value;
                    _deliverExpanded = false;
                  },
                );
                Provider.of<CheckoutViewModel>(context, listen: false)
                    .setShowLocker(false);
                Provider.of<CheckoutViewModel>(context, listen: false)
                    .setDeliveryChoice(value ?? '');
              }),

          // Show pickup points when pickup is selected
          if (_delivery == 'pickup' &&
              context.watch<CheckoutViewModel>().showLocker) ...[
            Consumer<CheckoutViewModel>(builder: (context, model, _) {
              final status = model.status;

              final inposts = model.nearestInpost;

              return Column(
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
                  if (_deliverExpanded) ...[
                    model.selectedInpost != null &&
                            context.watch<CheckoutViewModel>().hasLocker
                        ? Outlined(
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    model.selectedInpost?.name ?? '',
                                    style: TextStyle(),
                                  ),
                                  subtitle:
                                      Text(model.selectedInpost?.address ?? ''),
                                  value: true,
                                  onChanged: null,
                                ),
                              ],
                            ),
                          )
                        : Outlined(
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
                          ),
                  ],
                ],
              );
            })
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
          const Divider(height: 16),
        ],
      ),
    );
  }
}
