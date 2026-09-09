import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/utils/donor_discount_state_store.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';

class DonationViewModel extends ChangeNotifier {
  final IDonationRepository _donationRepository;
  final NavigationProvider navigator;

  DonationViewModel({required this._donationRepository, required this.navigator});

  Status _submissionStatus = Status.uninitialized;
  Status _postageStatus = Status.uninitialized;
  bool _submissionInFlight = false;
  bool _disposed = false;

  Status get submissionStatus => _submissionStatus;
  Status get postageStatus => _postageStatus;
  bool get isSubmitting => _submissionInFlight;

  List<PostageSizeInfo> _postageSizeInfos = [];
  List<PostageSizeInfo> get postageSizeInfos => _postageSizeInfos;

  /// Null means this call was ignored. Only the accepted caller owns its result.
  /// Disposing a form or loading postage never releases the submission lock.
  Future<Result<DonationResponse>?> submitDonation(
    DonationRequest request, {
    bool? donorDiscountActive,
  }) async {
    if (_submissionInFlight || _disposed) return null;
    _submissionInFlight = true;
    _submissionStatus = Status.loading;
    SafeLog.event(AppLogEvent.donationSubmissionStarted);
    try {
      final submittedRequest = request.copyWith(
        localImages: request.localImages == null ? null : List.unmodifiable(request.localImages!),
        productImages: request.productImages == null ? null : List.unmodifiable(request.productImages!),
      );
      notifyListeners();
      final result = await _donationRepository.submitDonation(submittedRequest);

      if (result.isSuccess && result.value != null) {
        // The listing already exists. Local follow-up failure must not invite a retry.
        if (donorDiscountActive != null) {
          try {
            await DonorDiscountStateStore.setDonorDiscountState(result.value!.id, donorDiscountActive);
          } catch (_) {
            SafeLog.event(
              AppLogEvent.donationDiscountPersistenceFailed,
              level: SafeLogLevel.warning,
            );
          }
        }
        _submissionStatus = Status.success;
        SafeLog.event(AppLogEvent.donationSubmissionSucceeded);
        return result;
      }

      final message = result.error ?? AppStrings.failedToSubmitDonation;
      _submissionStatus = Status.failure(message);
      SafeLog.event(
        AppLogEvent.donationSubmissionFailed,
        level: SafeLogLevel.warning,
      );
      return Result.failure(message);
    } catch (_) {
      _submissionStatus = Status.failure(AppStrings.unexpectedErrorOccurred);
      SafeLog.event(
        AppLogEvent.donationSubmissionFailed,
        level: SafeLogLevel.severe,
      );
      return Result.failure(AppStrings.unexpectedErrorOccurred);
    } finally {
      _submissionInFlight = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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
    if (_disposed || _postageStatus.type == StatusType.loading) return;
    _postageStatus = Status.loading;
    notifyListeners();

    try {
      final result = await _donationRepository.fetchPostageSizes();

      if (result.isSuccess && result.value != null) {
        _postageSizeInfos = result.value!;
        _postageStatus = Status.success;
      } else {
        _postageStatus = Status.failure(result.error ?? 'Failed to fetch postage sizes');
        SafeLog.event(
          AppLogEvent.donationPostageSizesLoadFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (e) {
      _postageStatus = Status.failure(AppStrings.postageSizeInfoError);
      SafeLog.event(
        AppLogEvent.donationPostageSizesLoadFailed,
        level: SafeLogLevel.severe,
      );
    }

    if (!_disposed) notifyListeners();
  }

  void goBack([PostageSizeInfo? postageSize]) {
    navigator.goBack(postageSize);
  }
}
