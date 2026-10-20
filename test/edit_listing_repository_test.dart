import 'dart:io';
import 'dart:typed_data';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/services/firebase_storage.dart';
import 'package:cherry_mvp/core/services/network/api_endpoints.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_draft.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/edit_listing/image_upload_format.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'support/unexpected_api_service.dart';

class _Api implements ApiService {
  _Api(this.events);
  final List<String> events;
  final List<Map<String, dynamic>> writes = [];
  String? endpoint;
  Result<dynamic> response = Result.success({
    'success': true,
    'data': {'id': 'listing-1'},
  });
  Object? exception;

  @override
  Future<Result<T>> put<T>(String endpoint, {dynamic data}) async {
    events.add('put');
    this.endpoint = endpoint;
    writes.add(Map<String, dynamic>.from(data as Map));
    if (exception != null) throw exception!;
    return response.isSuccess ? Result.success(response.value as T) : Result.failure(response.error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected API operation: ${invocation.memberName}');
}

class _Products extends ProductRepository {
  _Products(this.events) : super(const UnexpectedApiService());
  final List<String> events;
  final List<Result<Product>> responses = [];
  int calls = 0;
  Future<Result<Product>> Function()? onFetch;

  @override
  Future<Result<Product>> fetchProduct(String id) async {
    events.add('get');
    calls++;
    if (onFetch != null) return onFetch!();
    return responses.removeAt(0);
  }
}

class _Storage implements StorageProvider {
  _Storage(this.events);
  final List<String> events;
  final List<String> paths = [];
  final List<String> files = [];
  Future<Result<String>> Function()? onUpload;

  @override
  Future<Result<String>> uploadImage(File imageFile, String storagePath) async {
    events.add('upload');
    paths.add(storagePath);
    files.add(imageFile.path);
    return onUpload != null ? onUpload!() : Result.success('https://example.com/new-photo.jpg');
  }

  // Any direct Firebase access or destructive media operation fails the test.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected storage operation: ${invocation.memberName}');
}

class _Harness {
  _Harness({bool? enabled}) {
    api = _Api(events);
    products = _Products(events);
    storage = _Storage(events);
    repository = EditListingRepository(
      apiService: api,
      productRepository: products,
      storageProvider: storage,
      currentUserId: () => uid,
    );
  }
  String? uid = 'seller-1';
  final List<String> events = [];
  late final _Api api;
  late final _Products products;
  late final _Storage storage;
  late final EditListingRepository repository;
}

Product _product([Map<String, dynamic> changes = const {}]) => Product.fromJson({
  'id': 'listing-1',
  'userId': 'seller-1',
  'name': 'Blue cotton shirt',
  'description': 'A long-sleeved shirt in good condition.',
  'quality': 'GOOD',
  'product_images': ['https://example.com/original.jpg'],
  'donation': 10,
  'price': 10,
  'securityFee': 1,
  'likes': 2,
  'number': 1,
  'size': 'M',
  'postageSize': 'small',
  'categoryId': 'shirts',
  'charityId': 'charity-1',
  'status': 'active',
  ...changes,
});

EditListingDraft _changed(Product original) =>
    EditListingDraft.fromProduct(original).copyWith(name: 'Green cotton shirt');

// Leading bytes of real files. The repository inspects these, not file names.
const _pngBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0];
const _jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0];
const _webpBytes = [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50];
const _heicBytes = [0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63];

Directory? _photoDir;

/// Writes a real file, because the repository reads each new photo's header
/// and size before uploading anything.
XFile _photoFile(String name, List<int> bytes) {
  final directory = _photoDir ??= Directory.systemTemp.createTempSync('listing_photos_');
  final file = File('${directory.path}/$name')..writeAsBytesSync(bytes);
  return XFile(file.path);
}

EditListingDraft _withNewPhoto(Product original) => _changed(original).copyWith(
  photos: [
    ListingPhoto.remote(original.productImages.first),
    ListingPhoto.local(_photoFile('new-photo.png', _pngBytes)),
  ],
);

void main() {
  tearDownAll(() => _photoDir?.deleteSync(recursive: true));

  group('EditListingRepository access checks', () {
    test('backend eligibility gates prevent reads, uploads and writes', () async {
      final harness = _Harness();
      final original = _product({'status': 'sold', 'number': 0});
      expect(harness.repository.canEdit(original), isFalse);
      final result = await harness.repository.save(original, _withNewPhoto(original));
      expect(result.isSuccess, isFalse);
      expect(result.writeAttempted, isFalse);
      expect(harness.events, isEmpty);
    });

    final unavailable = <String, Map<String, dynamic>>{
      'unknown status': {'status': 'reserved'},
      'missing status': {'status': null},
      'sold status': {'status': 'sold'},
      'no stock': {'number': 0},
      'other owner': {'userId': 'another-seller'},
      'missing owner': {'userId': null},
    };
    for (final entry in unavailable.entries) {
      test('${entry.key} prevents upload and PUT', () async {
        final harness = _Harness();
        final original = _product(entry.value);
        expect(harness.repository.canEdit(original), isFalse);
        final result = await harness.repository.save(original, _withNewPhoto(original));
        expect(result.isSuccess, isFalse);
        expect(harness.events, isEmpty);
      });
    }

    test('signed-out user cannot load or save', () async {
      final harness = _Harness(enabled: true)..uid = null;
      final original = _product();
      expect((await harness.repository.load(original.id)).isSuccess, isFalse);
      expect((await harness.repository.save(original, _changed(original))).isSuccess, isFalse);
      expect(harness.events, isEmpty);
    });

    test('supports owned active and unlisted listings without version metadata', () {
      final harness = _Harness();
      for (final status in ['active', 'unlisted']) {
        expect(harness.repository.canEdit(_product({'status': status})), isTrue);
      }
    });

    test('account change during initial load rejects returned listing', () async {
      final harness = _Harness(enabled: true);
      harness.products.onFetch = () async {
        harness.uid = 'another-seller';
        return Result.success(_product());
      };
      expect((await harness.repository.load('listing-1')).isSuccess, isFalse);
      expect(harness.events, ['get']);
    });
  });

  group('EditListingRepository saves', () {
    test('sends only changed descriptive fields', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      final saved = _product({'name': 'Green cotton shirt'});
      harness.products.responses.addAll([Result.success(original), Result.success(saved)]);
      final result = await harness.repository.save(original, _changed(original));
      expect(result.product, same(saved));
      expect(result.writeAttempted, isTrue);
      expect(harness.api.endpoint, ApiEndpoints.productById(original.id));
      expect(harness.api.writes, [
        {'name': 'Green cotton shirt'},
      ]);
      expect(harness.events, ['get', 'put', 'get']);
    });

    test('changed allowlist excludes price, charity, postage, stock and ownership', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      final draft = _changed(original).copyWith(
        description: '',
        quality: 'LIKE NEW',
        size: 'L',
        categoryId: 'tops',
        photos: [ListingPhoto.local(_photoFile('replacement.jpg', _jpegBytes))],
      );
      harness.products.responses.addAll([
        Result.success(original),
        Result.success(_product()),
      ]);
      final result = await harness.repository.save(original, draft);
      expect(result.isSuccess, isTrue);
      expect(harness.api.writes.single, {
        'name': 'Green cotton shirt',
        'description': '',
        'quality': 'LIKE NEW',
        'size': 'L',
        'categoryId': 'tops',
        'product_images': ['https://example.com/new-photo.jpg'],
      });
    });

    for (final changes in [
      {'name': 'Different shirt'},
      {'price': 20},
      {'charityId': 'charity-2'},
      {'number': 2},
    ]) {
      test('fresh listing conflict $changes prevents uploads and PUT', () async {
        final harness = _Harness(enabled: true);
        final original = _product();
        harness.products.responses.add(Result.success(_product(changes)));
        final result = await harness.repository.save(original, _withNewPhoto(original));
        expect(result.isSuccess, isFalse);
        expect(result.requiresReload, isTrue);
        expect(result.writeAttempted, isFalse);
        expect(harness.events, ['get']);
      });
    }

    test('fresh sold listing prevents upload and PUT', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      harness.products.responses.add(Result.success(_product({'status': 'sold', 'number': 0})));
      expect((await harness.repository.save(original, _withNewPhoto(original))).isSuccess, isFalse);
      expect(harness.events, ['get']);
    });

    test('upload completes before PUT and retains existing photo URLs', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      harness.products.responses.addAll([
        Result.success(original),
        Result.success(_product()),
      ]);
      final result = await harness.repository.save(original, _withNewPhoto(original));
      expect(result.isSuccess, isTrue);
      expect(harness.events, ['get', 'upload', 'put', 'get']);
      expect(harness.api.writes.single['product_images'], [
        original.productImages.single,
        'https://example.com/new-photo.jpg',
      ]);
      expect(harness.storage.paths.single, matches(r'^products/seller-1/edit_[0-9a-f]{32}\.png$'));
      expect(harness.storage.files.single, endsWith('new-photo.png'));
    });

    test('upload failure leaves the original listing untouched', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      harness.products.responses.add(Result.success(original));
      harness.storage.onUpload = () async => Result.failure('Upload failed');
      final result = await harness.repository.save(original, _withNewPhoto(original));
      expect(result.isSuccess, isFalse);
      expect(result.writeAttempted, isFalse);
      expect(original.productImages, ['https://example.com/original.jpg']);
      expect(harness.events, ['get', 'upload']);
    });

    test('account change during upload prevents PUT', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      harness.products.responses.add(Result.success(original));
      harness.storage.onUpload = () async {
        harness.uid = 'another-seller';
        return Result.success('https://example.com/new-photo.jpg');
      };
      final result = await harness.repository.save(original, _withNewPhoto(original));
      expect(result.isSuccess, isFalse);
      expect(result.requiresReload, isTrue);
      expect(result.writeAttempted, isFalse);
      expect(harness.events, ['get', 'upload']);
    });

    final badResponses = <dynamic>[
      null,
      [],
      {'success': false},
      {'success': true, 'data': null},
      {
        'success': true,
        'data': {'id': 'different'},
      },
    ];
    for (var index = 0; index < badResponses.length; index++) {
      test('malformed write response $index requires reload without success', () async {
        final harness = _Harness(enabled: true);
        final original = _product();
        harness.products.responses.add(Result.success(original));
        harness.api.response = Result.success(badResponses[index]);
        final result = await harness.repository.save(original, _changed(original));
        expect(result.isSuccess, isFalse);
        expect(result.requiresReload, isTrue);
        expect(result.writeAttempted, isTrue);
        expect(harness.events, ['get', 'put']);
      });
    }

    for (final readback in [
      Result<Product>.failure('Readback failed'),
      Result.success(_product({'userId': 'another-seller'})),
    ]) {
      test('unconfirmed readback requires reload and never reports success', () async {
        final harness = _Harness(enabled: true);
        final original = _product();
        harness.products.responses.addAll([Result.success(original), readback]);
        final result = await harness.repository.save(original, _changed(original));
        expect(result.isSuccess, isFalse);
        expect(result.requiresReload, isTrue);
        expect(result.writeAttempted, isTrue);
        expect(harness.events, ['get', 'put', 'get']);
      });
    }

    test('transport failure after PUT requires reload before any retry', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      harness.products.responses.add(Result.success(original));
      harness.api.exception = StateError('Connection lost');
      final result = await harness.repository.save(original, _changed(original));
      expect(result.isSuccess, isFalse);
      expect(result.requiresReload, isTrue);
      expect(result.writeAttempted, isTrue);
      expect(harness.events, ['get', 'put']);
    });

    test('no-op and invalid drafts never load, upload or write', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      final drafts = [
        EditListingDraft.fromProduct(original),
        _changed(original).copyWith(name: 'x'),
        _changed(original).copyWith(photos: []),
        _changed(original).copyWith(photos: const [ListingPhoto.remote('https://other.com/injected.jpg')]),
      ];
      for (final draft in drafts) {
        expect((await harness.repository.save(original, draft)).isSuccess, isFalse);
      }
      expect(harness.events, isEmpty);
    });
  });

  group('EditListingRepository photos', () {
    Future<EditListingSaveResult> saveWith(_Harness harness, Product original, List<ListingPhoto> photos) {
      harness.products.responses.addAll([
        Result.success(original),
        Result.success(_product()),
      ]);
      return harness.repository.save(original, _changed(original).copyWith(photos: photos));
    }

    test('identifies the real format instead of trusting the file name', () async {
      final harness = _Harness(enabled: true);
      final result = await saveWith(harness, _product(), [
        ListingPhoto.local(_photoFile('actually-png.jpg', _pngBytes)),
        ListingPhoto.local(_photoFile('actually-jpeg.png', _jpegBytes)),
        ListingPhoto.local(_photoFile('actually-webp.jpeg', _webpBytes)),
      ]);
      expect(result.isSuccess, isTrue);
      expect(harness.storage.paths[0], endsWith('.png'));
      expect(harness.storage.paths[1], endsWith('.jpg'));
      expect(harness.storage.paths[2], endsWith('.webp'));
    });

    test('keeps photo order when new and existing photos are mixed', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      var uploads = 0;
      harness.storage.onUpload = () async => Result.success('https://example.com/new-${++uploads}.jpg');
      final result = await saveWith(harness, original, [
        ListingPhoto.local(_photoFile('first.png', _pngBytes)),
        ListingPhoto.remote(original.productImages.first),
        ListingPhoto.local(_photoFile('last.jpg', _jpegBytes)),
      ]);
      expect(result.isSuccess, isTrue);
      expect(harness.api.writes.single['product_images'], [
        'https://example.com/new-1.jpg',
        original.productImages.first,
        'https://example.com/new-2.jpg',
      ]);
      expect(harness.storage.paths, [matches(r'\.png$'), matches(r'\.jpg$')]);
    });

    test('HEIC content is refused before any upload or write, whatever its name', () async {
      final harness = _Harness(enabled: true);
      final result = await saveWith(harness, _product(), [
        ListingPhoto.local(_photoFile('IMG_0001.jpg', _heicBytes)),
      ]);
      expect(result.isSuccess, isFalse);
      expect(result.writeAttempted, isFalse);
      expect(result.error, contains('JPEG, PNG or WebP'));
      expect(harness.events, ['get']);
    });

    test('one unusable photo stops every upload, so none are orphaned', () async {
      final harness = _Harness(enabled: true);
      final result = await saveWith(harness, _product(), [
        ListingPhoto.local(_photoFile('good.png', _pngBytes)),
        ListingPhoto.local(_photoFile('bad.heic', _heicBytes)),
      ]);
      expect(result.isSuccess, isFalse);
      expect(harness.storage.paths, isEmpty);
      expect(harness.events, ['get']);
    });

    test('a photo over 10 MB is refused before any upload', () async {
      final harness = _Harness(enabled: true);
      final bytes = Uint8List(maxListingPhotoBytes + 1)..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
      final result = await saveWith(harness, _product(), [ListingPhoto.local(_photoFile('huge.jpg', bytes))]);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('10 MB'));
      expect(harness.events, ['get']);
    });

    test('a photo of exactly 10 MB is accepted', () async {
      final harness = _Harness(enabled: true);
      final bytes = Uint8List(maxListingPhotoBytes)..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
      final result = await saveWith(harness, _product(), [ListingPhoto.local(_photoFile('limit.jpg', bytes))]);
      expect(result.isSuccess, isTrue);
    });

    test('an unreadable photo is refused before any upload', () async {
      final harness = _Harness(enabled: true);
      final missing = XFile('${Directory.systemTemp.path}/listing-photo-that-does-not-exist.jpg');
      final result = await saveWith(harness, _product(), [ListingPhoto.local(missing)]);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('could not be read'));
      expect(harness.events, ['get']);
    });

    test('more than ten photos is an invalid draft that never uploads', () async {
      final harness = _Harness(enabled: true);
      final original = _product();
      final many = [for (var i = 0; i < 11; i++) ListingPhoto.local(XFile('photo-$i.jpg'))];
      final tooMany = _changed(original).copyWith(photos: many);
      expect(tooMany.validate(original), 'Use no more than 10 photos');
      expect((await harness.repository.save(original, tooMany)).isSuccess, isFalse);
      expect(harness.events, isEmpty);
      expect(_changed(original).copyWith(photos: many.take(10).toList()).validate(original), isNull);
    });
  });
}
