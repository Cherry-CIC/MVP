import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectPaymentTypeBottomSheet extends StatefulWidget {
  const SelectPaymentTypeBottomSheet({super.key});

  @override
  State<SelectPaymentTypeBottomSheet> createState() =>   _SelectPaymentTypeBottomSheetState();
}

class _SelectPaymentTypeBottomSheetState extends State<SelectPaymentTypeBottomSheet> {
  PaymentType? _selected;

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutViewModel>(
      builder: (context, vm, _) {
        //final selected = vm.selectedPaymentType;
    
        return BottomSheet(
          backgroundColor:  Theme.of(context).colorScheme.onTertiary,
          onClosing: () {},
          shape: const BeveledRectangleBorder(),
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                width: double.infinity,
                child: Text(
                  AppStrings.paymentMethodsTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(AppStrings.paymentMethodsInfo),
                titleTextStyle: Theme.of(context).textTheme.labelSmall,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Divider(height: 1, color: AppColors.grey,),

              const SizedBox(height: 30,),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text(AppStrings.paymentMethodsCard),
                trailing: Radio<PaymentType>(
                  value: PaymentType.card,   
                  groupValue: vm.selectedPaymentType ,
                  onChanged: (value) {
                    vm.setPaymentType(value!);
                    setState(() => _selected = value);
                  },             
                ),
                onTap: () {
                  vm.setPaymentType(PaymentType.card);
                  _selected = PaymentType.card;
                } 
              ),
              Divider(height: 1, color: AppColors.grey,),

              // Google Pay
              ListTile(
                leading: Image.asset(
                  AppImages.paymentMethodsGoogleIcon,
                  width: 24,
                  height: 24,
                ),
                title: Text(AppStrings.paymentMethodsGooglePay),
                trailing: Radio<PaymentType>(
                  value: PaymentType.google,
                  groupValue: vm.selectedPaymentType ,
                  onChanged: (value) {
                    vm.setPaymentType(value!);
                    setState(() => _selected = value);
                  },
                ),
                onTap: () {
                  vm.setPaymentType(PaymentType.google);
                  _selected = PaymentType.google;
                } 
              ),
              Divider(height: 1, color: AppColors.grey,),

              // Apple Pay
              ListTile(
                leading: Image.asset(
                  AppImages.paymentMethodsAppleIcon,
                  width: 24,
                  height: 24,
                ),
                title: Text(AppStrings.paymentMethodsApplePay),
                trailing: Radio<PaymentType>(
                  value: PaymentType.apple,
                  groupValue: vm.selectedPaymentType ,
                  onChanged: (value) {
                    vm.setPaymentType(value!);
                    setState(() => _selected = value);
                  },
                ),
                onTap: () {
                  vm.setPaymentType(PaymentType.apple);
                  _selected = PaymentType.apple;
                } 
              ),
              Divider(height: 1, color: AppColors.grey,),
              const SizedBox(height: 32),

              Container(
                height: 48,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: _selected != null
                      ? () => Navigator.pop(context, _selected)
                      : null,
                  child: Text(AppStrings.continueText),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          )
        );
      }
    );
  }
}
