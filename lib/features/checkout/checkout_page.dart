import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/basket_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/delivery_options.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<StatefulWidget> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _errorMessage = "";
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

          //if (_errorMessage.isNotEmpty)
          if (_errorMessage.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryAction,
                ),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: AppColors.primaryAction,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SliverList.list(
            children: [
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
                    if (viewModel.createOrderStatus.type ==
                        StatusType.failure) {
                      Fluttertoast.showToast(
                        msg:
                            viewModel.createOrderStatus.message ??
                            "oops! Something went wrong",
                      );
                    } else if (viewModel.createOrderStatus.type ==
                        StatusType.success) {
                      Fluttertoast.showToast(msg: "Payment Successful");

                      gotoCheckoutComplete();
                    }
                    return FilledButton(
                      onPressed: 
                      !viewModel.isShippingAddressConfirmed
                      ? null
                      : () async {
                        if (viewModel.deliveryChoice == null) {
                          setState(() => _errorMessage = AppStrings.checkoutDeliveryOptionRequired);
                          return;
                        }

                        // Validate pickup
                        if (viewModel.deliveryChoice == 'pickup' &&
                            viewModel.selectedInpost == null) {
                          setState(() => _errorMessage = AppStrings.checkoutPickupLockerRequired);
                          return;
                        }

                        if (!viewModel.hasPaymentMethod) {
                          setState(() => _errorMessage = AppStrings.checkoutPaymentMethodRequired);
                          return;
                        }
                        
                        // Clear error
                        setState(() => _errorMessage = '');

                        // 4. Proceed with order
                        await viewModel.storeOrderInFirestore();

                        if (basket.total <= 0) {
                          Fluttertoast.showToast(msg: "Your basket is empty");
                          return;
                        }

                        bool result = await viewModel.payWithPaymentSheet(amount: basket.total);

                        if (result) {
                          await viewModel.createOrder();
                        }
                      },
                      child:
                          viewModel.createOrderStatus.type == StatusType.loading
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

  gotoCheckoutComplete() async {
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, AppRoutes.checkoutComplete);
  }
}
