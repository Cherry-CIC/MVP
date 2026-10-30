import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _User implements User {
  @override
  String get uid => 'donor';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  @override
  User get currentUser => _User();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage implements StorageProvider {
  final pending = <String, Completer<Result<String>>>{};
  final completed = <String>[];

  @override
  Future<Result<String>> uploadImage(File imageFile, String storagePath) {
    final completer = Completer<Result<String>>();
    pending[imageFile.path] = completer;
    return completer.future.then((result) {
      completed.add(imageFile.path);
      return result;
    });
  }

  Future<void> complete(String path, Result<String> result) async {
    pending[path]!.complete(result);
    await pending[path]!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ApiService {
  final requests = <Map<String, dynamic>>[];
  String? endpoint;

  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    this.endpoint = endpoint;
    final request = Map<String, dynamic>.from(data as Map);
    requests.add(request);
    return Result.success(
      {
            'success': true,
            'message': AppStrings.donationSubmittedSuccessfully,
            'data': {...request, 'id': 'listing', 'securityFee': 0},
          }
          as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DonationRequest _request() => DonationRequest(
  name: 'Cotton shirt',
  description: 'A pre-loved cotton shirt',
  categoryId: 'clothing',
  charityId: 'charity',
  quality: 'GOOD',
  size: 'Small',
  postageSizeId: 'small',
  donation: 12,
  price: 12,
  // The user has chosen the detail photo as the cover.
  localImages: [XFile('/photos/detail.jpg'), XFile('/photos/front.jpg'), XFile('/photos/back.jpg')],
);

void main() {
  test('submits the chosen photo order when uploads finish out of order', () async {
    final storage = _Storage();
    final api = _Api();
    final repository = DonationRepository(apiService: api, storageProvider: storage, firebaseAuth: _Auth());

    final submission = repository.submitDonation(_request());

    await storage.complete('/photos/back.jpg', Result.success('https://example.com/back.jpg'));
    await storage.complete('/photos/front.jpg', Result.success('https://example.com/front.jpg'));
    expect(api.requests, isEmpty);
    await storage.complete('/photos/detail.jpg', Result.success('https://example.com/detail.jpg'));
    final result = await submission;

    expect(storage.completed, ['/photos/back.jpg', '/photos/front.jpg', '/photos/detail.jpg']);
    expect(result.isSuccess, isTrue);
    expect(api.endpoint, ApiEndpoints.products);
    expect(api.requests, hasLength(1));
    const expectedOrder = [
      'https://example.com/detail.jpg',
      'https://example.com/front.jpg',
      'https://example.com/back.jpg',
    ];
    expect(api.requests.single['product_images'], expectedOrder);
    expect(api.requests.single, isNot(contains('localImages')));
    expect(result.value!.data.productImages, expectedOrder);
  });

  test('does not create a listing with a partial photo set after an upload fails', () async {
    final storage = _Storage();
    final api = _Api();
    final repository = DonationRepository(apiService: api, storageProvider: storage, firebaseAuth: _Auth());

    final submission = repository.submitDonation(_request());

    await storage.complete('/photos/back.jpg', Result.success('https://example.com/back.jpg'));
    await storage.complete('/photos/front.jpg', Result.failure('Upload failed'));
    await storage.complete('/photos/detail.jpg', Result.success('https://example.com/detail.jpg'));
    final result = await submission;

    expect(result.isSuccess, isFalse);
    expect(result.error, AppStrings.failedToUploadImages);
    expect(api.requests, isEmpty);
  });
}
