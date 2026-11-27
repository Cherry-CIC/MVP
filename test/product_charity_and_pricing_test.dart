import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/charity_details_dialog.dart';
import 'package:cherry_mvp/features/products/widgets/product_charity_card.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/shared_widgets/bottom_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _CheckoutRepositoryStub extends Fake implements ICheckoutRepository {}

class _DonationRepositoryStub extends Fake implements IDonationRepository {}

class _PublicProfileRepositoryStub implements IPublicUserProfileRepository {
  @override
  Future<Result<PublicUser>> fetchUser(String userId) async {
    return Result.success(PublicUser(id: userId, username: 'Dr_Schmella'));
  }

  @override
  Future<Result<PublicUserProfilePage>> fetchProfile(
    String userId, {
    int limit = 20,
    String? cursor,
  }) async {
    return Result.success(
      PublicUserProfilePage(
        user: PublicUser(id: userId, username: 'Dr_Schmella'),
        products: const [],
        nextCursor: null,
        hasMore: false,
      ),
    );
  }
}

class _RecordingNavigator extends NavigationProvider {
  int purchaseSecurityCount = 0;

  @override
  Future<void> showPurchaseSecurity() async {
    purchaseSecurityCount += 1;
  }
}

final _samaritans = Charity(
  id: 'samaritans',
  name: 'Samaritans',
  imageUrl: AppImages.mind,
  description: 'Listening and supporting people around the clock.',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

Product _buildProduct({
  Charity? charity,
  double donation = 8.00,
  double price = 8.00,
}) => Product(
  id: 'shirt-1',
  userId: 'seller-1',
  name: 'Beige Cargo Shirt',
  description: 'Comfortable cotton cargo shirt.',
  quality: 'Good',
  productImages: const [AppImages.product1],
  donation: donation,
  price: price,
  securityFee: 1.00,
  likes: 3,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  charityId: charity?.id,
  charity: charity,
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('donation price greens meet WCAG AA contrast on light and dark surfaces', () {
    final lightBg = const Color(0xFFFAFAFA).computeLuminance();
    final lightFg = AppColors.donationGreen.computeLuminance();
    final lightContrast = (lightBg + 0.05) / (lightFg + 0.05);
    expect(lightContrast, greaterThanOrEqualTo(4.5));

    final darkBg = const Color(0xFF18181B).computeLuminance();
    final darkFg = AppColors.donationGreenDark.computeLuminance();
    final darkContrast = (darkFg + 0.05) / (darkBg + 0.05);
    expect(darkContrast, greaterThanOrEqualTo(4.5));
  });

  testWidgets(
    'ProductPage renders dedicated Donating to card, opens CharityDetailsDialog, and navigates to CharityProfilePage',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navigator = _RecordingNavigator();
      final product = _buildProduct(charity: _samaritans);
      final productViewModel = ProductViewModel(
        productRepository: ProductRepository(const UnexpectedApiService()),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      )..setProduct(product);
      final checkoutViewModel = CheckoutViewModel(
        donationRepository: _DonationRepositoryStub(),
        checkoutRepository: _CheckoutRepositoryStub(),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      );
      addTearDown(productViewModel.dispose);
      addTearDown(checkoutViewModel.dispose);

      CharityProfileArgs? openedCharityArgs;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NavigationProvider>.value(value: navigator),
            Provider<IPublicUserProfileRepository>.value(
              value: _PublicProfileRepositoryStub(),
            ),
            ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
            ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            navigatorKey: navigator.navigatorKey,
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.charityProfile) {
                openedCharityArgs = CharityProfileArgs.fromRouteArgument(settings.arguments);
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Charity Profile Screen')),
                );
              }
              return AppRoutes.generateRoute(settings);
            },
            home: ProductPage(product: product),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Seller row shows seller identity only — no inline charity logo, stars, or Ask seller.
      expect(find.text('Dr_Schmella'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SellerInformation),
          matching: find.byType(CharityLogo),
        ),
        findsNothing,
      );
      expect(find.text(AppStrings.askSeller), findsNothing);

      // Dedicated "Donating to" card sits below ProductInformation and above Description.
      expect(find.byType(ProductCharityCard), findsOneWidget);
      expect(find.text(AppStrings.productPageDonatingTo), findsOneWidget);
      expect(find.text('Samaritans'), findsOneWidget);
      final learnMoreFinder = find.text(AppStrings.productPageCharityLearnMore);
      expect(learnMoreFinder, findsOneWidget);
      expect(
        tester.widget<Text>(learnMoreFinder).style?.color,
        const Color(0xFFF90653),
      );

      final infoBottom = tester.getBottomLeft(find.byType(ProductInformation)).dy;
      final charityTop = tester.getTopLeft(find.byType(ProductCharityCard)).dy;
      final charityBottom = tester.getBottomLeft(find.byType(ProductCharityCard)).dy;
      final descriptionTop = tester.getTopLeft(find.text(AppStrings.productPageDescription)).dy;
      expect(charityTop, greaterThanOrEqualTo(infoBottom));
      expect(descriptionTop, greaterThan(charityBottom));

      // Out-of-scope prototype controls remain absent; Buy Now sticky button remains.
      expect(find.byIcon(Icons.workspace_premium), findsNothing);
      expect(find.text(AppStrings.productPageMakeOffer), findsNothing);
      expect(find.byType(BottomCta), findsOneWidget);
      expect(find.text(AppStrings.productPageBuyNow), findsOneWidget);

      // Tapping Learn More opens CharityDetailsDialog, then View Charity Profile opens CharityProfilePage.
      await tester.tap(learnMoreFinder);
      await tester.pumpAndSettle();
      expect(find.byType(CharityDetailsDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, AppStrings.charityProfileViewButton));
      await tester.pumpAndSettle();
      expect(find.byType(CharityDetailsDialog), findsNothing);
      expect(find.text('Charity Profile Screen'), findsOneWidget);
      expect(openedCharityArgs?.charityId, 'samaritans');
    },
  );

  testWidgets('ProductPage omits Donating to card when product has no charity', (tester) async {
    final navigator = _RecordingNavigator();
    final product = _buildProduct();
    final productViewModel = ProductViewModel(
      productRepository: ProductRepository(const UnexpectedApiService()),
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
    )..setProduct(product);
    final checkoutViewModel = CheckoutViewModel(
      donationRepository: _DonationRepositoryStub(),
      checkoutRepository: _CheckoutRepositoryStub(),
      navigator: navigator,
      currentUserIdProvider: () => 'buyer-1',
    );
    addTearDown(productViewModel.dispose);
    addTearDown(checkoutViewModel.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
          ChangeNotifierProvider<CheckoutViewModel>.value(value: checkoutViewModel),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: ProductPage(product: product),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductCharityCard), findsNothing);
    expect(find.text(AppStrings.productPageDonatingTo), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'ProductInformation styles larger green price with heart, Incl. label, and side-by-side size/quality in $brightness',
      (tester) async {
        final navigator = _RecordingNavigator();
        final productViewModel = ProductViewModel(
          productRepository: ProductRepository(const UnexpectedApiService()),
          navigator: navigator,
          currentUserIdProvider: () => 'buyer-1',
        );
        addTearDown(productViewModel.dispose);
        final product = _buildProduct(charity: _samaritans);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductViewModel>.value(
            value: productViewModel,
            child: MaterialApp(
              theme: buildTheme(brightness),
              home: Scaffold(
                body: SizedBox(width: 390, child: ProductInformation(product: product)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expectedGreen = brightness == Brightness.dark
            ? AppColors.donationGreenDark
            : AppColors.donationGreen;

        final donationPriceText = tester.widget<Text>(find.text('£8.00'));
        final totalPriceText = tester.widget<Text>(find.text('£9.00'));
        final inclText = tester.widget<Text>(find.text(AppStrings.productIncl));
        final heartImage = tester.widget<Image>(
          find.byKey(const ValueKey('product-info-donation-heart')),
        );

        expect(donationPriceText.style?.color, expectedGreen);
        expect((heartImage.image as AssetImage).assetName, AppImages.donationHeart);
        expect(heartImage.color, expectedGreen);
        expect(
          donationPriceText.style!.fontSize!,
          greaterThan(totalPriceText.style!.fontSize!),
        );

        expect(totalPriceText.style?.color, const Color(0xFFF90653));
        expect(inclText.style?.color, const Color(0xFFF90653));

        // Size and condition stay side-by-side to the right of the price column.
        final priceRight = tester.getTopRight(find.text('£8.00')).dx;
        final sizeLeft = tester.getTopLeft(find.text('M')).dx;
        final qualityLeft = tester.getTopLeft(find.text('Good')).dx;
        expect(sizeLeft, greaterThan(priceRight));
        expect(qualityLeft, greaterThan(sizeLeft));

        // Tapping price opens Purchase Security sheet.
        await tester.tap(find.text('£8.00'));
        expect(navigator.purchaseSecurityCount, 1);
      },
    );

    testWidgets(
      'ProductCard styles larger green price with heart and fits narrow 2-column grid in $brightness',
      (tester) async {
        final navigator = _RecordingNavigator();
        final productViewModel = ProductViewModel(
          productRepository: ProductRepository(const UnexpectedApiService()),
          navigator: navigator,
          currentUserIdProvider: () => 'buyer-1',
        );
        addTearDown(productViewModel.dispose);
        final product = _buildProduct(charity: _samaritans);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductViewModel>.value(
            value: productViewModel,
            child: MaterialApp(
              theme: buildTheme(brightness),
              home: Scaffold(
                body: SizedBox(
                  width: 162,
                  child: ProductCard(product: product),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final expectedGreen = brightness == Brightness.dark
            ? AppColors.donationGreenDark
            : AppColors.donationGreen;

        final basePriceText = tester.widget<Text>(find.text('£8.00'));
        final totalPriceText = tester.widget<Text>(find.text('£9.00'));
        final inclText = tester.widget<Text>(find.text(AppStrings.productIncl));
        final heartImage = tester.widget<Image>(
          find.byKey(const ValueKey('product-card-donation-heart-shirt-1')),
        );

        expect(basePriceText.style?.color, expectedGreen);
        expect((heartImage.image as AssetImage).assetName, AppImages.donationHeart);
        expect(heartImage.color, expectedGreen);
        expect(
          basePriceText.style!.fontSize!,
          greaterThan(totalPriceText.style!.fontSize!),
        );
        expect(totalPriceText.style?.color, const Color(0xFFF90653));
        expect(inclText.style?.color, const Color(0xFFF90653));

        await tester.tap(find.text('£8.00'));
        expect(navigator.purchaseSecurityCount, 1);
      },
    );
  }

  testWidgets(
    'ProductCard displays product.donation beside the heart when donation and price differ',
    (tester) async {
      final navigator = _RecordingNavigator();
      final productViewModel = ProductViewModel(
        productRepository: ProductRepository(const UnexpectedApiService()),
        navigator: navigator,
        currentUserIdProvider: () => 'buyer-1',
      );
      addTearDown(productViewModel.dispose);
      final product = _buildProduct(
        charity: _samaritans,
        donation: 6.50,
        price: 8.00,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ProductViewModel>.value(
          value: productViewModel,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(
              body: SizedBox(
                width: 180,
                child: ProductCard(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('£6.50'), findsOneWidget);
      expect(find.text('£8.00'), findsNothing);
      expect(find.text('£9.00'), findsOneWidget);
      expect(find.text(AppStrings.productIncl), findsOneWidget);
    },
  );
}
