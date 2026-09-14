import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

class _UnusedRegisterRepository implements RegisterRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Registration must not run in picker tests.');
}

class _UnusedDonationRepository implements IDonationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Donation submission must not run in picker tests.');
}

class _Picker extends ImagePickerPlatform {
  final singleCalls = <({ImageSource source, ImagePickerOptions options})>[];
  final multiCalls = <MultiImagePickerOptions>[];
  Future<XFile?> Function() singleResult = () async => null;
  Future<List<XFile>> Function() multiResult = () async => [];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    singleCalls.add((source: source, options: options));
    return singleResult();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) {
    multiCalls.add(options);
    return multiResult();
  }
}

Widget _registration() {
  final navigator = NavigationProvider();
  return MultiProvider(
    providers: [
      Provider<NavigationProvider>.value(value: navigator),
      ChangeNotifierProvider(
        create: (_) => RegisterViewModel(registerRepository: _UnusedRegisterRepository(), navigator: navigator),
      ),
    ],
    child: MaterialApp(
      navigatorKey: navigator.navigatorKey,
      home: const Scaffold(body: RegisterForm()),
    ),
  );
}

Widget _listing({List<XFile>? initialImages, ValueChanged<List<XFile>>? onChanged}) {
  final navigator = NavigationProvider();
  return ChangeNotifierProvider(
    create: (_) => DonationViewModel(donationRepository: _UnusedDonationRepository(), navigator: navigator),
    child: MaterialApp(
      navigatorKey: navigator.navigatorKey,
      home: Scaffold(
        body: SingleChildScrollView(
          child: PhotoUpload(initialImages: initialImages, onImagesChanged: onChanged),
        ),
      ),
    ),
  );
}

Future<void> _chooseSource(WidgetTester tester, ImageSource source) async {
  final addPhoto = find.text(AppStrings.takePhoto);
  await tester.tap(addPhoto.evaluate().isNotEmpty ? addPhoto : find.byIcon(Icons.add_a_photo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(source == ImageSource.camera ? AppStrings.cameraPhoto : AppStrings.galleryPhotoMultiple));
  await tester.pumpAndSettle();
}

Finder get _registrationPhoto => find.descendant(of: find.byType(RegisterForm), matching: find.byType(Image));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ImagePickerPlatform originalPicker;
  late _Picker picker;
  final photo = XFile(File('assets/images/product1.png').absolute.path);
  final otherPhoto = XFile(File('assets/images/product2.png').absolute.path);
  const settingsChannel = MethodChannel('uk.org.cherry.app/settings');

  setUp(() {
    originalPicker = ImagePickerPlatform.instance;
    picker = _Picker();
    ImagePickerPlatform.instance = picker;
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(settingsChannel, null);
  });

  testWidgets('registration opens the single gallery picker without full metadata', (tester) async {
    picker.singleResult = () async => photo;
    await tester.pumpWidget(_registration());
    expect(picker.singleCalls, isEmpty);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(picker.singleCalls.single.source, ImageSource.gallery);
    expect(picker.singleCalls.single.options.requestFullMetadata, isFalse);
    expect(picker.multiCalls, isEmpty);
    expect((tester.widget<Image>(_registrationPhoto).image as FileImage).file.path, photo.path);
  });

  testWidgets('registration cancellation keeps the selected photo without an error', (tester) async {
    picker.singleResult = () async => photo;
    await tester.pumpWidget(_registration());
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    picker.singleResult = () async => null;

    await tester.tap(_registrationPhoto);
    await tester.pumpAndSettle();

    expect((tester.widget<Image>(_registrationPhoto).image as FileImage).file.path, photo.path);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('registration errors are friendly and a fresh attempt can succeed', (tester) async {
    picker.singleResult = () async => throw PlatformException(code: 'unexpected', message: 'private native details');
    await tester.pumpWidget(_registration());
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('private native details'), findsNothing);
    expect(find.text('Open settings'), findsNothing);

    picker.singleResult = () async => photo;
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    expect(picker.singleCalls, hasLength(2));
    expect(_registrationPhoto, findsOneWidget);
  });

  testWidgets('registration ignores repeated taps while picking', (tester) async {
    final result = Completer<XFile?>();
    picker.singleResult = () => result.future;
    await tester.pumpWidget(_registration());

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.tap(find.byIcon(Icons.camera_alt));
    expect(picker.singleCalls, hasLength(1));

    result.complete(null);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    expect(picker.singleCalls, hasLength(2));
  });

  for (final fails in [false, true]) {
    testWidgets('registration safely ignores a late ${fails ? 'error' : 'selection'} after disposal', (tester) async {
      final result = Completer<XFile?>();
      picker.singleResult = () => result.future;
      await tester.pumpWidget(_registration());
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpWidget(const SizedBox.shrink());

      if (fails) {
        result.completeError(PlatformException(code: 'unexpected'));
      } else {
        result.complete(photo);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('listing gallery preserves compression, appends photos and ignores existing duplicates', (tester) async {
    final updates = <List<XFile>>[];
    picker.multiResult = () async => [photo, otherPhoto];
    await tester.pumpWidget(_listing(initialImages: [photo], onChanged: (images) => updates.add(List.of(images))));
    expect(picker.singleCalls, isEmpty);
    expect(picker.multiCalls, isEmpty);

    await _chooseSource(tester, ImageSource.gallery);

    final options = picker.multiCalls.single.imageOptions;
    expect(options.requestFullMetadata, isFalse);
    expect(options.maxHeight, 1024);
    expect(options.imageQuality, 85);
    expect(updates.single.map((image) => image.path), [photo.path, otherPhoto.path]);
    expect(picker.singleCalls, isEmpty);
  });

  testWidgets(
    'iOS camera denial offers app settings and a fresh attempt can succeed',
    (tester) async {
      final settingsCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(settingsChannel, (
        call,
      ) async {
        settingsCalls.add(call);
        return true;
      });
      picker.singleResult = () async => throw PlatformException(code: 'camera_access_denied');
      final updates = <List<XFile>>[];
      await tester.pumpWidget(_listing(onChanged: (images) => updates.add(List.of(images))));

      await _chooseSource(tester, ImageSource.camera);
      expect(find.text('Open settings'), findsOneWidget);
      expect(updates, isEmpty);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(settingsCalls.single.method, 'openAppSettings');

      picker.singleResult = () async => photo;
      await _chooseSource(tester, ImageSource.camera);
      expect(picker.singleCalls, hasLength(2));
      for (final call in picker.singleCalls) {
        expect(call.source, ImageSource.camera);
        expect(call.options.requestFullMetadata, isFalse);
        expect(call.options.maxHeight, 1024);
        expect(call.options.imageQuality, 85);
      }
      expect(updates.single.single.path, photo.path);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final failure in ['false', 'platform error', 'missing plugin']) {
    testWidgets(
      'iOS Settings opening gives manual recovery guidance after $failure',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(settingsChannel, (
          call,
        ) async {
          expect(call.method, 'openAppSettings');
          return switch (failure) {
            'platform error' => throw PlatformException(code: 'unavailable'),
            'missing plugin' => throw MissingPluginException(),
            _ => false,
          };
        });
        picker.singleResult = () async => throw PlatformException(code: 'camera_access_denied');
        await tester.pumpWidget(_listing());
        await _chooseSource(tester, ImageSource.camera);
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();

        expect(find.text('Open your device Settings, find cherry and enable Camera access.'), findsOneWidget);
        expect(find.byType(PhotoUpload), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'restricted camera access gives feedback without an unusable settings action',
    (tester) async {
      picker.singleResult = () async => throw PlatformException(code: 'camera_access_restricted');
      await tester.pumpWidget(_listing());
      await _chooseSource(tester, ImageSource.camera);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
      expect(find.textContaining('camera_access_restricted'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('gallery remains usable after camera denial', (tester) async {
    picker.singleResult = () async => throw PlatformException(code: 'camera_access_denied');
    picker.multiResult = () async => [photo];
    final updates = <List<XFile>>[];
    await tester.pumpWidget(_listing(onChanged: (images) => updates.add(List.of(images))));
    await _chooseSource(tester, ImageSource.camera);
    await _chooseSource(tester, ImageSource.gallery);

    expect(picker.singleCalls, hasLength(1));
    expect(picker.multiCalls, hasLength(1));
    expect(updates.single.single.path, photo.path);
  });

  testWidgets('cancelling either listing picker preserves photos without notifying the form', (tester) async {
    final updates = <List<XFile>>[];
    await tester.pumpWidget(_listing(initialImages: [photo], onChanged: (images) => updates.add(List.of(images))));
    await _chooseSource(tester, ImageSource.camera);
    await _chooseSource(tester, ImageSource.gallery);

    expect(updates, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    final images = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.image)
        .whereType<DecorationImage>();
    expect(images.single.image, FileImage(File(photo.path)));
  });

  testWidgets('listing prevents repeated source sheets and picker requests, then allows another attempt', (
    tester,
  ) async {
    final result = Completer<List<XFile>>();
    picker.multiResult = () => result.future;
    await tester.pumpWidget(_listing());
    final open = tester
        .widget<InkWell>(find.ancestor(of: find.text(AppStrings.takePhoto), matching: find.byType(InkWell)))
        .onTap!;
    open();
    open();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.galleryPhotoMultiple), findsOneWidget);

    final choose = tester
        .widget<ListTile>(
          find.ancestor(of: find.text(AppStrings.galleryPhotoMultiple), matching: find.byType(ListTile)),
        )
        .onTap!;
    choose();
    choose();
    await tester.pumpAndSettle();
    expect(find.byType(PhotoUpload), findsOneWidget);
    expect(tester.takeException(), isNull);
    open();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.galleryPhotoMultiple), findsNothing);
    expect(picker.multiCalls, hasLength(1));

    result.complete([]);
    await tester.pumpAndSettle();
    await _chooseSource(tester, ImageSource.gallery);
    expect(picker.multiCalls, hasLength(2));
  });

  testWidgets('dismissing the source sheet does not request media access', (tester) async {
    await tester.pumpWidget(_listing());
    await tester.tap(find.text(AppStrings.takePhoto));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(picker.singleCalls, isEmpty);
    expect(picker.multiCalls, isEmpty);
    await _chooseSource(tester, ImageSource.gallery);
    expect(picker.multiCalls, hasLength(1));
  });

  for (final source in ImageSource.values) {
    testWidgets('listing ${source.name} representation fallback keeps full metadata disabled', (tester) async {
      final error = PlatformException(code: 'invalid_image', message: 'Cannot load representation of type public.jpeg');
      picker.singleResult = () async => picker.singleCalls.length == 1 ? throw error : photo;
      picker.multiResult = () async => picker.multiCalls.length == 1 ? throw error : [photo];
      final updates = <List<XFile>>[];
      await tester.pumpWidget(_listing(onChanged: (images) => updates.add(List.of(images))));
      await _chooseSource(tester, source);

      final options = source == ImageSource.camera
          ? picker.singleCalls.map((call) => call.options).toList()
          : picker.multiCalls.map((call) => call.imageOptions).toList();
      expect(options, hasLength(2));
      expect(options.every((option) => !option.requestFullMetadata), isTrue);
      expect(options.first.maxHeight, 1024);
      expect(options.first.imageQuality, 85);
      expect(options.last.maxHeight, isNull);
      expect(options.last.imageQuality, isNull);
      expect(updates.single.single.path, photo.path);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  for (final fails in [false, true]) {
    testWidgets('listing safely ignores a late ${fails ? 'error' : 'selection'} after disposal', (tester) async {
      final result = Completer<List<XFile>>();
      picker.multiResult = () => result.future;
      final updates = <List<XFile>>[];
      await tester.pumpWidget(_listing(onChanged: (images) => updates.add(List.of(images))));
      await _chooseSource(tester, ImageSource.gallery);
      await tester.pumpWidget(const SizedBox.shrink());

      if (fails) {
        result.completeError(PlatformException(code: 'unexpected'));
      } else {
        result.complete([photo]);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(updates, isEmpty);
    });
  }
}
