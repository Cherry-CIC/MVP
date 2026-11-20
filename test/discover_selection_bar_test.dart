import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpBar(WidgetTester tester, {String selectedTag = 'popular', ValueChanged<String>? onSelected}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DiscoverSelectionBar(selectedTag: selectedTag, onSelected: onSelected ?? (_) {}),
      ),
    ),
  );
}

void main() {
  testWidgets('Local to you tab follows the showLocalCharitiesTab flag', (tester) async {
    await _pumpBar(tester);

    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Smaller Charities'), findsOneWidget);
    expect(
      find.text('Local to you'),
      FeatureFlags.showLocalCharitiesTab ? findsOneWidget : findsNothing,
    );
  });

  testWidgets('tabs run Popular, Smaller Charities, Categories and Categories is selectable', (tester) async {
    String? selected;
    await _pumpBar(tester, onSelected: (tag) => selected = tag);

    final popular = tester.getTopLeft(find.text('Popular')).dx;
    final smaller = tester.getTopLeft(find.text('Smaller Charities')).dx;
    final categories = tester.getTopLeft(find.text('Categories')).dx;
    expect(popular, lessThan(smaller));
    expect(smaller, lessThan(categories));

    await tester.tap(find.text('Categories'));
    expect(selected, DiscoverSelectionBar.categoriesTag);
  });

  testWidgets('semantics read naturally for charity tabs and Categories', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpBar(tester);

    expect(find.bySemanticsLabel('Popular charities'), findsOneWidget);
    expect(find.bySemanticsLabel('Smaller Charities charities'), findsOneWidget);
    expect(find.bySemanticsLabel('Categories'), findsOneWidget);
    expect(find.bySemanticsLabel('Categories charities'), findsNothing);
    semantics.dispose();
  });
}
