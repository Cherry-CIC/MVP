import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _product() {
  return const Product(
    id: 'mvp-donor-discount-product',
    name: 'MVP donor discount test item',
    description: 'A test product for donor discount visibility.',
    quality: 'Good',
    productImages: [AppImages.product1],
    donation: 6,
    price: 7,
    securityFee: 1,
    likes: 0,
    number: 1,
    size: 'M',
    postageSizeId: 'small',
  );
}

void main() {
  testWidgets('DonationOptions hides donor discount toggle for the MVP', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DonationOptions(
            isSwitchedOpenToOtherCharity: false,
            toggleSwitchOpenToOtherCharity: null,
            isSwitchedOpenToOffer: false,
            toggleSwitchOpenToOffer: null,
            isSwitchedApplicableBuyerDiscounts: false,
            toggleSwitchApplicableBuyerDiscounts: null,
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.donorDiscountsActiveText), findsNothing);
    expect(find.text(AppStrings.donorDiscountsInactiveText), findsNothing);
  });

  testWidgets('UserOrderDetails hides donor discount profile card for the MVP', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserOrderDetails())),
    );

    expect(find.text(AppStrings.profileUserBuyerDisc), findsNothing);
  });

  testWidgets('ProductPage hides donor discount highlight for the MVP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = _product();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(),
      navigator: NavigationProvider(),
    )..setProduct(product);

    await tester.pumpWidget(
      ChangeNotifierProvider<ProductViewModel>.value(
        value: productViewModel,
        child: const MaterialApp(home: ProductPage()),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productPageDescription), findsOneWidget);
    expect(find.text(AppStrings.productPageBuyerDiscountActive), findsNothing);
    expect(find.text(AppStrings.productPageDonorDiscountInactive), findsNothing);
    expect(
      find.text(AppStrings.productPageDonorDiscountInactiveDetail),
      findsNothing,
    );
  });
}
