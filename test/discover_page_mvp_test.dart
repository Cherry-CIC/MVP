import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/dummy_charity.dart';
import 'package:cherry_mvp/features/discover/discover_page.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/discover/discover_viewmodel.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_list.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:cherry_mvp/features/discover/widgets/items_in_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Discover hides the category selection bar for the MVP', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DiscoverViewModel(
          discoverRepository: DiscoverRepository(),
        ),
        child: MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 10)),
          ),
          home: const DiscoverPage(),
        ),
      ),
    );

    expect(find.byType(DiscoverSelectionBar), findsNothing);
    expect(find.text(AppStrings.popularText), findsNothing);
    expect(find.text(AppStrings.smallerCharitiesText), findsNothing);
    expect(find.text(AppStrings.localToYouText), findsNothing);
    expect(find.text('WaterAid'), findsOneWidget);

    final titleBottom = tester.getBottomLeft(find.text(AppStrings.discoverText)).dy;
    final firstCardTop = tester.getTopLeft(find.byType(DiscoverCharityCard).first).dy;

    expect(firstCardTop - titleBottom, greaterThanOrEqualTo(8));
  });

  testWidgets('Discover hides items in support for the MVP', (tester) async {
    const charity = DummyCharity(
      charityName: 'WaterAid',
      charityImage: AppImages.discoverImage1,
      description: 'Clean water support.',
      charityLogo: AppImages.waterAidLogo,
      likes: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 10)),
        ),
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              DiscoverCharityList(charities: [charity], products: []),
            ],
          ),
        ),
      ),
    );

    expect(find.text('WaterAid'), findsOneWidget);
    expect(find.text(AppStrings.itemsInSupportText), findsNothing);
    expect(find.byType(ItemsInSupport), findsNothing);
  });
}
