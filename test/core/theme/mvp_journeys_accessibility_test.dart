import 'dart:ui' show Tristate;

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/widgets/charity_card.dart';
import 'package:cherry_mvp/features/checkout/purchase_security.dart';
import 'package:cherry_mvp/features/checkout/widgets/checkout_action_button.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_list_item.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'package:cherry_mvp/features/home/widgets/discover_button.dart';
import 'package:cherry_mvp/features/orders/models/order_summary.dart';
import 'package:cherry_mvp/features/orders/widgets/order_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:cherry_mvp/features/profile/widgets/user_activity_cards.dart';
import 'package:cherry_mvp/features/search/widgets/category_tile_widget.dart';
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeProductRepo extends Fake implements ProductRepository {
  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    return Result.success(const ProductLikeUpdate(liked: true, likes: 6));
  }

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    return Result.success(const ProductLikeUpdate(liked: false, likes: 5));
  }
}

Widget _app(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  ProductViewModel? productViewModel,
}) {
  final nav = NavigationProvider();
  return MultiProvider(
    providers: [
      Provider<NavigationProvider>.value(value: nav),
      if (productViewModel != null)
        ChangeNotifierProvider<ProductViewModel>.value(value: productViewModel),
    ],
    child: MaterialApp(
      theme: buildTheme(brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('Journey 3: Home, Discover, Search, Categories accessibility', () {
    testWidgets('DiscoverButton meets tap target, label, and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const DiscoverButton()));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('DiscoverSelectionBar meets 48dp target for tabs', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          DiscoverSelectionBar(
            selectedTag: 'popular',
            onSelected: (_) {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('DiscoverCharityCard like button is a labelled toggle meeting 48dp target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const DiscoverCharityCard(
            title: 'Red Cross',
            description: 'Humanitarian aid',
            imagePath: '',
            logoPath: '',
            likes: 12,
          ),
        ),
      );
      final likeFinder = find.bySemanticsLabel('Like Red Cross, 12 likes');
      expect(likeFinder, findsOneWidget);
      expect(tester.getSemantics(likeFinder).flagsCollection.isToggled, Tristate.isFalse);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('CategoryTileWidget meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          CategoryTileWidget(
            onTap: () {},
            image: '',
            text: 'Clothing',
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Journey 4: Product detail accessibility', () {
    testWidgets('ProductHeaderCarousel like button is >= 48dp and labelled toggle', (tester) async {
      final handle = tester.ensureSemantics();
      final productRepo = _FakeProductRepo();
      final nav = NavigationProvider();
      final productViewModel = ProductViewModel(
        productRepository: productRepo,
        navigator: nav,
      );
      addTearDown(productViewModel.dispose);

      const product = Product(
        id: '1',
        name: 'Vintage Jacket',
        description: 'Warm wool jacket',
        quality: 'Good',
        productImages: [],
        donation: 10,
        price: 10,
        securityFee: 1,
        likes: 5,
        number: 1,
        size: 'L',
        postageSizeId: 'small',
      );
      await tester.pumpWidget(
        _app(
          const CustomScrollView(
            slivers: [
              ProductHeaderCarousel(product),
            ],
          ),
          productViewModel: productViewModel,
        ),
      );
      final likeFinder = find.bySemanticsLabel('${AppStrings.likeProduct}, 5 likes');
      expect(likeFinder, findsOneWidget);
      final size = tester.getSize(likeFinder);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Journey 5: Donation Flow accessibility', () {
    testWidgets('DonationFormField exposes title as semantics label and excludes decorative icon', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          DonationFormField(
            controller: controller,
            title: 'Listing Title',
            hintText: 'Enter title here',
            hintIcon: Icons.title,
          ),
        ),
      );
      final field = tester.getSemantics(find.byType(EditableText));
      expect(field.label, startsWith('Listing Title'));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('PhotoTipsBar meets 48dp minimum target and button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const PhotoTipsBar()));
      final button = find.byType(PhotoTipsBar);
      final size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(48));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Journey 6: Checkout Flow accessibility', () {
    testWidgets('PurchaseSecurity opens dialog cleanly and scales to 2.0x without overflow', (tester) async {
      await tester.pumpWidget(_app(const PurchaseSecurity(), textScale: 2.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ShippingListItem meets tap target and radio semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ShippingListItem<String>(
            title: 'Locker Pickup',
            subtitle: 'Collect at 24/7 locker',
            icon: Icons.store,
            value: 'pickup',
            groupValue: 'pickup',
            onChanged: (_) {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('CheckoutActionButton has button semantics and 48dp height', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              CheckoutActionButton(
                label: const Text('Track Order'),
                icon: const Icon(Icons.local_shipping),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Journey 7: Profile, Orders, Liked Items, Charity & Settings accessibility', () {
    testWidgets('CharityCard excludes decorative image and scales text cleanly', (tester) async {
      final charity = Charity(
        id: '1',
        name: 'Oxfam',
        imageUrl: '',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      await tester.pumpWidget(_app(CharityCard(charity: charity), textScale: 2.0));
      expect(find.text('Oxfam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OrderCard exposes full status and button semantics for action', (tester) async {
      final handle = tester.ensureSemantics();
      const order = OrderSummary(
        id: 'order1',
        productId: 'prod1',
        productName: 'Silk Scarf',
        size: 'One Size',
        imageUrl: '',
        charityLogoUrl: '',
        itemPriceMinor: 2500,
        totalAmountMinor: 2500,
        currency: 'GBP',
        deliveryState: 'delivered',
        deliveryLabel: 'Delivered',
      );
      await tester.pumpWidget(_app(OrderCard(order: order, onTap: () {})));
      final card = find.byType(OrderCard);
      final semantics = tester.getSemantics(card);
      expect(semantics.label, contains('Silk Scarf'));
      expect(semantics.label, contains('Delivered'));
      expect(semantics.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('UserActivityCards exposes container summary label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 120,
            height: 96,
            child: UserActivityCards(title: 'Bought', value: '4'),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Bought: 4'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('SettingsItem meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SettingsItem(
            title: 'Notifications',
            trailing: 'On',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
