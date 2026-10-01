import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_draft.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _Repository implements IEditListingRepository {
  int loadCount = 0;
  int saveCount = 0;
  Future<Result<Product>> Function()? onLoad;
  Future<EditListingSaveResult> Function()? onSave;
  EditListingDraft? savedDraft;

  @override
  bool canEdit(Product product) => true;

  @override
  Future<Result<Product>> load(String productId) async {
    loadCount++;
    return onLoad != null ? onLoad!() : Result.success(_product());
  }

  @override
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft) async {
    saveCount++;
    savedDraft = draft;
    return onSave != null ? onSave!() : EditListingSaveResult.success(_product(name: draft.name, version: 8));
  }
}

Product _product({String name = 'Blue cotton shirt', int version = 7}) => Product(
  id: 'listing-1',
  userId: 'seller-1',
  name: name,
  description: 'A long-sleeved shirt.',
  quality: 'GOOD',
  productImages: const ['https://example.com/original.jpg'],
  donation: 10,
  price: 10,
  securityFee: 1,
  likes: 2,
  number: 1,
  size: 'M',
  postageSizeId: 'small',
  categoryId: 'shirts',
  charityId: 'charity-1',
  status: 'active',
  editVersion: version,
);

void main() {
  group('EditListingDraft', () {
    test('supports clearing description, trimming text and removing/reordering photos', () {
      final original = _product();
      final draft = EditListingDraft.fromProduct(original).copyWith(
        name: '  Green cotton shirt  ',
        description: '',
      );
      expect(draft.validate(original), isNull);
      expect(draft.changedFields(original, original.productImages), {
        'name': 'Green cotton shirt',
        'description': '',
      });
      expect(draft.hasChanges(original), isTrue);
    });

    test('validates API text limits and keeps at least one known or local photo', () {
      final original = _product();
      final draft = EditListingDraft.fromProduct(original);
      expect(draft.validate(original), isNull);
      expect(draft.copyWith(name: 'ab').validate(original), isNotNull);
      expect(draft.copyWith(name: 'a' * 101).validate(original), isNotNull);
      expect(draft.copyWith(description: 'a' * 501).validate(original), isNotNull);
      expect(draft.copyWith(photos: []).validate(original), isNotNull);
      expect(draft.copyWith(quality: '').validate(original), isNotNull);
      expect(draft.copyWith(size: '').validate(original), isNotNull);
      expect(draft.copyWith(categoryId: '').validate(original), isNotNull);
      expect(draft.copyWith(photos: [ListingPhoto.local(XFile('/tmp/new.jpg'))]).validate(original), isNull);
    });

    test('photo collection is immutable and input changes cannot alter it', () {
      final original = _product();
      final photos = [ListingPhoto.remote(original.productImages.single)];
      final draft = EditListingDraft.fromProduct(original).copyWith(photos: photos);
      photos.clear();
      expect(draft.photos, hasLength(1));
      expect(() => draft.photos.clear(), throwsUnsupportedError);
    });
  });

  group('EditListingViewModel', () {
    late _Repository repository;
    late EditListingViewModel viewModel;
    setUp(() {
      repository = _Repository();
      viewModel = EditListingViewModel(repository: repository, productId: 'listing-1');
    });
    tearDown(() => viewModel.dispose());

    test('loads a pristine form then tracks and clears unsaved changes', () async {
      expect(viewModel.canSave, isFalse);
      await viewModel.load();
      expect(viewModel.formVersion, 1);
      expect(viewModel.isDirty, isFalse);
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      expect(viewModel.isDirty, isTrue);
      expect(viewModel.canSave, isTrue);
      final saved = await viewModel.save();
      expect(saved!.name, 'Green cotton shirt');
      expect(viewModel.original, same(saved));
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.canSave, isFalse);
      expect(viewModel.writeAttempted, isTrue);
      expect(viewModel.error, isNull);
    });

    test('concurrent save, reload and changes are blocked during a pending save', () async {
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      final pending = Completer<EditListingSaveResult>();
      repository.onSave = () => pending.future;
      final firstSave = viewModel.save();
      expect(viewModel.isSaving, isTrue);
      expect(await viewModel.save(), isNull);
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Unexpected replacement'));
      expect(repository.saveCount, 1);
      expect(repository.loadCount, 1);
      expect(viewModel.draft!.name, 'Green cotton shirt');
      pending.complete(EditListingSaveResult.success(_product(name: 'Green cotton shirt', version: 8)));
      expect(await firstSave, isNotNull);
      expect(viewModel.isSaving, isFalse);
    });

    test('duplicate initial loads share the loading state without a second request', () async {
      final pending = Completer<Result<Product>>();
      repository.onLoad = () => pending.future;
      final firstLoad = viewModel.load();
      await viewModel.load();
      expect(viewModel.isLoading, isTrue);
      expect(repository.loadCount, 1);
      pending.complete(Result.success(_product()));
      await firstLoad;
      expect(viewModel.isLoading, isFalse);
    });

    test('validation error preserves draft without a repository save', () async {
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'x'));
      expect(await viewModel.save(), isNull);
      expect(repository.saveCount, 0);
      expect(viewModel.error, isNotNull);
      expect(viewModel.draft!.name, 'x');
      viewModel.update(viewModel.draft!.copyWith(name: 'Corrected title'));
      expect(viewModel.error, isNull);
    });

    test('upload failure retains unsaved work and allows a deliberate retry', () async {
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      repository.onSave = () async => const EditListingSaveResult.failure('Photo upload failed');
      expect(await viewModel.save(), isNull);
      expect(viewModel.error, 'Photo upload failed');
      expect(viewModel.isDirty, isTrue);
      expect(viewModel.canSave, isTrue);
      expect(viewModel.requiresReload, isFalse);
      expect(viewModel.writeAttempted, isFalse);
    });

    test('uncertain write freezes draft until a successful canonical reload', () async {
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      repository.onSave = () async => const EditListingSaveResult.failure(
        'Could not confirm save',
        requiresReload: true,
        writeAttempted: true,
      );
      expect(await viewModel.save(), isNull);
      expect(viewModel.requiresReload, isTrue);
      expect(viewModel.canSave, isFalse);
      expect(viewModel.writeAttempted, isTrue);
      viewModel.update(viewModel.draft!.copyWith(name: 'Blocked update'));
      expect(viewModel.draft!.name, 'Green cotton shirt');
      expect(await viewModel.save(), isNull);
      expect(repository.saveCount, 1);

      repository.onLoad = () async => Result.failure('Offline');
      await viewModel.load();
      expect(viewModel.requiresReload, isTrue);
      expect(viewModel.draft!.name, 'Green cotton shirt');
      expect(viewModel.error, 'Offline');

      repository.onLoad = () async => Result.success(_product(name: 'Server title', version: 8));
      await viewModel.load();
      expect(viewModel.requiresReload, isFalse);
      expect(viewModel.draft!.name, 'Server title');
      expect(viewModel.isDirty, isFalse);
      expect(viewModel.formVersion, 2);
      expect(viewModel.writeAttempted, isTrue);
    });

    test('unexpected save exception is treated as an uncertain write', () async {
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      repository.onSave = () async => throw StateError('Lost connection');
      expect(await viewModel.save(), isNull);
      expect(viewModel.requiresReload, isTrue);
      expect(viewModel.writeAttempted, isTrue);
      expect(viewModel.canSave, isFalse);
      expect(viewModel.isSaving, isFalse);
    });

    test('initial load failure leaves no editable form', () async {
      repository.onLoad = () async => Result.failure('Listing unavailable');
      await viewModel.load();
      expect(viewModel.error, 'Listing unavailable');
      expect(viewModel.original, isNull);
      expect(viewModel.draft, isNull);
      expect(viewModel.canSave, isFalse);
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('EditListingViewModel disposal', () {
    test('late load result does not populate or notify a disposed model', () async {
      final repository = _Repository();
      final pending = Completer<Result<Product>>();
      repository.onLoad = () => pending.future;
      final viewModel = EditListingViewModel(repository: repository, productId: 'listing-1');
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      final load = viewModel.load();
      viewModel.dispose();
      final countAtDisposal = notifications;
      pending.complete(Result.success(_product()));
      await load;
      expect(notifications, countAtDisposal);
      expect(viewModel.original, isNull);
    });

    test('pending save completion never notifies disposed listeners', () async {
      final repository = _Repository();
      final viewModel = EditListingViewModel(repository: repository, productId: 'listing-1');
      await viewModel.load();
      viewModel.update(viewModel.draft!.copyWith(name: 'Green cotton shirt'));
      final pending = Completer<EditListingSaveResult>();
      repository.onSave = () => pending.future;
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      final save = viewModel.save();
      viewModel.dispose();
      final countAtDisposal = notifications;
      pending.complete(EditListingSaveResult.success(_product(name: 'Green cotton shirt', version: 8)));
      await save;
      expect(notifications, countAtDisposal);
    });
  });
}
