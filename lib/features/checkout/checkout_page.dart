import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/basket_list_item.dart';
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
  String _errorMessage = "";
  CheckoutViewModel? _vm; // ✅ avoid late-init crash

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final vm = context.read<CheckoutViewModel>();
      _vm = vm;

      vm.resetCreateOrderStatus();
      vm.fetchUserLocker();
      vm.addListener(_handleOrderStatus);
    });
  }

  void _handleOrderStatus() {
    if (!mounted) return;
    final vm = _vm;
    if (vm == null) return;

    final status = vm.createOrderStatus.type;

    if (status == StatusType.failure) {
      Fluttertoast.showToast(
        msg: vm.createOrderStatus.message ?? "oops! Something went wrong",
      );
      vm.resetCreateOrderStatus();
    }

    if (status == StatusType.success) {
      Fluttertoast.showToast(msg: "Payment Successful");
      vm.resetCreateOrderStatus();
      gotoCheckoutComplete();
    }
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

          if (_errorMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAction),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.primaryAction,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Consumer<CheckoutViewModel>(
              builder: (context, vm, _) {
                return ListTile(
                  title: const Text(AppStrings.checkoutPayment),
                  subtitle: Text(
                    vm.selectedPaymentType != null
                        ? vm.selectedPaymentType!.name
                        : AppStrings.paymentMethodsChoose,
                  ),
                  trailing: Icon(
                    vm.selectedPaymentType != null ? Icons.check : Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SelectPaymentTypeBottomSheet(),
                    );
                  },
                );
              },
            ),
          ),

          SliverList.list(
            children: [
              const SizedBox(height: 50),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 56,
        width: double.infinity,
        child: Consumer<CheckoutViewModel>(
          builder: (context, viewModel, _) {
            final isLoading =
                viewModel.createOrderStatus.type == StatusType.loading;

            final hasDeliveryChoice =
                (viewModel.deliveryChoice ?? '').isNotEmpty;
            final isPickup = viewModel.deliveryChoice == 'pickup';

            final hasValidDelivery = hasDeliveryChoice &&
                (isPickup
                    ? viewModel.selectedInpost != null
                    : viewModel.isShippingAddressConfirmed &&
                        viewModel.hasShippingAddress);

            final canAttemptPayment =
                hasValidDelivery && basket.total > 0 && !isLoading;

            return FilledButton(
              onPressed: canAttemptPayment
                  ? () async {
                      // ✅ require payment method
                      if (!viewModel.hasPaymentMethod) {
                        setState(() {
                          _errorMessage =
                              AppStrings.checkoutPaymentMethodRequired;
                        });

                        await showModalBottomSheet<PaymentType>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SelectPaymentTypeBottomSheet(),
                        );

                        if (!viewModel.hasPaymentMethod) return;
                      }

                      setState(() => _errorMessage = '');

                      await viewModel.storeOrderInFirestore();

                      final paid = await viewModel.payWithPaymentSheet(
                        amount: basket.total,
                      );

                      if (paid) {
                        await viewModel.createOrder();
                      }
                    }
                  : null,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppStrings.checkoutPay),
            );
          },
        ),
      ),
    );
  }

  Future<void> gotoCheckoutComplete() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.checkoutComplete);
  }

  @override
  void dispose() {
    _vm?.removeListener(_handleOrderStatus); // ✅ safe
    super.dispose();
  }
}