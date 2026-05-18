import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';

class ShippingMethodDropdown extends StatelessWidget {
  const ShippingMethodDropdown({
    super.key,
    required this.shippingMethods,
  });

  final List<InpostShippingMethod> shippingMethods;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CheckoutViewModel>();

    return DropdownButton<String>(
      itemHeight: 60,
      isExpanded: true,
      value: viewModel.selectedInpostShippingMethod?.id,
      items: shippingMethods.map<DropdownMenuItem<String>>((InpostShippingMethod shippingMethod) {
        return DropdownMenuItem(
          value: shippingMethod.id,
          child: Text(
            '${shippingMethod.name}: Postage ${AppStrings.currencySymbol}${shippingMethod.price.toStringAsFixed(2)}',
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          final selected = shippingMethods.firstWhere((m) => m.id == value);
          viewModel.setSelectedInpostShippingMethod(selected);
        }
      },
    );
  }
}
