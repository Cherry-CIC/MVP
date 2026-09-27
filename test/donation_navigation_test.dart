import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:cherry_mvp/features/donation/successful_upload_page.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class _DonationRepository implements IDonationRepository {
  final response = Completer<Result<DonationResponse>>();
  int submissions = 0;

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) {
    submissions++;
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

class _DonationViewModel extends DonationViewModel {
  _DonationViewModel({required super.donationRepository, required super.navigator});

  void repeatNotification() => notifyListeners();
}

class _Observer extends NavigatorObserver {
  final List<Route<dynamic>> pushes = [];
  final List<Route<dynamic>> pops = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => pops.add(route);
}

class _UploadHarness {
  final navigator = NavigationProvider();
  final repository = _DonationRepository();
  final observer = _Observer();
  late final viewModel = _DonationViewModel(donationRepository: repository, navigator: navigator);
  Future<dynamic>? uploadResult;
  int clearImagesCalls = 0;

  Future<void> pump(WidgetTester tester) async {
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
          navigatorObservers: [observer],
          onGenerateRoute: AppRoutes.generateRoute,
          home: const Scaffold(body: Text('Existing navigation shell')),
        ),
      ),
    );
    uploadResult = navigator.navigatorKey.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SingleChildScrollView(
            child: DonationForm(
              selectedImages: [XFile('/test/photo.jpg')],
              onClearImages: () => clearImagesCalls++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<VoidCallback> prepareSubmission(WidgetTester tester) async {
    // Set selection values to exercise the real validated submit handler.
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
    await tester.enterText(find.byType(TextFormField).at(0), 'New shirt');
    await tester.enterText(find.byType(TextFormField).at(1), 'A cotton shirt');
    await tester.enterText(find.byType(TextFormField).at(2), '12');
    final submit = find.widgetWithText(FilledButton, AppStrings.submitDonation);
    await tester.ensureVisible(submit);
    return tester.widget<FilledButton>(submit).onPressed!;
  }
}

DonationResponse _successfulResponse() => DonationResponse(
  success: true,
  message: AppStrings.donationSubmittedSuccessfully,
  data: const Product(
    id: 'new-listing',
    name: 'New shirt',
    description: 'A cotton shirt',
    quality: 'GOOD',
    productImages: [],
    donation: 12,
    price: 12,
    securityFee: 0,
    likes: 0,
    number: 1,
    size: 'Small',
    postageSizeId: 'small',
  ),
);

void main() {
  final toastCalls = <MethodCall>[];
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    toastCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      (call) async {
        toastCalls.add(call);
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('PonnamKarthik/fluttertoast'),
      null,
    );
  });

  for (final useSystemBack in [false, true]) {
    testWidgets('successful submission completes once via ${useSystemBack ? 'Back' : 'Continue'}', (tester) async {
      final harness = _UploadHarness();
      addTearDown(harness.viewModel.dispose);
      await harness.pump(tester);
      final submit = await harness.prepareSubmission(tester);
      submit();
      submit();
      await tester.pump();

      expect(harness.repository.submissions, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SuccessfulUploadPage), findsNothing);

      harness.repository.response.complete(Result.success(_successfulResponse()));
      await tester.pumpAndSettle();
      harness.viewModel.repeatNotification();
      harness.viewModel.repeatNotification();
      await tester.pumpAndSettle();

      expect(find.byType(SuccessfulUploadPage), findsOneWidget);
      expect(harness.observer.pushes, hasLength(3));
      expect(harness.clearImagesCalls, 1);
      expect(harness.viewModel.status.type, StatusType.uninitialized);
      expect(harness.viewModel.lastSubmission, isNull);

      if (useSystemBack) {
        await tester.binding.handlePopRoute();
      } else {
        final continueAction = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.continueText),
            )
            .onPressed!;
        continueAction();
        continueAction();
      }
      await tester.pumpAndSettle();

      expect(await harness.uploadResult, isTrue);
      expect(harness.observer.pops, hasLength(2));
      expect(find.byType(DonationForm), findsNothing);
      expect(find.byType(SuccessfulUploadPage), findsNothing);
      expect(find.text('Existing navigation shell'), findsOneWidget);
      expect(harness.navigator.navigatorKey.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  for (final throws in [false, true]) {
    testWidgets('${throws ? 'thrown error' : 'failed upload'} keeps form and does not navigate', (tester) async {
      final harness = _UploadHarness();
      addTearDown(harness.viewModel.dispose);
      await harness.pump(tester);
      final submit = await harness.prepareSubmission(tester);
      submit();
      await tester.pump();
      if (throws) {
        harness.repository.response.completeError(StateError('Upload failed'));
      } else {
        harness.repository.response.complete(Result.failure('Upload failed'));
      }
      await tester.pumpAndSettle();
      harness.viewModel.repeatNotification();
      await tester.pumpAndSettle();
      // Finish the toast plugin's one-second dismissal timer.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DonationForm), findsOneWidget);
      expect(find.text('New shirt'), findsOneWidget);
      expect(find.byType(SuccessfulUploadPage), findsNothing);
      expect(harness.observer.pushes, hasLength(2));
      expect(harness.observer.pops, isEmpty);
      expect(harness.clearImagesCalls, 0);
      expect(toastCalls, hasLength(1));
      expect(harness.viewModel.status.type, StatusType.failure);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completion after the upload route is dismissed does not navigate', (tester) async {
    final harness = _UploadHarness();
    addTearDown(harness.viewModel.dispose);
    await harness.pump(tester);
    final submit = await harness.prepareSubmission(tester);
    submit();
    harness.navigator.goBack();
    harness.repository.response.complete(Result.success(_successfulResponse()));
    await tester.pumpAndSettle();

    expect(await harness.uploadResult, isNull);
    expect(harness.observer.pushes, hasLength(2));
    expect(find.byType(SuccessfulUploadPage), findsNothing);
    expect(find.text('Existing navigation shell'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('success closes a selection screen covering the pending upload', (tester) async {
    final harness = _UploadHarness();
    addTearDown(harness.viewModel.dispose);
    await harness.pump(tester);
    final submit = await harness.prepareSubmission(tester);
    submit();
    final selection = harness.navigator.navigatorKey.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Selection screen'))),
    );
    await tester.pump();
    harness.repository.response.complete(Result.success(_successfulResponse()));
    await tester.pumpAndSettle();

    await selection;
    expect(find.text('Selection screen'), findsNothing);
    expect(find.byType(SuccessfulUploadPage), findsOneWidget);
    expect(harness.repository.submissions, 1);
    expect(harness.clearImagesCalls, 1);

    await tester.tap(find.text(AppStrings.continueText));
    await tester.pumpAndSettle();

    expect(await harness.uploadResult, isTrue);
    expect(harness.observer.pushes, hasLength(4));
    expect(harness.observer.pops, hasLength(3));
    expect(harness.navigator.navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
