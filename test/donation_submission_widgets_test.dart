import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_page.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:cherry_mvp/features/donation/postage_size_page.dart';
import 'package:cherry_mvp/features/donation/successful_upload_page.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_dialog.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/home/home_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/liked_items/liked_items_page.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'support/donation_test_support.dart';

class _ApiStub extends Mock implements ApiService {}

class _AuthStub extends Mock implements AuthViewModel {
  @override
  Future<void> loadCurrentUser() async {}
}

class _HomeStub implements IHomeRepository {
  @override
  Future<Result<ProductPage>> fetchProducts({int limit = 20, String? cursor, String? search}) async =>
      Result.success(const ProductPage(products: [], limit: 20, nextCursor: null, hasMore: false));
}

class _ListingsStub implements IProfileListingsRepository {
  @override
  Future<Result<ProfileListingsPage>> fetchListings({int limit = 20, String? cursor}) async =>
      Result.success(const ProfileListingsPage(listings: [], limit: 20, nextCursor: null, hasMore: false));
}

class _ProductsStub extends ProductRepository {
  _ProductsStub() : super(_ApiStub());
  @override
  Future<Result<List<Product>>> fetchLikedProducts() async => Result.success([]);
}

class _RouteObserver extends NavigatorObserver {
  final replacements = <Route<dynamic>>[];
  final pushes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes.add(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) replacements.add(oldRoute);
  }
}

// Selector futures are independently controlled; submission navigation always uses real routes.
class _Navigation extends NavigationProvider {
  final selectors = <String, Completer<dynamic>>{};
  @override
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    if (selectors.containsKey(routeName)) return selectors[routeName]!.future;
    return super.navigateTo(routeName, arguments: arguments);
  }
}

class _Harness {
  final repository = ControlledDonationRepository();
  final navigation = _Navigation();
  final observer = _RouteObserver();
  final toasts = <String>[];
  late final viewModel = DonationViewModel(donationRepository: repository, navigator: navigation);
  late CategoryViewModel categories;
  late CharityViewModel charities;

  Future<void> pump(WidgetTester tester, {Widget home = const HomePage()}) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async {
        if (call.method == 'showToast') toasts.add((call.arguments as Map)['msg'] as String);
        return true;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('PonnamKarthik/fluttertoast'),
        null,
      ),
    );
    categories = CategoryViewModel(categoryRepository: DonationCategoriesStub(), navigator: navigation);
    charities = CharityViewModel(charityRepository: DonationCharitiesStub(), navigator: navigation);
    final products = _ProductsStub();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NavigationProvider>.value(value: navigation),
          ChangeNotifierProvider<DonationViewModel>.value(value: viewModel),
          ChangeNotifierProvider<CategoryViewModel>.value(value: categories),
          ChangeNotifierProvider<CharityViewModel>.value(value: charities),
          ChangeNotifierProvider<AuthViewModel>.value(value: _AuthStub()),
          ChangeNotifierProvider(create: (_) => SearchController()),
          ChangeNotifierProvider(create: (_) => HomeViewModel(homeRepository: _HomeStub())),
          ChangeNotifierProvider(create: (_) => ProfileListingsViewModel(repository: _ListingsStub())),
          Provider<ProductRepository>.value(value: products),
          ChangeNotifierProvider(
            create: (_) => ProductViewModel(productRepository: products, navigator: navigation),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigation.navigatorKey,
          navigatorObservers: [observer],
          onGenerateRoute: AppRoutes.generateRoute,
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> open(WidgetTester tester, [String entry = 'Give']) async {
    if (entry == 'Profile') {
      await tester.tap(find.text('Profile'));
      await settle(tester);
      await tester.ensureVisible(find.text(AppStrings.profileListingsCreate));
      await tester.tap(find.text(AppStrings.profileListingsCreate));
    } else {
      await tester.tap(find.text('Give'));
    }
    if (viewModel.isSubmitting) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await settle(tester);
    }
    expect(find.byType(DonationPage), findsOneWidget);
  }

  Future<void> fill(WidgetTester tester, {bool photos = true}) async {
    await tester.enterText(find.widgetWithText(TextFormField, titleHintText), 'Wool jumper');
    await tester.enterText(find.widgetWithText(TextFormField, descriptionHintText), 'Warm wool jumper');
    await tester.enterText(find.widgetWithText(TextFormField, AppStrings.priceText), '12');
    for (final selection in [
      (AppStrings.categoryText, AppRoutes.category, testCategory),
      (AppStrings.charityText, AppRoutes.charity, testCharity),
      (postageSizeHintText, AppRoutes.postageSize, testPostage),
    ]) {
      navigation.selectors[selection.$2] = Completer<dynamic>();
      await tester.ensureVisible(find.ancestor(of: find.text(selection.$1), matching: find.byType(InkWell)).first);
      await tester.tap(find.ancestor(of: find.text(selection.$1), matching: find.byType(InkWell)).first);
      navigation.selectors.remove(selection.$2)!.complete(selection.$3);
      await settle(tester);
    }
    for (final selection in [('Quality', 'GOOD'), ('Size', 'Medium')]) {
      final field = find.byWidgetPredicate(
        (widget) => widget is DonationDropdownField && widget.formFieldsHintText == selection.$1,
      );
      await tester.ensureVisible(field);
      await tester.tap(find.descendant(of: field, matching: find.byType(TextField)));
      await settle(tester);
      await tester.tap(find.text(selection.$2).last);
      await settle(tester);
    }
    if (photos) {
      tester.widget<PhotoUpload>(find.byType(PhotoUpload)).onImagesChanged!([XFile(photoPath)]);
      await settle(tester);
    }
    await tester.ensureVisible(find.text(AppStrings.submitDonation));
    await settle(tester);
  }

  Route<dynamic> formRoute(WidgetTester tester) => ModalRoute.of(tester.element(find.byType(DonationForm)))!;
  Future<void> submit(WidgetTester tester) => tester.tap(find.text(AppStrings.submitDonation));
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // Fluttertoast retains a one-second timer after its method-channel response.
  await tester.pump(const Duration(seconds: 2));
}

late String photoPath;
late String latePhotoPath;
void main() {
  setUpAll(() {
    final directory = Directory.systemTemp.createTempSync('cherry-donation-photos-');
    photoPath = '${directory.path}/photo.png';
    // A real, local image fixture allows FileImage to render without picking or uploading photos.
    final asset = Directory(
      'assets/images',
    ).listSync().whereType<File>().firstWhere((file) => file.path.endsWith('.png'));
    asset.copySync(photoPath);
    latePhotoPath = '${directory.path}/late-photo.png';
    asset.copySync(latePhotoPath);
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  for (final entry in ['Give', 'Profile', 'Liked Items']) {
    testWidgets('$entry replaces the submitted route exactly once and Back cannot reveal it', (tester) async {
      final h = _Harness();
      await h.pump(tester, home: entry == 'Liked Items' ? const LikedItemsPage() : const HomePage());
      await h.open(tester, entry);
      final route = h.formRoute(tester);
      expect(route is DialogRoute, entry != 'Profile');
      await h.fill(tester);
      await h.submit(tester);
      await h.submit(tester); // No rebuild between these taps.
      expect(h.repository.requests, hasLength(1));
      await tester.pump();
      expect(h.viewModel.isSubmitting, isTrue);
      h.repository.submissions.single.complete(Result.success(testDonationResponse()));
      await settle(tester);
      await h.categories.fetchCategories();
      await h.charities.fetchCharities();
      await settle(tester);
      expect(find.byType(SuccessfulUploadPage), findsOneWidget);
      expect(h.observer.replacements, [same(route)]);
      expect(find.byType(DonationPage, skipOffstage: false), findsNothing);
      expect(h.toasts, isEmpty);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(SuccessfulUploadPage), findsNothing);
      expect(find.byType(DonationPage, skipOffstage: false), findsNothing);
      expect(find.byType(entry == 'Liked Items' ? LikedItemsPage : HomePage), findsOneWidget);
    });
  }

  for (final throws in [false, true]) {
    testWidgets('${throws ? 'unexpected exception' : 'failure'} retains the complete draft and permits one retry', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.open(tester);
      await h.fill(tester);
      final originalImages = tester.widget<DonationForm>(find.byType(DonationForm)).selectedImages!;
      await h.submit(tester);
      await tester.pump();
      expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).enabled, isFalse);
      expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == 'Close'))
            .onPressed,
        isNull,
      );
      expect(tester.widget<DonationFormField>(find.byType(DonationFormField).first).enabled, isFalse);
      await tester.tap(find.byTooltip('Close'));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DonationForm), findsOneWidget);
      if (throws) {
        h.repository.submissions.single.completeError(StateError('Private failure detail'));
      } else {
        h.repository.submissions.single.complete(Result.failure('Please try again'));
      }
      await settle(tester);
      expect(h.toasts, [throws ? AppStrings.unexpectedErrorOccurred : 'Please try again']);
      expect(tester.widget<DonationForm>(find.byType(DonationForm)).selectedImages, originalImages);
      expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).initialImages, originalImages);
      expect(tester.widget<PhotoUpload>(find.byType(PhotoUpload)).enabled, isTrue);
      expect(find.text('Wool jumper'), findsOneWidget);
      expect(find.text('Warm wool jumper'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await h.submit(tester);
      await h.submit(tester);
      expect(h.repository.requests, hasLength(2));
      expect(h.repository.requests.last.toJson(), h.repository.requests.first.toJson());
      expect(h.repository.requests.last.localImages!.single.path, photoPath);
      h.repository.submissions.last.complete(Result.success(testDonationResponse()));
      await settle(tester);
      expect(h.observer.replacements, hasLength(1));
    });
  }

  testWidgets('Close, system Back and photo tips are blocked before a rebuild', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.open(tester);
    await h.fill(tester);
    final tips = tester
        .widget<InkWell>(find.ancestor(of: find.text(AppStrings.learnHow), matching: find.byType(InkWell)))
        .onTap!;
    final close = tester
        .widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == 'Close'))
        .onPressed!;
    await h.submit(tester);
    close();
    tips();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(DonationForm), findsOneWidget);
    expect(find.byType(PhotoTipsDialog), findsNothing);
    h.repository.submissions.single.complete(Result.failure('Failed'));
    await settle(tester);
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    expect(find.byType(DonationForm), findsNothing);
  });

  for (final success in [false, true]) {
    testWidgets('forced disposal suppresses old ${success ? 'success' : 'failure'} and protects a reopened draft', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.open(tester);
      await h.fill(tester);
      final route = h.formRoute(tester);
      await h.submit(tester);
      h.navigation.navigatorKey.currentState!.removeRoute(route);
      await settle(tester);
      await h.open(tester);
      final newRoute = h.formRoute(tester);
      expect(h.viewModel.isSubmitting, isTrue);
      expect(await h.viewModel.submitDonation(testDonationRequest()), isNull);
      h.repository.submissions.single.complete(
        success ? Result.success(testDonationResponse()) : Result.failure('Old error'),
      );
      await settle(tester);
      expect(h.formRoute(tester), same(newRoute));
      expect(h.observer.replacements, isEmpty);
      expect(h.toasts, isEmpty);
      expect(find.byType(SuccessfulUploadPage), findsNothing);
      await h.fill(tester);
      expect(find.text('Wool jumper'), findsOneWidget);
      await h.categories.fetchCategories();
      await settle(tester);
      expect(h.formRoute(tester), same(newRoute));
      expect(h.repository.requests, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completed success is not replayed when a new form opens', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.open(tester);
    await h.fill(tester);
    await h.submit(tester);
    h.repository.submissions.single.complete(Result.success(testDonationResponse()));
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    await h.open(tester);
    await h.fill(tester);
    await h.categories.fetchCategories();
    await settle(tester);
    expect(find.byType(DonationForm), findsOneWidget);
    expect(find.text('Wool jumper'), findsOneWidget);
    expect(h.observer.replacements, hasLength(1));
    expect(h.viewModel.submissionStatus.type, StatusType.success);
  });

  for (final selector in [
    (AppStrings.categoryText, AppRoutes.category, otherCategory),
    (AppStrings.charityText, AppRoutes.charity, otherCharity),
    (postageSizeHintText, AppRoutes.postageSize, otherPostage),
  ]) {
    testWidgets('late ${selector.$1} result is ignored during submission and after disposal', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.open(tester);
      await h.fill(tester);
      final pending = Completer<dynamic>();
      h.navigation.selectors[selector.$2] = pending;
      await tester.ensureVisible(find.ancestor(of: find.text(selector.$1), matching: find.byType(InkWell)).first);
      await tester.tap(find.ancestor(of: find.text(selector.$1), matching: find.byType(InkWell)).first);
      await tester.ensureVisible(find.text(AppStrings.submitDonation));
      await h.submit(tester);
      await tester.pump();
      pending.complete(selector.$3);
      await tester.pump();
      expect(h.repository.requests.single.postageSizeId, testPostage.id);
      expect(tester.state<DonationFormState>(find.byType(DonationForm)).selectedCategoryId, testCategory.id);
      expect(tester.state<DonationFormState>(find.byType(DonationForm)).selectedCharity, same(testCharity));
      expect(tester.state<DonationFormState>(find.byType(DonationForm)).selectedPostageSize, same(testPostage));
      expect(h.viewModel.isSubmitting, isTrue);
      h.repository.submissions.single.complete(Result.failure('Failed'));
      await settle(tester);
      final late = Completer<dynamic>();
      h.navigation.selectors[selector.$2] = late;
      await tester.ensureVisible(find.ancestor(of: find.text(selector.$1), matching: find.byType(InkWell)).first);
      await tester.tap(find.ancestor(of: find.text(selector.$1), matching: find.byType(InkWell)).first);
      h.navigation.navigatorKey.currentState!.removeRoute(h.formRoute(tester));
      await settle(tester);
      late.complete(selector.$3);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(h.toasts, ['Failed']);
    });
  }

  testWidgets('invalid fields and missing photos make zero requests', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.open(tester);
    await tester.ensureVisible(find.text(AppStrings.submitDonation));
    await h.submit(tester);
    await settle(tester);
    expect(h.repository.requests, isEmpty);
    await h.fill(tester, photos: false);
    await h.submit(tester);
    await settle(tester);
    expect(h.repository.requests, isEmpty);
    expect(h.toasts.last, AppStrings.pleaseAddPhoto);
  });

  testWidgets('postage page loads, retries, highlights the initial choice and returns a selection', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    final selection = h.navigation.navigateTo(AppRoutes.postageSize, arguments: {'initialPostageSize': otherPostage});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PostageSizePage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    h.repository.postageLoads.single.complete(Result.failure('Postage unavailable'));
    await settle(tester);
    expect(find.text('Postage unavailable'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();
    expect(h.repository.postageLoads, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    h.repository.postageLoads.last.complete(Result.success([testPostage, otherPostage]));
    await settle(tester);
    final selected = find.ancestor(of: find.text(otherPostage.description), matching: find.byType(Row)).first;
    expect(find.descendant(of: selected, matching: find.byIcon(Icons.check_circle)), findsOneWidget);
    final pending = h.viewModel.submitDonation(testDonationRequest());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(testPostage.description), findsOneWidget);
    await tester.tap(find.text(testPostage.description));
    expect(await selection, same(testPostage));
    await settle(tester);
    expect(h.viewModel.isSubmitting, isTrue);
    h.repository.submissions.single.complete(Result.failure('Failed'));
    await pending;
  });

  testWidgets('postage page exceptions show a controlled error and empty success remains usable', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    h.navigation.navigateTo(AppRoutes.postageSize);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    h.repository.postageLoads.single.completeError(StateError('Private details'));
    await settle(tester);
    expect(find.textContaining('Private details'), findsNothing);
    expect(find.text(AppStrings.retry), findsOneWidget);
    await tester.tap(find.text(AppStrings.retry));
    await tester.pump();
    h.repository.postageLoads.last.complete(Result.success([]));
    await settle(tester);
    expect(find.text(AppStrings.noPostageSizeInfosAvailable), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(PostageSizePage), findsNothing);
  });

  testWidgets('postage notifications cannot complete or unlock the visible form', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.open(tester);
    await h.fill(tester);
    await h.submit(tester);
    await tester.pump();
    for (final successful in [true, false]) {
      final postage = h.viewModel.fetchPostageSizes();
      h.repository.postageLoads.last.complete(
        successful ? Result.success([otherPostage]) : Result.failure('Postage failed'),
      );
      await postage;
      await tester.pump();
      expect(h.viewModel.isSubmitting, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(h.toasts, isEmpty);
      expect(h.observer.replacements, isEmpty);
      expect(h.repository.requests.single.postageSizeId, testPostage.id);
      expect(tester.state<DonationFormState>(find.byType(DonationForm)).selectedPostageSize, same(testPostage));
    }
    h.repository.submissions.single.complete(Result.success(testDonationResponse()));
    await settle(tester);
    expect(h.observer.replacements, hasLength(1));
  });

  testWidgets('completion during a forced pop animation cannot navigate from the old form', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await h.open(tester);
    await h.fill(tester);
    await h.submit(tester);
    h.navigation.navigatorKey.currentState!.pop();
    h.repository.submissions.single.complete(Result.success(testDonationResponse()));
    await settle(tester);
    expect(h.observer.replacements, isEmpty);
    expect(h.toasts, isEmpty);
    expect(find.byType(DonationPage, skipOffstage: false), findsNothing);
    expect(find.byType(SuccessfulUploadPage), findsNothing);
  });

  for (final outcome in ['active', 'failed', 'disposed', 'picker exception']) {
    testWidgets('late gallery result is safe when submission is $outcome', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.open(tester);
      await h.fill(tester);
      final photoResult = Completer<List<String>>();
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      var pickerCalls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pickMultiImage');
        pickerCalls++;
        return photoResult.future;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      await tester.ensureVisible(find.byIcon(Icons.add_a_photo));
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await settle(tester);
      await tester.tap(find.text(AppStrings.galleryPhotoMultiple));
      await settle(tester);
      expect(pickerCalls, 1);
      await tester.ensureVisible(find.text(AppStrings.submitDonation));
      await h.submit(tester);
      await tester.pump();
      if (outcome == 'failed') {
        h.repository.submissions.single.complete(Result.failure('Failed'));
        await settle(tester);
      } else if (outcome == 'disposed' || outcome == 'picker exception') {
        h.navigation.navigatorKey.currentState!.removeRoute(h.formRoute(tester));
        await settle(tester);
      }
      if (outcome == 'picker exception') {
        photoResult.completeError(PlatformException(code: 'unavailable'));
      } else {
        photoResult.complete([latePhotoPath]);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      if (outcome == 'active' || outcome == 'failed') {
        expect(tester.widget<DonationForm>(find.byType(DonationForm)).selectedImages, hasLength(1));
      }
      expect(h.repository.requests.single.localImages, hasLength(1));
      if (outcome != 'failed') {
        h.repository.submissions.single.complete(Result.success(testDonationResponse()));
        await settle(tester);
      }
      expect(tester.takeException(), isNull);
      if (outcome == 'disposed' || outcome == 'picker exception') {
        expect(h.observer.replacements, isEmpty);
        expect(h.toasts, isEmpty);
      }
    });
  }

  for (final success in [false, true]) {
    testWidgets('a covering route stays current after ${success ? 'success' : 'failure'}', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.open(tester);
      await h.fill(tester);
      await h.submit(tester);
      final original = h.formRoute(tester);
      final covering = MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Newer page')));
      h.navigation.navigatorKey.currentState!.push(covering);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      h.repository.submissions.single.complete(
        success ? Result.success(testDonationResponse()) : Result.failure('Failed'),
      );
      await settle(tester);
      expect(covering.isCurrent, isTrue);
      expect(find.text('Newer page'), findsOneWidget);
      expect(h.toasts, isEmpty);
      expect(h.observer.replacements, isEmpty);
      expect(original.isActive, !success);
      h.navigation.navigatorKey.currentState!.pop();
      await settle(tester);
      if (success) {
        expect(find.byType(DonationForm, skipOffstage: false), findsNothing);
      } else {
        expect(find.byType(DonationForm), findsOneWidget);
        expect(find.text('Wool jumper'), findsOneWidget);
        expect(find.text(AppStrings.submitDonation), findsOneWidget);
        await h.submit(tester);
        expect(h.repository.requests, hasLength(2));
        h.repository.submissions.last.complete(Result.success(testDonationResponse()));
        await settle(tester);
      }
    });
  }
}
