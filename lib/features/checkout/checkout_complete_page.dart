import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/widgets/basket_list_item.dart';
import 'package:cherry_mvp/features/checkout/widgets/checkout_action_button.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class CheckoutCompletePage extends StatelessWidget {
  const CheckoutCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final basket = context.read<CheckoutViewModel>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: MediaQuery.of(context).padding,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 64, 48, 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shadows: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .6),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        shape: const CircleBorder(),
                      ),
                      height: 120,
                      width: 120,
                      child: Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.checkoutOrderPlaced,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.checkoutThankYou,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.checkoutEscrowInfo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final product in basket.basketItems)
              BasketListItem(product: product),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              child: Row(
                spacing: 8,
                children: [
                  CheckoutActionButton(
                    label: Text(AppStrings.checkoutTrackOrders),
                    icon: SvgPicture.asset(
                      AppImages.checkoutTrackOrdersIcon,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                      height: 24,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CheckoutActionButton(
                    label: Text(AppStrings.checkoutImpactSummary),
                    icon: SvgPicture.asset(
                      AppImages.checkoutImpactSummaryIcon,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                      height: 24,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CheckoutActionButton(
                    label: Text(AppStrings.checkoutReview),
                    icon: SvgPicture.asset(
                      AppImages.checkoutReviewIcon,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                      height: 24,
                      width: 24,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              height: 56,
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Provider.of<CheckoutViewModel>(
                    context,
                    listen: false,
                  ).resetCheckout();
                  Navigator.of(context).pushAndRemoveUntil(
                    CupertinoPageRoute(builder: (context) => HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text(AppStrings.checkoutContinueShopping),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
