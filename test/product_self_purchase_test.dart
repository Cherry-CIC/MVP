import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CheckoutRepositoryStub implements ICheckoutRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DonationRepositoryStub implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProductPage disables purchase for the signed-in seller', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigator = NavigationProvider();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(),
      navigator: navigator,
    )..setProduct(_product);
    final checkoutViewModel = CheckoutViewModel(
      donationRepository: _DonationRepositoryStub(),
      checkoutRepository: _CheckoutRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'seller-1',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<ProductViewModel>.value(
            value: productViewModel,
          ),
          ChangeNotifierProvider<CheckoutViewModel>.value(
            value: checkoutViewModel,
          ),
        ],
        child: const MaterialApp(home: ProductPage()),
      ),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, AppStrings.productPageYourListing),
    );
    expect(button.onPressed, isNull);
    expect(checkoutViewModel.basketItems, isEmpty);
  });
}

const _product = Product(
  id: 'product-1',
  userId: 'seller-1',
  name: 'Jumper',
  description: 'Blue jumper',
  quality: 'Good',
  productImages: [AppImages.product1],
  donation: 20,
  price: 20,
  securityFee: 2,
  likes: 0,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
);
