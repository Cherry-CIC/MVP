import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/widgets/delete_listing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/unexpected_api_service.dart';

class _Repository extends ProductRepository {
  _Repository() : super(const UnexpectedApiService());

  final deletedIds = <String>[];
  Future<Result<void>> Function()? onDelete;

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    deletedIds.add(productId);
    return onDelete == null ? Result<void>.success(null, statusCode: 200) : onDelete!();
  }
}

class _Harness {
  final repository = _Repository();
  final deletedListings = DeletedListings();
  final results = <DeleteListingOutcome?>[];
  final changes = StreamController<String?>(sync: true);
  String? userId = 'owner';
  late final viewModel = DeleteListingViewModel(
    repository: repository,
    deletedListings: deletedListings,
    currentUserId: () => userId,
    accountChanges: changes.stream,
  );

  void dispose() {
    viewModel.dispose();
    deletedListings.dispose();
    changes.close();
  }

  Future<void> open(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                results.add(
                  await showDeleteListingDialog(
                    context,
                    viewModel: viewModel,
                    productId: 'listing',
                    ownerId: 'owner',
                    knownSold: false,
                    actionSession: viewModel.session,
                  ),
                );
              },
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
  }
}

Finder get _deleteButton => find.widgetWithText(FilledButton, 'Delete listing');
Finder get _cancelButton => find.widgetWithText(TextButton, 'Cancel');

void main() {
  late _Harness harness;
  setUp(() => harness = _Harness());
  tearDown(() => harness.dispose());

  testWidgets('confirmation explains permanence and cancelling sends no request', (tester) async {
    await harness.open(tester);
    expect(find.text('Delete this listing?'), findsOneWidget);
    expect(
      find.text('This will remove your listing from cherry. You cannot undo this action.'),
      findsOneWidget,
    );
    expect(harness.repository.deletedIds, isEmpty);
    await tester.tap(_cancelButton);
    await tester.pumpAndSettle();
    expect(harness.results, [null]);
    expect(harness.repository.deletedIds, isEmpty);
    expect(harness.deletedListings.contains('listing'), isFalse);
  });

  testWidgets('busy state disables both buttons and back until the response arrives', (tester) async {
    final response = Completer<Result<void>>();
    harness.repository.onDelete = () => response.future;
    await harness.open(tester);
    await tester.tap(_deleteButton);
    await tester.pump();
    expect(harness.repository.deletedIds, ['listing']);
    expect(tester.widget<FilledButton>(_deleteButton).onPressed, isNull);
    expect(tester.widget<TextButton>(_cancelButton).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).semanticsLabel,
      'Deleting listing',
    );
    await tester.tap(_deleteButton);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(harness.repository.deletedIds, ['listing']);
    expect(harness.results, isEmpty);

    response.complete(Result<void>.success(null, statusCode: 200));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(harness.results, [DeleteListingOutcome.deleted]);
    expect(harness.deletedListings.contains('listing'), isTrue);
  });

  testWidgets('uncertain deletion keeps the dialog open and retries only when requested', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      harness.repository.onDelete = () async => throw TimeoutException('Response lost');
      await harness.open(tester);
      await tester.tap(_deleteButton);
      await tester.pumpAndSettle();
      final error = find.text(DeleteListingOutcome.uncertain.message);
      expect(error, findsOneWidget);
      expect(tester.getSemantics(error).getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(find.text('Try again'), findsOneWidget);
      expect(harness.repository.deletedIds, ['listing']);
      expect(harness.deletedListings.contains('listing'), isFalse);
      expect(harness.results, isEmpty);

      harness.repository.onDelete = () async => Result<void>.success(null, statusCode: 200);
      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      await tester.pumpAndSettle();
      expect(harness.repository.deletedIds, ['listing', 'listing']);
      expect(harness.results, [DeleteListingOutcome.deleted]);
      expect(harness.deletedListings.contains('listing'), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a terminal rejection explains why deletion is blocked and offers only Close', (tester) async {
    harness.repository.onDelete = () async => Result<void>.failure(
      'Untrusted backend text',
      statusCode: 409,
      errorCode: 'LISTING_HAS_SALES',
    );
    await harness.open(tester);
    await tester.tap(_deleteButton);
    await tester.pumpAndSettle();
    expect(find.text(DeleteListingOutcome.hasSales.message), findsOneWidget);
    expect(find.text('Untrusted backend text'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(harness.deletedListings.contains('listing'), isFalse);
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    expect(harness.results, [null]);
  });

  testWidgets('account change while confirming removes the destructive action', (tester) async {
    await harness.open(tester);
    harness.userId = 'another-owner';
    harness.changes.add(harness.userId);
    await tester.pumpAndSettle();
    expect(find.text(DeleteListingOutcome.accountChanged.message), findsOneWidget);
    expect(_deleteButton, findsNothing);
    expect(harness.repository.deletedIds, isEmpty);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(harness.results, [null]);
  });

  testWidgets('account change during deletion keeps late success out of the UI and cache', (tester) async {
    final response = Completer<Result<void>>();
    harness.repository.onDelete = () => response.future;
    await harness.open(tester);
    await tester.tap(_deleteButton);
    await tester.pump();
    harness.userId = 'another-owner';
    harness.changes.add(harness.userId);
    response.complete(Result<void>.success(null, statusCode: 200));
    await tester.pumpAndSettle();
    expect(find.text(DeleteListingOutcome.accountChanged.message), findsOneWidget);
    expect(harness.results, isEmpty);
    expect(harness.deletedListings.contains('listing'), isFalse);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(harness.results, [null]);
  });

  testWidgets('large text fits a narrow screen and exposes labelled screen-reader buttons', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await harness.open(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      for (final finder in [_deleteButton, _cancelButton]) {
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.label, isNotEmpty);
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(harness.repository.deletedIds, isEmpty);
    } finally {
      semantics.dispose();
    }
  });
}
