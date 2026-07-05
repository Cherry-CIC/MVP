import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _product() {
  return const Product(
    id: 'mvp-ask-seller-product',
    name: 'MVP ask seller test item',
    description: 'A test product for ask seller visibility.',
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
  testWidgets('SellerInformation hides ask-seller button for the MVP', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SellerInformation(
            user: UserInformation(
              username: 'Seller',
              location: 'United Kingdom',
              reviewsCount: 0,
              followersCount: 0,
              followingCount: 0,
              rating: 0,
              awards: 0,
              hasBuyerDiscounts: false,
            ),
            charity: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('Seller'), findsOneWidget);
    expect(find.text(AppStrings.askSeller), findsNothing);
  });

  testWidgets('ProductPage hides ask-seller control for the MVP', (
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

    expect(find.text(AppStrings.productPageBuyNow), findsOneWidget);
    expect(find.text(AppStrings.askSeller), findsNothing);
  });
}
