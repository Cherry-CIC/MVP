import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _Snapshot implements TaskSnapshot {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Upload implements UploadTask {
  @override
  Future<R> then<R>(FutureOr<R> Function(TaskSnapshot) onValue, {Function? onError}) =>
      Future<TaskSnapshot>.value(_Snapshot()).then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reference implements Reference {
  SettableMetadata? metadata;
  Uint8List? bytes;

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    bytes = data;
    this.metadata = metadata;
    return _Upload();
  }

  @override
  Future<String> getDownloadURL() async => 'https://example.com/uploaded.png';

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected storage operation');
}

class _Storage implements FirebaseStorage {
  final reference = _Reference();
  final paths = <String?>[];

  @override
  Reference ref([String? path]) {
    paths.add(path);
    return reference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected Firebase operation');
}

class _User implements User {
  @override
  String get uid => 'seller-1';
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected user operation');
}

class _Auth implements FirebaseAuth {
  @override
  User? currentUser = _User();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected auth operation');
}

class _ListingStorage implements StorageProvider {
  final uploads = <String>[];
  void Function()? onUpload;
  Result<String> result = Result.success('https://example.com/photo.png');

  @override
  Future<Result<String>> uploadListingImage(File file, String ownerUid) async {
    uploads.add('protected/$ownerUid');
    onUpload?.call();
    return result;
  }

  @override
  Future<Result<String>> uploadImage(File file, String path) async {
    uploads.add(path);
    onUpload?.call();
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected upload operation');
}

class _Api implements ApiService {
  final payloads = <dynamic>[];
  @override
  Future<Result<T>> post<T>(String endpoint, {dynamic data}) async {
    payloads.add(data);
    return Result.failure('Stop after capturing the request');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected API operation');
}

DonationRequest _donation([int photos = 1]) => DonationRequest(
  name: 'Blue shirt',
  description: 'Cotton shirt',
  categoryId: 'shirts',
  charityId: 'charity-1',
  quality: 'GOOD',
  size: 'Small',
  postageSizeId: 'small',
  donation: 10,
  price: 10,
  localImages: List.generate(photos, (index) => XFile('/tmp/photo-$index.png')),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  test('uploads content-based PNG with unique owned paths and policy metadata', () async {
    final directory = await Directory.systemTemp.createTemp('listing-image-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/mislabelled.heic').writeAsBytes(png);
    final storage = _Storage();
    final provider = StorageProvider(firebaseStorage: storage);
    expect((await provider.uploadListingImage(file, 'seller-1')).isSuccess, isTrue);
    expect((await provider.uploadListingImage(file, 'seller-1')).isSuccess, isTrue);
    expect(storage.paths.toSet(), hasLength(2));
    expect(
      storage.paths.every((path) => RegExp(r'^listing-media-v1/seller-1/[0-9a-f]{32}\.png$').hasMatch(path!)),
      isTrue,
    );
    expect(storage.reference.metadata?.contentType, 'image/png');
    expect(storage.reference.metadata?.customMetadata, {'ownerUid': 'seller-1', 'mediaPolicy': 'listing-v1'});
    expect(storage.reference.bytes, png);
  });

  test('rejects empty or oversized photos before decoding', () async {
    for (final bytes in [Uint8List(0), Uint8List(StorageProvider.maxPhotoBytes + 1)]) {
      await expectLater(StorageProvider.prepareListingImage(bytes), throwsFormatException);
    }
  });

  test('invalid image bytes cannot be uploaded', () async {
    final directory = await Directory.systemTemp.createTemp('listing-image-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/broken.jpg').writeAsString('not a photo');
    final storage = _Storage();
    final result = await StorageProvider(firebaseStorage: storage).uploadListingImage(file, 'seller-1');
    expect(result.isSuccess, isFalse);
    expect(storage.paths, isEmpty);
  });

  test('new listings use protected uploads only in an enabled build', () async {
    final api = _Api();
    final storage = _ListingStorage();
    final repository = DonationRepository(apiService: api, storageProvider: storage, firebaseAuth: _Auth());
    await repository.submitDonation(_donation());
    if (FeatureFlags.enableListingEdit) {
      expect(storage.uploads, ['protected/seller-1']);
    } else {
      expect(storage.uploads.single, matches(r'^products/seller-1/image_[0-9]+_0\.jpg$'));
    }
    expect(api.payloads.single['product_images'], ['https://example.com/photo.png']);
  });

  test('failed uploads and account changes prevent listing creation', () async {
    for (final changeAccount in [false, true]) {
      final api = _Api();
      final storage = _ListingStorage();
      final auth = _Auth();
      if (changeAccount) {
        storage.onUpload = () => auth.currentUser = null;
      } else {
        storage.result = Result.failure('Choose a smaller photo');
      }
      final repository = DonationRepository(apiService: api, storageProvider: storage, firebaseAuth: auth);
      expect((await repository.submitDonation(_donation())).isSuccess, isFalse);
      expect(api.payloads, isEmpty);
    }
  });

  test('enabled creation requires between 1 and 10 photos', () async {
    if (!FeatureFlags.enableListingEdit) return;
    for (final count in [0, 11]) {
      final api = _Api();
      final storage = _ListingStorage();
      final repository = DonationRepository(apiService: api, storageProvider: storage, firebaseAuth: _Auth());
      expect((await repository.submitDonation(_donation(count))).isSuccess, isFalse);
      expect(api.payloads, isEmpty);
      expect(storage.uploads, isEmpty);
    }
  });
}
