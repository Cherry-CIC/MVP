import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/services.dart';
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
  final _log = Logger('DonationRepository');

  DonationRepository({
    required ApiService apiService,
    required StorageProvider storageProvider,
    required FirebaseAuth firebaseAuth,
  }) : _apiService = apiService,
       _storageProvider = storageProvider,
       _firebaseAuth = firebaseAuth;

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) async {
    try {
      _log.info('Starting donation submission process');

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Result.failure(AppStrings.userNotAuthenticated);
      }

      List<String> imageUrls = [];

      if (request.localImages != null && request.localImages!.isNotEmpty) {
        _log.info('Uploading ${request.localImages!.length} images to Firebase Storage');

        final List<File> imageFiles = request.localImages!.map((xFile) => File(xFile.path)).toList();

        final uploadResult = await _uploadMultipleImages(imageFiles, user.uid);

        if (uploadResult.isSuccess) {
          imageUrls = uploadResult.value!;
        } else {
          _log.warning('Image upload failed: ${uploadResult.error}');
          return Result.failure('${AppStrings.failedToUploadImages}: ${uploadResult.error}');
        }
        _log.info('Successfully uploaded ${imageUrls.length} images');
      }

      final apiRequest = request.copyWith(
        productImages: imageUrls,
        localImages: null,
      );

      _log.info('Submitting donation to API: ${apiRequest.toJson()}');

      final response = await _apiService.post(
        ApiEndpoints.products,
        data: apiRequest.toJson(),
      );

      if (response.isSuccess) {
        final donationResponse = DonationResponse.fromJson(response.value);
        _log.info('Donation submitted successfully with ID: ${donationResponse.id}');
        return Result.success(donationResponse);
      } else {
        _log.warning('API submission failed: ${response.error}');
        return Result.failure(response.error ?? AppStrings.failedToSubmitDonation);
      }
    } catch (e) {
      _log.severe('Exception during donation submission: $e');
      return Result.failure('${AppStrings.unexpectedErrorOccurred}: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() async {
    try {
      // TODO implement endpoint
      // final result = await _apiService.get(ApiEndpoints.postageSizes);

      final result = Result<dynamic>.success({
        "data": [
          {
            "id": "rcjK7AppkzE00YyyozcT",
            "type": "inpost",
            "size": "small",
            "description":
                "Small (Up to 500g): Max dimensions (30cm x 23cm x 10cm). Best for lightweight clothing, single books, or small accessories.",
          },
          {
            "id": "rcjK7AppkzE00YyyozcS",
            "type": "inpost",
            "size": "medium",
            "description":
                "Medium (Up to 1kg): Max dimensions (40cm x 30cm x 15cm). Suitable for heavier tops, single jeans, or standard shoe boxes.",
          },
          {
            "id": "rcjK7AppkzE00YyyozcU",
            "type": "inpost",
            "size": "large",
            "description":
                "Large (Up to 2kg): Max dimensions (60cm x 50cm x 50cm). Perfect for thick coats, chunky boots, or bundles of items.",
          },
        ],
      });

      if (result.isSuccess && result.value != null) {
        final data = result.value;
        final List<dynamic> jsonList = data['data'] ?? data;
        final postageSizes = jsonList.map((json) => PostageSizeInfo.fromJson(json)).toList();
        return Result.success(postageSizes);
      } else {
        return Result.failure(result.error ?? 'Failed to fetch postage sizes');
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
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
          return Result.failure('Failed to upload image ${i + 1}: ${result.error}');
        }
      }

      return Result.success(downloadUrls);
    } catch (e) {
      return Result.failure('Image upload error: ${e.toString()}');
    }
  }
}

class MockDonationRepository implements IDonationRepository {
  final _log = Logger('MockDonationRepository');

  @override
  Future<Result<DonationResponse>> submitDonation(DonationRequest request) async {
    _log.info('Mock: Submitting donation: ${request.toJson()}');

    await Future.delayed(const Duration(seconds: 2));

    final mockData = Product(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      name: request.name,
      description: request.description,
      categoryId: request.categoryId,
      charityId: request.charityId,
      quality: request.quality,
      size: request.size,
      postageSize: request.postageSize,
      productImages: request.productImages ?? [],
      donation: request.donation,
      price: request.price,
      likes: request.likes,
      number: request.number,
      userId: 'mock_user_id',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final response = DonationResponse(
      success: true,
      message: AppStrings.donationSubmittedSuccessfully,
      productData: mockData,
    );

    return Result.success(response);
  }

  @override
  Future<Result<List<PostageSizeInfo>>> fetchPostageSizes() {
    // TODO: implement fetchPostageSizes
    throw UnimplementedError();
  }
}
