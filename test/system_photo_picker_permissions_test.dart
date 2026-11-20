import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/system_photo_picker.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/register/register_repository.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class _MockRegisterRepository extends Mock implements RegisterRepository {}

class _FakeImagePickerPlatform extends ImagePickerPlatform {
  final List<({ImageSource source, ImagePickerOptions options})> singleCalls = [];
  final List<MultiImagePickerOptions> multiCalls = [];
  Future<XFile?> Function()? onGetImage;
  Future<List<XFile>> Function()? onGetMultiImage;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    singleCalls.add((source: source, options: options));
    if (onGetImage != null) {
      return await onGetImage!();
    }
    return null;
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    multiCalls.add(options);
    if (onGetMultiImage != null) {
      return await onGetMultiImage!();
    }
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('System Photo Picker Configuration', () {
    test('configureSystemPhotoPicker enables useAndroidPhotoPicker on ImagePickerAndroid', () {
      final androidPlatform = ImagePickerAndroid();
      expect(androidPlatform.useAndroidPhotoPicker, isFalse);

      configureSystemPhotoPicker(androidPlatform);
      expect(androidPlatform.useAndroidPhotoPicker, isTrue);
    });

    test('configureSystemPhotoPicker does not throw when platform is not ImagePickerAndroid', () {
      final fakePlatform = _FakeImagePickerPlatform();
      expect(() => configureSystemPhotoPicker(fakePlatform), returnsNormally);
    });
  });

  group('RegisterForm Photo Picker', () {
    late ImagePickerPlatform originalPlatform;
    late _FakeImagePickerPlatform fakePlatform;
    late Directory tempDir;
    late File testImageFile;

    setUp(() {
      originalPlatform = ImagePickerPlatform.instance;
      fakePlatform = _FakeImagePickerPlatform();
      ImagePickerPlatform.instance = fakePlatform;

      tempDir = Directory.systemTemp.createTempSync('cherry_reg_picker_test_');
      testImageFile = File('${tempDir.path}/avatar.png')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() {
      ImagePickerPlatform.instance = originalPlatform;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<void> pumpRegisterForm(WidgetTester tester) async {
      final navigator = NavigationProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NavigationProvider>.value(value: navigator),
            ChangeNotifierProvider<RegisterViewModel>(
              create: (_) => RegisterViewModel(
                registerRepository: _MockRegisterRepository(),
                navigator: navigator,
              ),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigator.navigatorKey,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const Scaffold(body: RegisterForm()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('picks gallery photo with requestFullMetadata set to false', (tester) async {
      fakePlatform.onGetImage = () async => XFile(testImageFile.path);

      await pumpRegisterForm(tester);

      // Tap on the avatar camera icon to trigger photo selection
      final cameraIcon = find.byIcon(Icons.camera_alt);
      expect(cameraIcon, findsOneWidget);
      await tester.tap(cameraIcon);
      await tester.pumpAndSettle();

      expect(fakePlatform.singleCalls, hasLength(1));
      final call = fakePlatform.singleCalls.first;
      expect(call.source, ImageSource.gallery);
      expect(call.options.requestFullMetadata, isFalse);

      // Verify the selected image is displayed in the avatar container
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('debounces duplicate rapid taps while photo picker is opening', (tester) async {
      final completer = Completer<XFile?>();
      fakePlatform.onGetImage = () => completer.future;

      await pumpRegisterForm(tester);

      final cameraIcon = find.byIcon(Icons.camera_alt);
      await tester.tap(cameraIcon);
      await tester.pump();
      // Tap again while first pick is still pending
      await tester.tap(cameraIcon);
      await tester.pump();

      expect(fakePlatform.singleCalls, hasLength(1));

      completer.complete(null);
      await tester.pumpAndSettle();

      // Subsequent tap after completion triggers new selection
      await tester.tap(cameraIcon);
      await tester.pump();
      expect(fakePlatform.singleCalls, hasLength(2));
    });

    testWidgets('safely handles PlatformException without uncaught crash and shows SnackBar', (tester) async {
      fakePlatform.onGetImage = () async {
        throw PlatformException(code: 'picker_failed', message: 'User dismissed');
      };

      await pumpRegisterForm(tester);

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining(AppStrings.errorPickingImage), findsOneWidget);
    });

    testWidgets('safely ignores result if widget is disposed while picker is open', (tester) async {
      final completer = Completer<XFile?>();
      fakePlatform.onGetImage = () => completer.future;

      await pumpRegisterForm(tester);

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      // Navigate away / dispose widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Gone'))));
      await tester.pumpAndSettle();

      completer.complete(XFile(testImageFile.path));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Manifest and Plist Compliance Checks', () {
    test('AndroidManifest.xml contains tools:node="remove" for broad media and storage permissions', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('xmlns:tools="http://schemas.android.com/tools"'));
      expect(content, contains('android:name="android.permission.READ_MEDIA_IMAGES" tools:node="remove"'));
      expect(content, contains('android:name="android.permission.READ_MEDIA_VIDEO" tools:node="remove"'));
      expect(content, contains('android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" tools:node="remove"'));
      expect(content, contains('android:name="android.permission.READ_EXTERNAL_STORAGE" tools:node="remove"'));
      expect(content, contains('android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:node="remove"'));
    });

    test('ios/Runner/Info.plist does not declare NSPhotoLibraryUsageDescription', () {
      final infoPlistFile = File('ios/Runner/Info.plist');
      expect(infoPlistFile.existsSync(), isTrue);

      final content = infoPlistFile.readAsStringSync();
      expect(content, isNot(contains('NSPhotoLibraryUsageDescription')));
      expect(content, isNot(contains('NSPhotoLibraryAddUsageDescription')));
      expect(content, contains('NSCameraUsageDescription'));
    });
  });
}
