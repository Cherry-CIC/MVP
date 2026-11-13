// Run: flutter test --no-pub tool/render_collection_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'ready_to_collect_preview.dart';

void main() {
  testWidgets('render collection previews for visual review', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fonts = FontLoader('PreviewSans')
      ..addFont(rootBundle.load('assets/fonts/Raleway-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Raleway-Bold.ttf'));
    await fonts.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final originalShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      final binding = tester.binding;
      final key = GlobalKey();
      for (final variant in ['ready', 'expired', 'dark', 'timer', 'timer-dark', 'timer-large']) {
        tester.view.physicalSize = variant == 'timer-large' ? const Size(320, 844) : const Size(390, 844);
        tester.platformDispatcher.textScaleFactorTestValue = variant == 'timer-large' ? 2 : 1;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ReadyToCollectPreview(
              expired: variant == 'expired',
              dark: variant == 'dark' || variant == 'timer-dark',
              showTimer: variant.startsWith('timer'),
              fontFamily: 'PreviewSans',
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(Scaffold));
          for (final asset in [
            'product1.png',
            'product2.png',
            'product3.png',
            'product4.png',
            'charity_home_start.png',
            'explore_image.png',
          ]) {
            await precacheImage(AssetImage('assets/images/$asset'), context);
          }
        });
        await tester.pumpAndSettle();
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await binding.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/collection-preview/$variant.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        if (variant == 'timer') {
          await tester.tap(find.text('left to collect'));
          await tester.pumpAndSettle();
          expect(find.text('Ready to collect'), findsOneWidget);
          expect(find.text('left to collect'), findsNothing);
          await tester.tap(find.text('Not yet'));
          await tester.pumpAndSettle();
          expect(find.text('left to collect'), findsOneWidget);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDisableShadows = originalShadows;
    }
  });
}
