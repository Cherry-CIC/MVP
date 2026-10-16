import 'dart:async';

import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_draft.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_page.dart';
import 'package:cherry_mvp/features/products/edit_listing/edit_listing_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EditRepository implements IEditListingRepository {
  _EditRepository({Product? product}) : product = product ?? _product();

  final Product product;
  final loadedIds = <String>[];
  final savedDrafts = <EditListingDraft>[];
  final savedOriginals = <Product>[];
  final routeResults = <EditListingResult?>[];
  Future<Result<Product>>? loadResponse;
  Future<EditListingSaveResult>? saveResponse;

  @override
  bool canEdit(Product product) => product.userId == 'owner';

  @override
  Future<Result<Product>> load(String productId) async {
    loadedIds.add(productId);
    return loadResponse ?? Result.success(product);
  }

  @override
  Future<EditListingSaveResult> save(Product original, EditListingDraft draft) async {
    savedOriginals.add(original);
    savedDrafts.add(draft);
    return saveResponse ?? EditListingSaveResult.success(_product(name: 'Canonical server title', version: 3));
  }
}

Future<void> _open(WidgetTester tester, _EditRepository repository, {double textScale = 1}) async {
  await tester.pumpWidget(
    Provider<IEditListingRepository>.value(
      value: repository,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<EditListingResult>(
                  MaterialPageRoute(builder: (_) => const EditListingPage(productId: 'listing')),
                );
                repository.routeResults.add(result);
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Finder _field(String title) => find.descendant(
  of: find.byWidgetPredicate((widget) => widget is DonationFormField && widget.title == title),
  matching: find.byType(TextFormField),
);

String _fieldText(WidgetTester tester, String title) => tester
    .widget<EditableText>(find.descendant(of: _field(title), matching: find.byType(EditableText)))
    .controller
    .text;

Finder get _saveButton => find.widgetWithText(FilledButton, 'Save changes');

Future<void> _save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(_saveButton);
  await tester.pumpAndSettle();
  await tester.tap(_saveButton);
  await tester.pump();
}

void main() {
  group('EditListingPage', () {
    testWidgets('shows loading, then prefills server details and disables an unchanged save', (tester) async {
      final response = Completer<Result<Product>>();
      final repository = _EditRepository()..loadResponse = response.future;
      await _open(tester, repository);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(DonationFormField), findsNothing);

      response.complete(Result.success(repository.product));
      await tester.pumpAndSettle();
      expect(repository.loadedIds, ['listing']);
      expect(_fieldText(tester, 'Title'), 'Original wool coat');
      expect(_fieldText(tester, 'Description'), 'A warm wool coat with two pockets.');
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
      expect(find.text('Price, charity, postage and quantity cannot be changed here.'), findsOneWidget);
    });

    testWidgets('saves edited title and description and returns the canonical server product', (tester) async {
      final canonical = _product(
        name: 'Canonical server title',
        description: 'Canonical server description',
        version: 3,
      );
      final repository = _EditRepository()..saveResponse = Future.value(EditListingSaveResult.success(canonical));
      await _open(tester, repository);
      await tester.enterText(_field('Title'), 'Edited wool coat');
      await tester.enterText(_field('Description'), 'New details about the wool coat.');
      await _save(tester);
      await tester.pumpAndSettle();

      expect(repository.savedDrafts.single.name, 'Edited wool coat');
      expect(repository.savedDrafts.single.description, 'New details about the wool coat.');
      expect(repository.savedOriginals.single, same(repository.product));
      expect(repository.routeResults.single?.product, same(canonical));
      expect(find.text('Open editor'), findsOneWidget);
      expect(find.text('Discard your changes?'), findsNothing);
    });

    for (final failure in ['This listing cannot be edited at the moment', 'Could not load this listing']) {
      testWidgets('shows retry without an editable form when loading fails: $failure', (tester) async {
        final repository = _EditRepository()..loadResponse = Future.value(Result.failure(failure));
        await _open(tester, repository);
        expect(find.text(failure), findsOneWidget);
        expect(find.byType(DonationFormField), findsNothing);
        expect(_saveButton, findsNothing);

        repository.loadResponse = Future.value(Result.success(repository.product));
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(repository.loadedIds, ['listing', 'listing']);
        expect(_fieldText(tester, 'Title'), repository.product.name);
        expect(repository.savedDrafts, isEmpty);
      });
    }

    testWidgets('invalid title and overlong description block repository writes', (tester) async {
      final repository = _EditRepository();
      await _open(tester, repository);
      await tester.enterText(_field('Title'), 'ab');
      await _save(tester);
      expect(find.text('Use at least 3 characters for the title'), findsOneWidget);
      expect(repository.savedDrafts, isEmpty);

      await tester.ensureVisible(_field('Title'));
      await tester.enterText(_field('Title'), 'Valid coat title');
      await tester.enterText(_field('Description'), List.filled(501, 'a').join());
      await _save(tester);
      expect(find.text('Use no more than 500 characters for the description'), findsOneWidget);
      expect(repository.savedDrafts, isEmpty);
    });

    testWidgets('optional description can be cleared', (tester) async {
      final repository = _EditRepository();
      await _open(tester, repository);
      await tester.enterText(_field('Description'), '');
      await _save(tester);
      await tester.pumpAndSettle();
      expect(repository.savedDrafts.single.description, isEmpty);
      expect(repository.routeResults.single?.product, isNotNull);
    });

    testWidgets('back asks before discarding edits and keep editing retains the draft', (tester) async {
      final repository = _EditRepository();
      await _open(tester, repository);
      await tester.enterText(_field('Title'), 'Unsaved coat title');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'Title'), 'Unsaved coat title');
      expect(repository.routeResults, isEmpty);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(repository.routeResults, [null]);
      expect(repository.savedDrafts, isEmpty);
      expect(find.text('Open editor'), findsOneWidget);
    });

    testWidgets('uncertain save disables resubmission until the listing is reloaded', (tester) async {
      const failure = 'We could not confirm the save. Reload the listing to check its current details.';
      final repository = _EditRepository()
        ..saveResponse = Future.value(
          const EditListingSaveResult.failure(
            failure,
            requiresReload: true,
            writeAttempted: true,
          ),
        );
      await _open(tester, repository);
      await tester.enterText(_field('Title'), 'Changed coat title');
      await _save(tester);
      await tester.pumpAndSettle();
      expect(find.text(failure), findsOneWidget);
      expect(repository.savedDrafts, hasLength(1));
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);

      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Reload listing'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reload listing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Reload listing'));
      await tester.pumpAndSettle();
      expect(repository.loadedIds, ['listing', 'listing']);
      expect(_fieldText(tester, 'Title'), 'Original wool coat');
      expect(find.text(failure), findsNothing);

      await tester.enterText(_field('Title'), 'Another valid title');
      await tester.pump();
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);
      expect(repository.savedDrafts, hasLength(1));
    });

    testWidgets('leaving an uncertain save returns an invalidation result without claiming success', (tester) async {
      final repository = _EditRepository()
        ..saveResponse = Future.value(
          const EditListingSaveResult.failure(
            'Reload the listing to check its details.',
            requiresReload: true,
            writeAttempted: true,
          ),
        );
      await _open(tester, repository);
      await tester.enterText(_field('Title'), 'Changed coat title');
      await _save(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(repository.routeResults.single, isA<EditListingResult>());
      expect(repository.routeResults.single?.product, isNull);
    });

    testWidgets('removing the final photo prevents save', (tester) async {
      final repository = _EditRepository();
      await _open(tester, repository);
      await tester.tap(find.byTooltip('Remove photo 1'));
      await _save(tester);
      expect(find.text('Keep at least one photo'), findsOneWidget);
      expect(repository.savedDrafts, isEmpty);
      expect(repository.routeResults, isEmpty);
    });

    testWidgets('changing the main photo preserves URLs and their chosen order', (tester) async {
      final repository = _EditRepository(product: _product(images: const [_photoOne, _photoTwo]));
      await _open(tester, repository);
      await tester.tap(find.byTooltip('Make photo 2 the main photo'));
      await _save(tester);
      await tester.pumpAndSettle();
      expect(repository.savedDrafts.single.photos.map((photo) => photo.remoteUrl), [_photoTwo, _photoOne]);
    });

    testWidgets('restoring the original main photo makes the draft unchanged again', (tester) async {
      final repository = _EditRepository(product: _product(images: const [_photoOne, _photoTwo]));
      await _open(tester, repository);
      await tester.tap(find.byTooltip('Make photo 2 the main photo'));
      await tester.pump();
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Make photo 2 the main photo'));
      await tester.pump();
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
      expect(repository.savedDrafts, isEmpty);
    });

    testWidgets('fits a 320px viewport with large text while editing and saving', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saving = Completer<EditListingSaveResult>();
      final repository = _EditRepository(product: _product(images: const [_photoOne, _photoTwo]))
        ..saveResponse = saving.future;
      await _open(tester, repository, textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(_field('Title'));
      await tester.enterText(_field('Title'), 'Changed coat title');
      await _save(tester);
      expect(find.text('Saving changes…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      saving.complete(EditListingSaveResult.success(_product(version: 3)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(repository.routeResults.single?.product, isNotNull);
    });
  });
}

const _photoOne = 'https://example.com/listing-one.jpg';
const _photoTwo = 'https://example.com/listing-two.jpg';

Product _product({
  String name = 'Original wool coat',
  String description = 'A warm wool coat with two pockets.',
  List<String> images = const [_photoOne],
  int version = 2,
}) => Product(
  id: 'listing',
  userId: 'owner',
  name: name,
  description: description,
  quality: 'GOOD',
  productImages: images,
  donation: 12,
  price: 12,
  securityFee: 1,
  likes: 0,
  number: 1,
  size: 'Medium',
  postageSizeId: 'small',
  categoryId: 'category',
  charityId: 'charity',
  status: 'active',
  editVersion: version,
);
