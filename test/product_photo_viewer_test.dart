import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/widgets/image_carousel.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_header_carousel.dart';
import 'package:cherry_mvp/features/products/widgets/product_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

const _images = [AssetImage(AppImages.product1), AssetImage(AppImages.product2), AssetImage(AppImages.product3)];

Future<void> _openViewer(
  WidgetTester tester, {
  List<ImageProvider> images = _images,
  int initialIndex = 0,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ProductPhotoViewer(images: images, initialIndex: initialIndex),
              ),
            ),
            child: const Text('Open photos'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open photos'));
  await tester.pumpAndSettle();
}

Finder get _pages => find.descendant(of: find.byType(ProductPhotoViewer), matching: find.byType(PageView));

void main() {
  testWidgets('opens the selected photo and pages horizontally without dismissing', (tester) async {
    await _openViewer(tester, initialIndex: 1);
    await tester.runAsync(() => precacheImage(_images[1], tester.element(_pages)));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    final selectedImage = tester.widget<Image>(find.byType(Image).hitTestable());
    expect(selectedImage.image, _images[1]);
    expect(selectedImage.fit, BoxFit.contain);
    final renderedImage = tester.widget<RawImage>(find.byType(RawImage).hitTestable());
    expect(renderedImage.image, isNotNull);
    expect(renderedImage.fit, BoxFit.contain);

    // Slight vertical movement should still be recognised as a horizontal swipe.
    await tester.drag(_pages, const Offset(-600, 35));
    await tester.pumpAndSettle();
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.byType(ProductPhotoViewer), findsOneWidget);

    await tester.drag(_pages, const Offset(600, -35));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final direction in [-1.0, 1.0]) {
    testWidgets('vertical swipe $direction closes only the viewer', (tester) async {
      await _openViewer(tester);
      await tester.drag(_pages, Offset(20, direction * 240));
      await tester.pumpAndSettle();
      expect(find.byType(ProductPhotoViewer), findsNothing);
      expect(find.text('Open photos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a small vertical drag returns the photo to its original position', (tester) async {
    await _openViewer(tester);
    final initialPosition = tester.getTopLeft(_pages);
    await tester.timedDrag(_pages, const Offset(0, 40), const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPhotoViewer), findsOneWidget);
    expect(tester.getTopLeft(_pages), initialPosition);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('labelled controls browse to both ends and close the viewer', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openViewer(tester);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left)).onPressed, isNull);
    for (var page = 2; page <= 3; page++) {
      await tester.tap(find.byTooltip(AppStrings.nextPhoto));
      await tester.pumpAndSettle();
      expect(find.text('$page of 3'), findsOneWidget);
    }
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right)).onPressed, isNull);
    await tester.tap(find.byTooltip(AppStrings.previousPhoto));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip(AppStrings.closePhotoViewer)).getSemanticsData().tooltip,
      AppStrings.closePhotoViewer,
    );
    expect(tester.getSize(find.byTooltip(AppStrings.closePhotoViewer)).shortestSide, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip(AppStrings.closePhotoViewer));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPhotoViewer), findsNothing);
    semantics.dispose();
  });

  testWidgets('a single photo has no paging controls and supports system back', (tester) async {
    await _openViewer(tester, images: [_images.first]);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.byTooltip(AppStrings.nextPhoto), findsNothing);
    expect(find.byTooltip(AppStrings.previousPhoto), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProductPhotoViewer), findsNothing);
    expect(find.text('Open photos'), findsOneWidget);
  });

  testWidgets('a failed image still allows paging and dismissal', (tester) async {
    await _openViewer(tester, images: [const AssetImage('assets/missing-photo.png'), _images.first]);
    expect(find.text(AppStrings.photoUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(AppStrings.nextPhoto));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.drag(_pages, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPhotoViewer), findsNothing);
  });

  for (final brightness in Brightness.values) {
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      testWidgets('controls fit $size with large text in $brightness', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _openViewer(tester, brightness: brightness, textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.byTooltip(AppStrings.closePhotoViewer).hitTestable(), findsOneWidget);
        expect(find.byTooltip(AppStrings.nextPhoto).hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip(AppStrings.nextPhoto));
        await tester.pumpAndSettle();
        expect(find.text('2 of 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final imagePaths in [
    <String>[],
    [AppImages.product1, AppImages.product2, AppImages.product3],
  ]) {
    testWidgets('product header opens photos and preserves the page: ${imagePaths.length} photos', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final viewModel = ProductViewModel(
        productRepository: ProductRepository(const UnexpectedApiService()),
        navigator: NavigationProvider(),
        currentUserIdProvider: () => 'seller',
      );
      addTearDown(viewModel.dispose);
      final scrollController = ScrollController(initialScrollOffset: 40);
      addTearDown(scrollController.dispose);
      final product = Product(
        id: 'product-1',
        userId: 'seller',
        name: 'Jumper',
        description: 'Blue jumper',
        quality: 'Good',
        productImages: imagePaths,
        donation: 20,
        price: 20,
        securityFee: 2,
        likes: 0,
        number: 1,
        size: 'M',
        postageSizeId: 'small',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductViewModel>.value(
          value: viewModel,
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: scrollController,
                slivers: [
                  ProductHeaderCarousel(product),
                  const SliverToBoxAdapter(child: SizedBox(height: 1200, child: Text('Product details'))),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (imagePaths.isEmpty) {
        await tester.tapAt(const Offset(200, 200));
        await tester.pumpAndSettle();
        expect(find.byType(ProductPhotoViewer), findsNothing);
      } else {
        final carousel = find.descendant(of: find.byType(ImageCarousel), matching: find.byType(PageView));
        await tester.drag(carousel, const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('View full photo 2 of 3'), findsOneWidget);
        final offsetBefore = scrollController.offset;
        await tester.tap(carousel);
        await tester.pumpAndSettle();
        expect(find.text('2 of 3'), findsOneWidget);
        await tester.drag(_pages, const Offset(0, 250));
        await tester.pumpAndSettle();
        expect(find.byType(ProductPhotoViewer), findsNothing);
        expect(scrollController.offset, offsetBefore);
        await tester.tap(carousel);
        await tester.pumpAndSettle();
        expect(find.text('2 of 3'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
