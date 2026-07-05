import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _product() {
  return const Product(
    id: 'mvp-other-charity-product',
    name: 'MVP other charity test item',
    description: 'A test product for other charity visibility.',
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
  testWidgets('DonationOptions hides open-to-other-charities toggle for the MVP', (
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

    expect(find.text(AppStrings.donationOptionsText), findsOneWidget);
    expect(find.text(AppStrings.openToOtherCharitiesText), findsNothing);
  });

  testWidgets('ProductPage hides request-other-charity control for the MVP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(),
      navigator: NavigationProvider(),
    )..setProduct(_product());

    await tester.pumpWidget(
      ChangeNotifierProvider<ProductViewModel>.value(
        value: productViewModel,
        child: const MaterialApp(home: ProductPage()),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productPageDescription), findsOneWidget);
    expect(find.text(AppStrings.productPageOpenToOtherCharities), findsNothing);
    expect(find.text(AppStrings.productPageRequestOtherCharity), findsNothing);
  });
}
