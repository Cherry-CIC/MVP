import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/products/widgets/charity_details_dialog.dart';
import 'package:cherry_mvp/features/products/widgets/seller_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Charity charity({
  String name = 'Example charity',
  String? description = 'Supporting local people.',
  String image = AppImages.mind,
}) => Charity(
  id: 'charity-1',
  name: name,
  imageUrl: image,
  description: description,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  for (final description in [null, '  ', 'Description from the charity record.']) {
    testWidgets('uses Discovery only when the record description is absent: $description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharityDetailsDialog(
              charity: charity(name: ' British  Red Cross ', description: description),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final expected = description == null || description.trim().isEmpty
          ? DiscoverRepository().descriptionForCharityName('British Red Cross')!
          : description;
      expect(find.text(expected), findsOneWidget);
      expect(find.text('A description is not available for this charity yet.'), findsNothing);
    });
  }

  testWidgets('charity opens details independently of seller and closes with icon', (tester) async {
    var sellerTaps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SellerInformation(
            user: UserInformation(
              username: 'Alex',
              location: '',
              reviewsCount: 0,
              followersCount: 0,
              followingCount: 0,
              rating: 0,
              awards: 0,
              hasBuyerDiscounts: false,
            ),
            charity: const SizedBox.shrink(),
            charityDetails: charity(),
            onViewProfile: () => sellerTaps++,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('About Example charity'), findsOneWidget);
    final target = find.byKey(const ValueKey('product-charity-details'));
    expect(tester.getSize(target), const Size(56, 56));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byType(CharityDetailsDialog), findsOneWidget);
    expect(find.text('Example charity'), findsOneWidget);
    expect(find.text('Supporting local people.'), findsOneWidget);
    expect(find.descendant(of: find.byType(CharityDetailsDialog), matching: find.byType(Image)), findsOneWidget);
    expect(sellerTaps, 0);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(CharityDetailsDialog), findsNothing);
    await tester.tap(find.text('Alex'));
    expect(sellerTaps, 1);
    semantics.dispose();
  });

  for (final image in ['', 'assets/missing-charity-logo.png']) {
    testWidgets('missing description and logo use honest fallbacks: $image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharityDetailsDialog(
              charity: charity(description: '  ', image: image),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A description is not available for this charity yet.'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('long description scrolls on narrow screen with large text in $brightness', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => CharityDetailsDialog(
                    charity: charity(description: '${'A long description. ' * 80}End of description.'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scroll = find.descendant(of: find.byType(Dialog), matching: find.byType(SingleChildScrollView));
      expect(scroll, findsOneWidget);
      await tester.drag(scroll, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(CharityDetailsDialog), findsNothing);
    });
  }
}
