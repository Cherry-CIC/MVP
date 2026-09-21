import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _LikeRepository extends ProductRepository {
  _LikeRepository() : super(const UnexpectedApiService());

  int likeCalls = 0;
  int unlikeCalls = 0;

  @override
  Future<Result<ProductLikeUpdate>> likeProduct(Product product) async {
    likeCalls++;
    return Result.success(const ProductLikeUpdate(liked: true, likes: 1));
  }

  @override
  Future<Result<ProductLikeUpdate>> unlikeProduct(String productId) async {
    unlikeCalls++;
    return Result.success(const ProductLikeUpdate(liked: false, likes: 0));
  }
}

void main() {
  late _LikeRepository repository;
  late ProductViewModel viewModel;
  String? currentUserId;

  setUp(() {
    currentUserId = 'seller';
    repository = _LikeRepository();
    viewModel = ProductViewModel(
      productRepository: repository,
      navigator: NavigationProvider(),
      currentUserIdProvider: () => currentUserId,
    );
  });

  tearDown(() => viewModel.dispose());

  test('self-likes never reach the repository or change local state', () async {
    expect((await viewModel.toggleLike(_product)).isSuccess, isFalse);
    expect((await viewModel.setProductLiked(_product, true)).isSuccess, isFalse);
    expect(repository.likeCalls, 0);
    expect(repository.unlikeCalls, 0);
    expect(viewModel.isProductLiked(_product.id), isFalse);
    expect(viewModel.getLikesCount(_product), 0);
    expect(viewModel.isLikeUpdatePending(_product.id), isFalse);
  });

  test('a historical self-like can still be removed', () async {
    viewModel.cacheLikedProducts([_product]);

    final result = await viewModel.setProductLiked(_product, false);

    expect(result.isSuccess, isTrue);
    expect(result.value, isFalse);
    expect(repository.likeCalls, 0);
    expect(repository.unlikeCalls, 1);
    expect(viewModel.isProductLiked(_product.id), isFalse);
  });

  test('other sellers can be liked and ownership follows account changes', () async {
    currentUserId = 'viewer';
    expect(viewModel.isOwnProduct(_product), isFalse);
    expect((await viewModel.toggleLike(_product)).value, isTrue);
    expect(repository.likeCalls, 1);

    currentUserId = 'seller';
    expect(viewModel.isOwnProduct(_product), isTrue);
    expect((await viewModel.setProductLiked(_product, true)).isSuccess, isFalse);
    expect(repository.likeCalls, 1);

    currentUserId = null;
    expect(viewModel.isOwnProduct(_product), isFalse);
  });

  for (final surface in ['card', 'detail']) {
    testWidgets('$surface hides the like control from its owner', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: surface == 'card'
                  ? const SizedBox(width: 250, child: ProductCard(product: _product))
                  : const CustomScrollView(
                      slivers: [ProductHeaderCarousel(_product)],
                    ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_outline), findsNothing);
      expect(find.byKey(const ValueKey('product-like-product-1')), findsNothing);

      currentUserId = 'viewer';
      viewModel.clearUserState();
      await tester.pump();
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pump();
      expect(repository.likeCalls, 1);

      currentUserId = 'seller';
      viewModel.clearUserState();
      await tester.pump();
      expect(find.byIcon(Icons.favorite_outline), findsNothing);
      expect(find.byKey(const ValueKey('product-like-product-1')), findsNothing);

      // Old self-likes must not restore the owner's heart control either.
      viewModel.cacheLikedProducts([_product]);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == AppImages.likeHeart,
        ),
        findsNothing,
      );
      expect(repository.likeCalls, 1);
    });
  }
}

const _product = Product(
  id: 'product-1',
  userId: 'seller',
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
