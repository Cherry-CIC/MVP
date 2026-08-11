import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';

abstract class IDonationRepository {
  Future<Result<DonationResponse>> submitDonation(DonationRequest request);
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes();
}

class DonationRepository implements IDonationRepository {
  final ApiService _apiService;
  final StorageProvider _storageProvider;
  final FirebaseAuth _firebaseAuth;

  DonationRepository({required this._apiService, required this._storageProvider, required this._firebaseAuth});

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) async {
    try {
      SafeLog.event(AppLogEvent.donationSubmissionStarted);

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(AppStrings.userNotAuthenticated);
      }

      List<String> imageUrls = [];

      if (request.localImages != null && request.localImages!.isNotEmpty) {
        SafeLog.count(
          AppLogEvent.donationImageUploadStarted,
          request.localImages!.length,
        );

        final List<File> imageFiles = request.localImages!.map((xFile) => File(xFile.path)).toList();

        final uploadResult = await _uploadMultipleImages(imageFiles, user.uid);

        if (uploadResult.isSuccess) {
          imageUrls = uploadResult.value!;
        } else {
          SafeLog.event(
            AppLogEvent.donationImageUploadFailed,
            level: SafeLogLevel.warning,
          );
          return Result.failure(AppStrings.failedToUploadImages);
        }
        SafeLog.count(
          AppLogEvent.donationImageUploadSucceeded,
          imageUrls.length,
        );
      }

      final apiRequest = request.copyWith(
        productImages: imageUrls,
        localImages: null,
      );

      final response = await _apiService.post(
        ApiEndpoints.products,
        data: apiRequest.toJson(),
      );

      if (response.isSuccess) {
        final donationResponse = DonationResponse.fromJson(response.value);
        SafeLog.event(AppLogEvent.donationSubmissionSucceeded);
        return Result.success(donationResponse);
      } else {
        SafeLog.event(
          AppLogEvent.donationSubmissionFailed,
          level: SafeLogLevel.warning,
        );
        return Result.failure(response.error ?? AppStrings.failedToSubmitDonation);
      }
    } catch (_) {
      SafeLog.event(
        AppLogEvent.donationSubmissionFailed,
        level: SafeLogLevel.severe,
      );
      return Result.failure(AppStrings.unexpectedErrorOccurred);
    }
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() async {
    try {
      final result = await _apiService.get<dynamic>(ApiEndpoints.postageSizes);

      if (result.isSuccess && result.value != null) {
        final jsonList = _extractPostageSizeList(result.value);
        if (jsonList == null) {
          return Result.failure('Unexpected postage sizes response format');
        }
        final postageSizes = jsonList
            .whereType<Map>()
            .map((json) => PostageSizeInfo.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        postageSizes.sort((a, b) => a.size.index.compareTo(b.size.index));
        return Result.success(postageSizes);
      } else {
        return Result.failure(result.error ?? 'Failed to fetch postage sizes');
      }
    } catch (_) {
      return Result.failure('Failed to fetch postage sizes');
    }
  }

  List<dynamic>? _extractPostageSizeList(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      return data is List ? data : null;
    }

    return payload is List ? payload : null;
  }

  Future<Result<List<String>>> _uploadMultipleImages(List<File> imageFiles, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final List<Future<Result<String>>> uploadFutures = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final imageName = 'image_${timestamp}_$i.jpg';
        final imagePath = 'products/$userId/$imageName';

        uploadFutures.add(_storageProvider.uploadImage(imageFiles[i], imagePath));
      }

      final List<Result<String>> uploadResults = await Future.wait(uploadFutures);

      final List<String> downloadUrls = [];
      for (int i = 0; i < uploadResults.length; i++) {
        final result = uploadResults[i];
        if (result.isSuccess) {
          downloadUrls.add(result.value!);
        } else {
          return Result.failure(AppStrings.failedToUploadImages);
        }
      }

      return Result.success(downloadUrls);
    } catch (_) {
      return Result.failure(AppStrings.failedToUploadImages);
    }
  }
}

class MockDonationRepository implements IDonationRepository {
  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) async {
    SafeLog.event(AppLogEvent.donationSubmissionStarted);

    await Future.delayed(const Duration(seconds: 2));

    final mockData = Product(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      description: request.description,
      categoryId: request.categoryId,
      charityId: request.charityId,
      quality: request.quality,
      size: request.size,
      postageSizeId: request.postageSizeId,
      productImages: request.productImages ?? [],
      donation: request.donation,
      price: request.price,
      securityFee: 7.00,
      likes: request.likes,
      number: request.number,
      userId: 'mock_user_id',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final response = DonationResponse(
      success: true,
      message: AppStrings.donationSubmittedSuccessfully,
      data: mockData,
    );

    return Result.success(response);
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() {
    return Future.value(Result.success(_mockPostageSizes()));
  }
}

List<PostageSizeInfo> _mockPostageSizes() {
  return [
    PostageSizeInfo(
      id: 'small',
      type: 'inpost',
      size: PostageSize.small,
      description:
          'Small (up to 500g): max dimensions 30cm x 23cm x 10cm. Best for lightweight clothing, single books or small accessories.',
      weight: 500,
    ),
    PostageSizeInfo(
      id: 'medium',
      type: 'inpost',
      size: PostageSize.medium,
      description:
          'Medium (up to 1kg): max dimensions 40cm x 30cm x 15cm. Good for heavier tops, single jeans or standard shoe boxes.',
      weight: 1000,
    ),
    PostageSizeInfo(
      id: 'large',
      type: 'inpost',
      size: PostageSize.large,
      description:
          'Large (up to 2kg): max dimensions 60cm x 50cm x 50cm. Useful for coats, chunky boots or small bundles.',
      weight: 2000,
    ),
  ];
}
