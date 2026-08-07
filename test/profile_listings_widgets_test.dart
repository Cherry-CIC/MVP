import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/profile_listings_repository.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/profile_listings_section.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _ProfileListingsRepositoryStub implements IProfileListingsRepository {
  final Result<ProfileListingsPage> result;

  const _ProfileListingsRepositoryStub(this.result);

  @override
  Future<Result<ProfileListingsPage>> fetchListings({
    int limit = 20,
    String? cursor,
  }) async {
    return result;
  }
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required ProfileListingsViewModel viewModel,
  VoidCallback? onCreateListing,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProfileListingsSection(
                onCreateListing: onCreateListing ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('seller card shows identifying information and an image fallback', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: SellerListingCard(
              listing: SellerListing(
                id: 'listing-1',
                name: 'Example shirt',
                imageUrls: [],
                price: 12.5,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Example shirt'), findsOneWidget);
    expect(find.text('£12.50'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Example shirt. £12.50.'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('seller card replaces a failed network image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: SellerListingCard(
              listing: SellerListing(
                id: 'listing-1',
                name: 'Example shirt',
                imageUrls: ['https://example.invalid/unavailable.jpg'],
                price: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated listings render in two columns without a button-style header', (tester) async {
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          ProfileListingsPage(
            listings: const [
              SellerListing(
                id: 'listing-1',
                name: 'First listing',
                imageUrls: [],
                price: 10,
              ),
              SellerListing(
                id: 'listing-2',
                name: 'Second listing',
                imageUrls: [],
                price: 20,
              ),
            ],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(tester, viewModel: viewModel);

    final firstPosition = tester.getTopLeft(find.text('First listing'));
    final secondPosition = tester.getTopLeft(find.text('Second listing'));
    expect(firstPosition.dy, secondPosition.dy);
    expect(firstPosition.dx, lessThan(secondPosition.dx));
    expect(
      find.ancestor(
        of: find.text(AppStrings.profileUserListings),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('empty listings explain the state and offer Give', (tester) async {
    var createListingPressed = false;
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          const ProfileListingsPage(
            listings: [],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(
      tester,
      viewModel: viewModel,
      onCreateListing: () => createListingPressed = true,
    );
    await tester.tap(find.text(AppStrings.profileListingsCreate));

    expect(find.text(AppStrings.profileListingsEmpty), findsOneWidget);
    expect(createListingPressed, isTrue);
  });

  testWidgets('failed listings show a retry control', (tester) async {
    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.failure('technical failure'),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(tester, viewModel: viewModel);

    expect(find.text(AppStrings.profileListingsLoadFailed), findsOneWidget);
    expect(find.text('technical failure'), findsOneWidget);
    expect(find.text(AppStrings.retry), findsOneWidget);
  });

  testWidgets('seller cards tolerate large text without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final viewModel = ProfileListingsViewModel(
      repository: _ProfileListingsRepositoryStub(
        Result.success(
          const ProfileListingsPage(
            listings: [
              SellerListing(
                id: 'listing-1',
                name: 'A long listing title that needs more than one line',
                imageUrls: [],
                price: null,
              ),
            ],
            limit: 20,
            nextCursor: null,
            hasMore: false,
          ),
        ),
      ),
    );
    await viewModel.loadInitialListings();

    await _pumpSection(
      tester,
      viewModel: viewModel,
      textScale: 2,
    );

    expect(find.text(AppStrings.profileListingPriceUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile shortcuts contain Orders and Liked but not Listings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UserOrderDetails()),
      ),
    );

    expect(find.text(AppStrings.profileUserOrders), findsOneWidget);
    expect(find.text(AppStrings.profileUserLiked), findsOneWidget);
    expect(find.text(AppStrings.profileUserListings), findsNothing);
  });
}
