import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_reorder_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercise the list's native screen-reader actions through the semantics tree.
Future<void> moveSelectedPhoto(WidgetTester tester, {required bool earlier}) async {
  final stripFinder = find.byType(PhotoReorderStrip);
  final strip = tester.widget<PhotoReorderStrip>(stripFinder);
  final thumbnail = find.descendant(
    of: stripFinder,
    matching: find.byKey(ValueKey(strip.images[strip.selectedIndex].path)),
  );
  await tester.ensureVisible(thumbnail);
  final semantics = tester.ensureSemantics();
  try {
    await tester.pumpAndSettle();
    final localisations = WidgetsLocalizations.of(tester.element(stripFinder));
    final action = CustomSemanticsAction(
      label: earlier ? localisations.reorderItemLeft : localisations.reorderItemRight,
    );
    final label = AppStrings.photoPosition(strip.selectedIndex + 1, strip.images.length);
    final thumbnailLabel = strip.selectedIndex == 0 ? '$label, ${AppStrings.coverPhoto}' : label;
    final node = find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label == thumbnailLabel && data.hasAction(SemanticsAction.customAction);
    });
    expect(node, findsOne);
    tester.semantics.customAction(node, action);
    await tester.pumpAndSettle();
  } finally {
    semantics.dispose();
  }
}
