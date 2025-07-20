import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/basket/basket_service.dart';
import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:cherry_mvp/features/checkout/widgets/price_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryOptions extends StatefulWidget {
  const DeliveryOptions({super.key});

  @override
  State<DeliveryOptions> createState() => _DeliveryOptionsState();
}

class _DeliveryOptionsState extends State<DeliveryOptions> {
  String? _delivery;
  var _deliverExpanded = false;

  @override
  Widget build(BuildContext context) {
    final basket = context.read<BasketService>();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.list(
        children: [
          const Divider(height: 32),
          PriceListItem(
            title: const Text(AppStrings.checkoutOrderTotal),
            price: basket.total,
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
            price: basket.postage,
            style: Theme.of(context).textTheme.titleMedium,
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
            value: _delivery,
            groupValue: 'pickup',
            onChanged: (value) => setState(
              () => _delivery = value,
            ),
          ),
          const SizedBox(height: 8),
          ShippingListItem(
            icon: Icons.home,
            title: AppStrings.checkoutShipToHome,
            subtitle: AppStrings.checkoutHomeSubtitle,
            value: _delivery,
            groupValue: 'home',
            onChanged: (value) => setState(
              () {
                _delivery = value;
                _deliverExpanded = false;
              },
            ),
          ),
          if (_delivery == 'pickup') ...[
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
            if (_deliverExpanded)
              Outlined(
                child: Column(
                  children: const [
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        AppStrings.checkoutPickupPoint1,
                        style: TextStyle(),
                      ),
                      subtitle: Text(AppStrings.checkoutPickupAddress1),
                      value: true,
                      onChanged: null,
                    ),
                    Divider(height: 1),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(AppStrings.checkoutPickupPoint2,
                          style: TextStyle()),
                      subtitle: Text(AppStrings.checkoutPickupAddress2),
                      value: false,
                      onChanged: null,
                    ),
                    Divider(height: 1),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(AppStrings.checkoutPickupPoint3,
                          style: TextStyle()),
                      subtitle: Text(AppStrings.checkoutPickupAddress3),
                      value: false,
                      onChanged: null,
                    ),
                  ],
                ),
              ),
          ],
          const Divider(height: 16),
        ],
      ),
    );
  }
}
