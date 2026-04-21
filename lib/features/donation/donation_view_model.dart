import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';

class DonationViewModel extends ChangeNotifier {
  final IDonationRepository _donationRepository;
  final NavigationProvider navigator;
  final _log = Logger('DonationViewModel');

  DonationViewModel({required IDonationRepository donationRepository, required this.navigator})
    : _donationRepository = donationRepository;

  Status _status = Status.uninitialized;
  DonationResponse? _lastSubmission;
  String? _submissionMessage;

  Status get status => _status;
  DonationResponse? get lastSubmission => _lastSubmission;
  String? get submissionMessage => _submissionMessage;

  Future<void> submitDonation(DonationRequest request) async {
    _log.info('Starting donation submission for: ${request.name}');

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
        _log.info("Donation submitted successfully with ID: ${result.value!.id}");
      } else {
        _status = Status.failure(result.error ?? "Unknown error");
        _submissionMessage = result.error ?? "Failed to submit donation";
        _log.warning("Donation submission failed: ${result.error}");
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _submissionMessage = AppStrings.unexpectedErrorOccurred;
      _log.severe("Exception during donation submission: $e");
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
}
