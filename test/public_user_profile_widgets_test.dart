import 'dart:async';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/public_user_profile.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/public_profile_fixtures.dart';

Future<void> pumpProfile(
  WidgetTester tester,
  IPublicUserProfileRepository repository, {
  String userId = 'seller',
  double textScale = 1,
}) => tester.pumpWidget(
  Provider<IPublicUserProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: PublicUserProfile(userId: userId),
    ),
  ),
);

void main() {
  testWidgets('shows a labelled loading state then an empty public profile', (tester) async {
    final pending = Completer<Result<PublicUserProfilePage>>();
    await pumpProfile(tester, FakePublicProfileRepository((_, _) => pending.future));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No public listings at the moment.'), findsNothing);
    pending.complete(Result.success(publicProfilePage()));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('No public listings at the moment.'), findsOneWidget);
    for (final label in ['Settings', 'Orders', 'Liked', 'Email', 'Address', 'Give']) {
      expect(find.text(label), findsNothing);
    }
  });

  for (final status in [404, 410]) {
    testWidgets('HTTP $status shows unavailable rather than an empty profile', (tester) async {
      await pumpProfile(
        tester,
        FakePublicProfileRepository((_, _) => Result.failure('private status', statusCode: status)),
      );
      await tester.pumpAndSettle();
      expect(find.text('This profile is unavailable.'), findsOneWidget);
      expect(find.text('No public listings at the moment.'), findsNothing);
      expect(find.text('private status'), findsNothing);
    });
  }

  testWidgets('temporary failure exposes safe copy and a working retry', (tester) async {
    var fail = true;
    final repository = FakePublicProfileRepository(
      (_, _) => fail ? Result.failure('PRIVATE_BACKEND_ERROR', statusCode: 500) : Result.success(publicProfilePage()),
    );
    await pumpProfile(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t load this profile. Please try again.'), findsOneWidget);
    expect(find.text('PRIVATE_BACKEND_ERROR'), findsNothing);
    fail = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(repository.calls.length, 2);
  });

  testWidgets('listings have accessible actions and pagination can recover from failure', (tester) async {
    final semantics = tester.ensureSemantics();
    var failMore = true;
    final repository = FakePublicProfileRepository(
      (_, cursor) => cursor == null
          ? Result.success(publicProfilePage(products: [publicProfileProduct('one')], cursor: 'next'))
          : failMore
          ? Result.failure('network')
          : Result.success(publicProfilePage(products: [publicProfileProduct('two')])),
    );
    await pumpProfile(tester, repository);
    await tester.pumpAndSettle();
    expect(find.byType(SellerListingCard), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Listing one. £10.00.')),
      matchesSemantics(
        label: 'Listing one. £10.00.',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
    await tester.scrollUntilVisible(find.text(AppStrings.profileListingsLoadMore), 300);
    await tester.tap(find.text(AppStrings.profileListingsLoadMore));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t load more listings.'), findsOneWidget);
    failMore = false;
    await tester.ensureVisible(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.byType(SellerListingCard), findsNWidgets(2));
    expect(repository.calls.last.cursor, 'next');
  });

  testWidgets('large text on a narrow screen uses one column without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpProfile(
      tester,
      FakePublicProfileRepository(
        (_, _) => Result.success(
          publicProfilePage(
            username: 'A longer public username for accessibility',
            products: [publicProfileProduct('one'), publicProfileProduct('two')],
          ),
        ),
      ),
      textScale: 3,
    );
    await tester.pumpAndSettle();
    final cards = find.byType(SellerListingCard);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('public-listing-one')), 300);
    expect(tester.getTopLeft(cards.at(1)).dy, greaterThan(tester.getTopLeft(cards.at(0)).dy));
    expect(tester.getTopLeft(cards.at(1)).dx, tester.getTopLeft(cards.at(0)).dx);
    expect(tester.takeException(), isNull);
  });

  testWidgets('broken avatar has a safe fallback', (tester) async {
    await pumpProfile(
      tester,
      FakePublicProfileRepository(
        (_, _) => Result.success(
          publicProfilePage(
            imageUrl: 'https://example.test/missing-avatar.jpg',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching user IDs ignores the earlier profile response', (tester) async {
    final pending = Completer<Result<PublicUserProfilePage>>();
    final repository = FakePublicProfileRepository(
      (id, _) =>
          id == 'first' ? pending.future : Result.success(publicProfilePage(userId: id, username: 'Second seller')),
    );
    await pumpProfile(tester, repository, userId: 'first');
    await pumpProfile(tester, repository, userId: 'second');
    await tester.pumpAndSettle();
    pending.complete(Result.success(publicProfilePage(userId: 'first', username: 'First seller')));
    await tester.pumpAndSettle();
    expect(find.text('Second seller'), findsOneWidget);
    expect(find.text('First seller'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh clears listings when the profile becomes unavailable', (tester) async {
    var unavailable = false;
    final repository = FakePublicProfileRepository(
      (_, _) => unavailable
          ? Result.failure('gone', statusCode: 410)
          : Result.success(publicProfilePage(products: [publicProfileProduct('one')])),
    );
    await pumpProfile(tester, repository);
    await tester.pumpAndSettle();
    unavailable = true;
    await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('This profile is unavailable.'), findsOneWidget);
    expect(find.byType(SellerListingCard), findsNothing);
    expect(find.text('Alex'), findsNothing);
  });
}
