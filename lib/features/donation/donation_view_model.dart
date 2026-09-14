import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';

class DonationViewModel extends ChangeNotifier {
  final IDonationRepository _donationRepository;
  final NavigationProvider navigator;

  DonationViewModel({required IDonationRepository donationRepository, required this.navigator})
    : _donationRepository = donationRepository;

  Status _status = Status.uninitialized;
  DonationResponse? _lastSubmission;
  String? _submissionMessage;

  Status get status => _status;
  DonationResponse? get lastSubmission => _lastSubmission;
  String? get submissionMessage => _submissionMessage;

  List<PostageSizeInfo> _postageSizeInfos = [];
  List<PostageSizeInfo> get postageSizeInfos => _postageSizeInfos;

  Future<void> submitDonation(DonationRequest request) async {
    SafeLog.event(AppLogEvent.donationSubmissionStarted);

    _status = Status.loading;
    _submissionMessage = null;
    _lastSubmission = null;
    notifyListeners();

    try {
      final result = await _donationRepository.submitDonation(request);

      if (result.isSuccess) {
        _status = Status.success;
        _lastSubmission = result.value!;
        _submissionMessage = AppStrings.donationSubmittedSuccessfully;
        SafeLog.event(AppLogEvent.donationSubmissionSucceeded);
      } else {
        _status = Status.failure(result.error ?? "Unknown error");
        _submissionMessage = result.error ?? "Failed to submit donation";
        SafeLog.event(
          AppLogEvent.donationSubmissionFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (e) {
      _status = Status.failure(AppStrings.unexpectedErrorOccurred);
      _submissionMessage = AppStrings.unexpectedErrorOccurred;
      SafeLog.event(
        AppLogEvent.donationSubmissionFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  void resetStatus() {
    _status = Status.uninitialized;
    _submissionMessage = null;
    _lastSubmission = null;
    notifyListeners();
  }

  Future<void> showDonationSuccess() async {
    navigator.navigateTo(AppRoutes.donationSuccess);
  }

  void selectType([ImageSource? imgSource]) {
    navigator.goBack(imgSource);
  }

  Future<Category?> navigateToCategoryPage(String selectedCategoryId) async {
    final Category? result = await navigator.navigateTo(
      AppRoutes.category,
      arguments: {
        'selectionMode': true,
        'initialCategoryId': selectedCategoryId.isNotEmpty ? selectedCategoryId : null,
      },
    );

    return result;
  }

  Future<Charity?> navigateToCharityPage(String? selectedCharityId) async {
    final Charity? result = await navigator.navigateTo(
      AppRoutes.charity,
      arguments: {
        'selectionMode': true,
        'initialCharityId': selectedCharityId,
      },
    );

    return result;
  }

  Future<PostageSizeInfo?> navigateToPostageSizePage(PostageSizeInfo? selectedPostageSize) async {
    return await navigator.navigateTo(
      AppRoutes.postageSize,
      arguments: {'initialPostageSize': selectedPostageSize},
    );
  }

  Future<void> fetchPostageSizes() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await _donationRepository.fetchPostageSizes();

      if (result.isSuccess && result.value != null) {
        _postageSizeInfos = result.value!;
        _status = Status.success;
      } else {
        _status = Status.failure(result.error ?? 'Failed to fetch postage sizes');
        SafeLog.event(
          AppLogEvent.donationPostageSizesLoadFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      SafeLog.event(
        AppLogEvent.donationPostageSizesLoadFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  void goBack([PostageSizeInfo? postageSize]) {
    navigator.goBack(postageSize);
  }
}
