import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/donor_discount_state_store.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/donation_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ControlledDonationRepository repository;
  late DonationViewModel viewModel;

  setUp(() {
    repository = ControlledDonationRepository();
    viewModel = DonationViewModel(donationRepository: repository, navigator: NavigationProvider());
  });

  test('overlapping calls accept one request and give no result to the ignored caller', () async {
    final first = viewModel.submitDonation(testDonationRequest());
    final second = viewModel.submitDonation(testDonationRequest());
    expect(repository.requests, hasLength(1));
    expect(await second, isNull);
    expect(viewModel.isSubmitting, isTrue);
    repository.submissions.single.complete(Result.success(testDonationResponse()));
    expect((await first)!.isSuccess, isTrue);
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.submissionStatus.type, StatusType.success);
  });

  for (final outcome in ['success', 'failure', 'exception']) {
    test('postage $outcome cannot alter or unlock an active submission', () async {
      final pending = viewModel.submitDonation(testDonationRequest());
      final postage = viewModel.fetchPostageSizes();
      expect(viewModel.postageStatus.type, StatusType.loading);
      expect(viewModel.submissionStatus.type, StatusType.loading);
      switch (outcome) {
        case 'success':
          repository.postageLoads.single.complete(Result.success([testPostage]));
        case 'failure':
          repository.postageLoads.single.complete(Result.failure('Postage unavailable'));
        case 'exception':
          repository.postageLoads.single.completeError(StateError('Unexpected'));
      }
      await postage;
      expect(viewModel.postageStatus.type, outcome == 'success' ? StatusType.success : StatusType.failure);
      expect(viewModel.submissionStatus.type, StatusType.loading);
      expect(viewModel.isSubmitting, isTrue);
      expect(await viewModel.submitDonation(testDonationRequest()), isNull);
      repository.submissions.single.complete(Result.failure('Try again'));
      await pending;
    });
  }

  for (final throws in [false, true]) {
    test('${throws ? 'exception' : 'failure'} releases the lock for a deliberate retry', () async {
      final first = viewModel.submitDonation(testDonationRequest());
      if (throws) {
        repository.submissions.single.completeError(StateError('Private exception detail'));
      } else {
        repository.submissions.single.complete(Result.failure('Could not submit'));
      }
      final result = (await first)!;
      expect(result.isSuccess, isFalse);
      expect(result.error, throws ? AppStrings.unexpectedErrorOccurred : 'Could not submit');
      expect(viewModel.submissionStatus.type, StatusType.failure);
      expect(viewModel.isSubmitting, isFalse);
      final retry = viewModel.submitDonation(testDonationRequest());
      expect(repository.requests, hasLength(2));
      repository.submissions.last.complete(Result.success(testDonationResponse()));
      expect((await retry)!.isSuccess, isTrue);
    });
  }

  test('accepted requests own immutable copies of both image lists', () async {
    final images = [XFile('photo.jpg')];
    final urls = ['existing-image'];
    final input = testDonationRequest(images: images, urls: urls);
    final pending = viewModel.submitDonation(input);
    images.clear();
    urls.add('late-image');
    final accepted = repository.requests.single;
    expect(accepted.localImages!.single.path, 'photo.jpg');
    expect(accepted.productImages, ['existing-image']);
    expect(() => accepted.localImages!.clear(), throwsUnsupportedError);
    expect(() => accepted.productImages!.clear(), throwsUnsupportedError);
    expect(accepted.toJson(), testDonationRequest(urls: ['existing-image']).toJson());
    repository.submissions.single.complete(Result.success(testDonationResponse()));
    await pending;
  });

  test('disposing the view model does not notify after asynchronous completion', () async {
    final pending = viewModel.submitDonation(testDonationRequest());
    final postage = viewModel.fetchPostageSizes();
    viewModel.dispose();
    expect(await viewModel.submitDonation(testDonationRequest()), isNull);
    repository.submissions.single.complete(Result.success(testDonationResponse()));
    repository.postageLoads.single.complete(Result.success([testPostage]));
    await Future.wait([pending, postage]);
    expect(repository.requests, hasLength(1));
  });

  test('enabled donor-discount follow-up persists the captured value once', () async {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    final pending = viewModel.submitDonation(testDonationRequest(), donorDiscountActive: true);
    repository.submissions.single.complete(Result.success(testDonationResponse()));
    expect((await pending)!.isSuccess, isTrue);
    expect(await DonorDiscountStateStore.getDonorDiscountState('created-listing'), isTrue);
  });

  test('local persistence failure preserves success and keeps the lock until handled', () async {
    SharedPreferences.resetStatic();
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    final persistence = Completer<bool>();
    var writes = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return <String, Object>{};
      writes++;
      return persistence.future;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      SharedPreferences.resetStatic();
    });
    final pending = viewModel.submitDonation(testDonationRequest(), donorDiscountActive: false);
    repository.submissions.single.complete(Result.success(testDonationResponse()));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.isSubmitting, isTrue);
    expect(await viewModel.submitDonation(testDonationRequest()), isNull);
    persistence.completeError(PlatformException(code: 'unavailable'));
    expect((await pending)!.isSuccess, isTrue);
    expect(writes, 1);
    expect(viewModel.submissionStatus.type, StatusType.success);
    expect(viewModel.isSubmitting, isFalse);
  });
}
