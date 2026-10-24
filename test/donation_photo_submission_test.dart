import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_reorder_strip.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'support/photo_reorder_actions.dart';

class _DonationRepository implements IDonationRepository {
  final response = Completer<Result<DonationResponse>>();
  final requests = <DonationRequest>[];

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) {
    requests.add(request);
    return response.future;
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() async => Result.success([]);
}

class _Categories implements ICategoryRepository {
  @override
  Future<Result<List<Category>>> fetchCategories() async => Result.success([]);
}

class _Charities implements ICharityRepository {
  @override
  Future<Result<List<Charity>>> fetchCharities() async => Result.success([]);
}

class _Harness {
  final navigator = NavigationProvider();
  final repository = _DonationRepository();
  late final viewModel = DonationViewModel(donationRepository: repository, navigator: navigator);

  Future<void> pump(WidgetTester tester, List<XFile> images) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigator),
          ChangeNotifierProvider<DonationViewModel>.value(value: viewModel),
          ChangeNotifierProvider(
            create: (_) => CategoryViewModel(categoryRepository: _Categories(), navigator: navigator),
          ),
          ChangeNotifierProvider(
            create: (_) => CharityViewModel(charityRepository: _Charities(), navigator: navigator),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator.navigatorKey,
          home: const DonationPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PhotoUpload));
    await tester.runAsync(() async {
      for (final photo in images) {
        final image = FileImage(File(photo.path));
        await precacheImage(image, context);
        await precacheImage(ResizeImage(image, width: 104), context);
      }
    });
    // Supply picker results through the real parent callback.
    tester.widget<PhotoUpload>(find.byType(PhotoUpload)).onImagesChanged!(images);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final form = tester.state<DonationFormState>(find.byType(DonationForm));
    form.selectedCategoryId = 'category';
    form.selectedQuality = 'GOOD';
    form.selectedSize = 'Small';
    form.selectedCharity = dummyCharities.first;
    form.selectedPostageSize = PostageSizeInfo(
      id: 'small',
      type: 'inpost',
      size: PostageSize.small,
      description: 'Small parcel',
      weight: 500,
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Cotton shirt');
    await tester.enterText(find.byType(TextFormField).at(1), 'A pre-loved cotton shirt');
    await tester.enterText(find.byType(TextFormField).at(2), '12');
    final submit = find.widgetWithText(FilledButton, AppStrings.submitDonation);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
  }
}

List<String> _formPaths(WidgetTester tester) =>
    tester.widget<DonationForm>(find.byType(DonationForm)).selectedImages!.map((image) => image.path).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory photos;
  late List<XFile> images;

  setUpAll(() {
    photos = Directory.systemTemp.createTempSync('cherry-donation-photo-test-');
    final png = File('assets/icon/icon.png').readAsBytesSync();
    images = [
      for (final name in ['front', 'back', 'detail'])
        XFile((File('${photos.path}/$name.png')..writeAsBytesSync(png)).path),
    ];
  });

  tearDownAll(() => photos.deleteSync(recursive: true));

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (_) async => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      null,
    );
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('submits reordered photos and preserves the request through a failed upload and later changes', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.pump(tester, images);
    await moveSelectedPhoto(tester, earlier: false);
    await moveSelectedPhoto(tester, earlier: false);
    await moveSelectedPhoto(tester, earlier: true);
    final chosenOrder = [images[1].path, images[0].path, images[2].path];
    expect(_formPaths(tester), chosenOrder);

    await harness.submit(tester);

    expect(harness.repository.requests, hasLength(1));
    final submitted = harness.repository.requests.single;
    expect(submitted.localImages!.map((image) => image.path), chosenOrder);
    expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).enabled, isFalse);
    final strip = tester.widget<PhotoReorderStrip>(find.byType(PhotoReorderStrip));
    strip.onReorder(1, 0);
    expect(_formPaths(tester), chosenOrder);

    harness.repository.response.complete(Result.failure('Upload failed'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).enabled, isTrue);
    expect(_formPaths(tester), chosenOrder);
    await moveSelectedPhoto(tester, earlier: false);
    expect(_formPaths(tester), [images[1].path, images[2].path, images[0].path]);
    expect(submitted.localImages!.map((image) => image.path), chosenOrder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing the form clears both the picker and submitted photo selection', (tester) async {
    final harness = _Harness();
    await harness.pump(tester, images);
    expect(find.byType(PhotoReorderStrip), findsOneWidget);

    tester.widget<DonationForm>(find.byType(DonationForm)).onClearImages!();
    await tester.pumpAndSettle();

    expect(_formPaths(tester), isEmpty);
    expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).initialImages, isEmpty);
    expect(find.byType(PhotoReorderStrip), findsNothing);
    expect(find.text(AppStrings.takePhoto), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
