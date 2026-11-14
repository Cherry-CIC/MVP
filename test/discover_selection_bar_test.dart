import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Local to you tab follows the showLocalCharitiesTab flag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverSelectionBar(selectedTag: 'popular', onSelected: (_) {}),
        ),
      ),
    );

    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Smaller Charities'), findsOneWidget);
    expect(
      find.text('Local to you'),
      FeatureFlags.showLocalCharitiesTab ? findsOneWidget : findsNothing,
    );
  });
}
