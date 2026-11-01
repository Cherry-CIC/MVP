import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_theme.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_reorder_strip.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'support/photo_reorder_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late List<XFile> photos;
  final changes = <List<XFile>>[];
  const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

  setUp(() {
    directory = Directory.systemTemp.createTempSync('cherry_photo_order_');
    final png = File('assets/icon/icon.png').readAsBytesSync();
    photos = List.generate(6, (index) {
      final file = File('${directory.path}/photo_$index.png')..writeAsBytesSync(png);
      return XFile(file.path);
    });
    changes.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pickerChannel, null);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    directory.deleteSync(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    List<XFile>? initial,
    bool enabled = true,
    bool reordering = true,
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1100);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    if (find.byType(MaterialApp).evaluate().isEmpty) {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    }
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      final width = (104 + (textScale - 1) * 72).round();
      for (final photo in photos) {
        final image = FileImage(File(photo.path));
        await precacheImage(image, context);
        await precacheImage(ResizeImage(image, width: width), context);
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoUpload(
              initialImages: initial ?? photos.take(3).toList(),
              enableReordering: reordering,
              enabled: enabled,
              onImagesChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder thumbnail(int photo) => find.descendant(
    of: find.byType(PhotoReorderStrip),
    matching: find.byKey(ValueKey(photos[photo].path)),
  );

  List<String> paths(List<XFile> images) => images.map((image) => image.path).toList();

  void expectPreview(WidgetTester tester, int photo, int position) {
    final page = tester.widget<PageView>(find.byType(PageView));
    expect(page.controller!.page, position.toDouble());
    expect(
      find.text('${position + 1} / ${tester.widget<PhotoReorderStrip>(find.byType(PhotoReorderStrip)).images.length}'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(PageView), matching: find.byKey(ValueKey(photos[photo].path))),
      findsOneWidget,
    );
  }

  Future<void> dragPhoto(WidgetTester tester, int photo, Offset offset) async {
    final gesture = await tester.startGesture(tester.getCenter(thumbnail(photo)));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(offset);
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('tap previews, screen-reader actions reorder, and callback snapshots retain their order', (tester) async {
    await pump(tester);
    expectPreview(tester, 0, 0);
    expect(find.text('Move earlier'), findsNothing);
    expect(find.text('Move later'), findsNothing);
    await tester.tap(thumbnail(2));
    await tester.pumpAndSettle();
    expectPreview(tester, 2, 2);

    await moveSelectedPhoto(tester, earlier: true);
    await tester.pumpAndSettle();
    expect(paths(changes.last), paths([photos[0], photos[2], photos[1]]));
    expectPreview(tester, 2, 1);
    final firstChange = changes.single;
    await moveSelectedPhoto(tester, earlier: true);
    await tester.pumpAndSettle();
    expect(paths(changes.last), paths([photos[2], photos[0], photos[1]]));
    expect(paths(firstChange), paths([photos[0], photos[2], photos[1]]));
    expectPreview(tester, 2, 0);
    expect(find.descendant(of: thumbnail(2), matching: find.text(AppStrings.coverPhoto)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press dragging in either direction preserves the active photo', (tester) async {
    await pump(tester);
    await dragPhoto(tester, 2, const Offset(-220, 0));
    expect(paths(changes.last), paths([photos[2], photos[0], photos[1]]));
    expectPreview(tester, 0, 1);
    await dragPhoto(tester, 2, const Offset(220, 0));
    expect(paths(changes.last), paths(photos.take(3).toList()));
    expectPreview(tester, 0, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding and removing after reordering keeps cover, preview and order consistent', (tester) async {
    await pump(tester);
    await tester.tap(thumbnail(2));
    await tester.pumpAndSettle();
    await moveSelectedPhoto(tester, earlier: true);
    await tester.pumpAndSettle();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pickerChannel, (
      call,
    ) async {
      expect(call.method, 'pickMultiImage');
      return [photos[0].path, photos[3].path, photos[3].path];
    });
    await tester.tap(find.byTooltip(AppStrings.addMorePhotos));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.galleryPhotoMultiple));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(paths(changes.last), paths([photos[0], photos[2], photos[1], photos[3]]));
    expectPreview(tester, 3, 3);
    await tester.tap(find.byTooltip(AppStrings.removePhoto));
    await tester.pumpAndSettle();
    expect(paths(changes.last), paths([photos[0], photos[2], photos[1]]));
    expectPreview(tester, 1, 2);
    await tester.tap(thumbnail(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.removePhoto));
    await tester.pumpAndSettle();
    expectPreview(tester, 2, 0);
    expect(find.descendant(of: thumbnail(2), matching: find.text(AppStrings.coverPhoto)), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.removePhoto));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reorderPhotosHint), findsNothing);
    await tester.tap(find.byTooltip(AppStrings.removePhoto));
    await tester.pumpAndSettle();
    expect(changes.last, isEmpty);
    expect(find.byType(PhotoReorderStrip), findsNothing);
    expect(find.text(AppStrings.takePhoto), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving beyond the visible row keeps the selected thumbnail in view', (tester) async {
    await pump(tester, initial: photos);
    for (var index = 0; index < photos.length - 1; index++) {
      await moveSelectedPhoto(tester, earlier: false);
      await tester.pumpAndSettle();
    }
    expect(paths(changes.last), paths([...photos.skip(1), photos.first]));
    expectPreview(tester, 0, 5);
    final row = tester.getRect(find.byType(ReorderableListView));
    final selected = tester.getRect(thumbnail(0));
    expect(selected.left, greaterThanOrEqualTo(row.left));
    expect(selected.right - 12, lessThanOrEqualTo(row.right + 0.1));
    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expectPreview(tester, 5, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled upload prevents drags, movement, adding and removal', (tester) async {
    await pump(tester, enabled: false);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close)).onPressed, isNull);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_a_photo)).onPressed, isNull);

    await dragPhoto(tester, 2, const Offset(-220, 0));
    await moveSelectedPhoto(tester, earlier: false);
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent replacement and clearing synchronise the preview and controls', (tester) async {
    await pump(tester);
    await tester.tap(thumbnail(2));
    await tester.pumpAndSettle();
    await pump(tester, initial: [photos[2], photos[0]]);
    expectPreview(tester, 2, 0);
    await pump(tester, initial: []);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(PhotoReorderStrip), findsNothing);
    expect(find.text(AppStrings.takePhoto), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared picker keeps reordering opt-in', (tester) async {
    await pump(tester, reordering: false);
    expect(find.byType(PhotoReorderStrip), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('large text in $brightness has labelled thumbnails and no overflow', (tester) async {
      final semantics = tester.ensureSemantics();

      await pump(tester, textScale: 2, brightness: brightness);
      expect(find.bySemanticsLabel('Photo 1 of 3, Cover photo'), findsOneWidget);
      expect(find.text('Move earlier'), findsNothing);
      expect(find.text('Move later'), findsNothing);
      final hint = tester.widget<Text>(find.text(AppStrings.reorderPhotosHint));
      final theme = Theme.of(tester.element(find.byType(PhotoReorderStrip)));
      expect(hint.style!.color, theme.colorScheme.onSurfaceVariant);
      final luminance = hint.style!.color!.computeLuminance();
      final background = theme.scaffoldBackgroundColor.computeLuminance();
      final contrast = brightness == Brightness.dark
          ? (luminance + 0.05) / (background + 0.05)
          : (background + 0.05) / (luminance + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
