import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/basket_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/card_details_bottom_sheet.dart';
import 'package:cherry_mvp/features/checkout/widgets/delivery_options.dart';
import 'package:cherry_mvp/features/checkout/widgets/select_payment_type_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<StatefulWidget> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CheckoutViewModel>(context, listen: false).fetchUserLocker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final basket = context.read<CheckoutViewModel>();
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(AppStrings.checkoutTitle),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: basket.basketItems.length,
            itemBuilder: (context, index) {
              final product = basket.basketItems[index];
              return BasketListItem(
                product: product,
                onRemove: () => basket.removeItem(product),
              );
            },
          ),
          DeliveryOptions(),
          SliverList.list(
            children: [
              ListTile(
                onTap: () async {
                  final checkoutViewModel = context.read<CheckoutViewModel>();
                  if (checkoutViewModel.deliveryChoice != null) {
                    if (checkoutViewModel.deliveryChoice == "pickup" &&
                        checkoutViewModel.selectedInpost == null) {
                      Fluttertoast.showToast(msg: "choose pick up point");
                      return;
                    }

                    final selected = await showModalBottomSheet<PaymentType>(
                      context: context,
                      enableDrag: false,
                      isScrollControlled: false,
                      builder: (context) =>
                          const SelectPaymentTypeBottomSheet(),
                    );
                    if (selected == null || !context.mounted) return;
                    if (selected == PaymentType.card) {
                      showModalBottomSheet(
                        context: context,
                        enableDrag: false,
                        isScrollControlled: true,
                        builder: (context) => const CardDetailsBottomSheet(),
                      );
                    }
                  }
                },
                title: const Text(AppStrings.checkoutPayment),
                titleTextStyle: Theme.of(context).textTheme.labelMedium,
                subtitle: const Text(AppStrings.checkoutChoosePayment),
                trailing: const Icon(Icons.add),
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    Text(
                      AppStrings.checkoutSecure,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 56,
                width: double.infinity,
                child: Consumer<CheckoutViewModel>(
                  builder: (context, viewModel, _) {
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   if (viewModel.status.type == StatusType.failure) {
                    //     Fluttertoast.showToast(
                    //       msg:
                    //           viewModel.status.message ??
                    //           "Something went wrong",
                    //     );
                    //   } else if (viewModel.status.type == StatusType.success) {
                    //     Fluttertoast.showToast(msg: "Payment Successful");
                    //     Navigator.pushReplacementNamed(
                    //       context,
                    //       AppRoutes.checkoutComplete,
                    //     );
                    //   }
                    // });
                    return FilledButton(
                      onPressed: () async {
                        // if (viewModel.deliveryChoice == "pickup" &&
                        //     viewModel.selectedInpost != null) {
                        //   await viewModel.storeLockerInFirestore();
                        // }
                        // // Store dummy order in Firestore
                        // await viewModel.storeOrderInFirestore();

                        if (basket.total > 0) {
                          bool result = await viewModel.payWithPaymentSheet(
                            amount: basket.total,
                          );
                          if (result) {
                            await viewModel.createOrder();
                          }
                        } else {
                          Fluttertoast.showToast(msg: "Your basket is empty");
                        }
                      },
                      child: viewModel.status.type == StatusType.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(AppStrings.checkoutPay),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }
}
