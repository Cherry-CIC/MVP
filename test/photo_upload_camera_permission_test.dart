import 'dart:async';
import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
  const cameraChannel = MethodChannel('plugins.flutter.io/image_picker');
  const settingsChannel = MethodChannel('com.spencerccf.app_settings/methods');
  late Directory directory;
  late List<XFile> photos;
  late PermissionStatus status;
  late PermissionStatus requestResult;
  Completer<int>? pendingStatus;
  Completer<Map<int, int>>? pendingRequest;
  String? nextPhoto;
  final events = <String>[];
  final changes = <List<XFile>>[];
  final enabled = ValueNotifier(true);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('cherry_camera_permissions_');
    final png = File('assets/icon/icon.png').readAsBytesSync();
    photos = List.generate(2, (index) {
      final file = File('${directory.path}/photo_$index.png')..writeAsBytesSync(png);
      return XFile(file.path);
    });
    status = PermissionStatus.denied;
    requestResult = PermissionStatus.granted;
    pendingStatus = null;
    pendingRequest = null;
    nextPhoto = null;
    events.clear();
    changes.clear();
    enabled.value = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            expect(call.arguments, Permission.camera.value);
            events.add('status');
            return pendingStatus?.future ?? status.index;
          case 'requestPermissions':
            expect(call.arguments, [Permission.camera.value]);
            events.add('request');
            status = requestResult;
            return pendingRequest?.future ?? {Permission.camera.value: status.index};
          default:
            throw StateError('Unexpected permission operation: ${call.method}');
        }
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(cameraChannel, (
      call,
    ) async {
      if (call.method == 'pickMultiImage') {
        events.add('gallery');
        return <String>[];
      }
      expect(call.method, 'pickImage');
      expect(call.arguments['source'], ImageSource.camera.index);
      events.add('camera');
      return nextPhoto;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(settingsChannel, (
      call,
    ) async {
      expect(call.method, 'openSettings');
      events.add('settings');
      return null;
    });
  });

  tearDown(() {
    for (final channel in [permissionChannel, cameraChannel, settingsChannel]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    directory.deleteSync(recursive: true);
  });
  tearDownAll(enabled.dispose);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() async {
      for (final photo in photos) {
        await precacheImage(FileImage(File(photo.path)), context);
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<bool>(
              valueListenable: enabled,
              builder: (context, value, child) => PhotoUpload(
                initialImages: [photos.first],
                enabled: value,
                onImagesChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openCamera(WidgetTester tester) async {
    await tester.tap(find.byTooltip(AppStrings.addMorePhotos));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cameraPhoto));
    await tester.pumpAndSettle();
  }

  void expectExistingPhotoUnchanged(WidgetTester tester) {
    expect(changes, isEmpty);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byKey(ValueKey(photos.first.path)), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('granted access opens consecutive captures without an explanation or permission request', (tester) async {
    status = PermissionStatus.granted;
    nextPhoto = photos.last.path;
    await pump(tester);
    await openCamera(tester);
    expect(events, ['status', 'camera']);
    expect(find.text(AppStrings.cameraPermissionTitle), findsNothing);
    expect(changes.single.map((image) => image.path), photos.map((image) => image.path));

    // Cancelling the next capture keeps the previously added photos.
    nextPhoto = null;
    await openCamera(tester);
    expect(events, ['status', 'camera', 'status', 'camera']);
    expect(find.text(AppStrings.cameraPermissionTitle), findsNothing);
    expect(changes, hasLength(1));
    expect(find.text('2 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ungranted access explains first, requests on Continue, and skips the explanation after approval', (
    tester,
  ) async {
    await pump(tester);
    await openCamera(tester);
    expect(events, ['status']);
    expect(find.text(AppStrings.cameraPermissionRationale), findsOneWidget);
    await tester.tap(find.text(AppStrings.continueText));
    await tester.pumpAndSettle();
    expect(events, ['status', 'request', 'camera']);
    await openCamera(tester);
    expect(events, ['status', 'request', 'camera', 'status', 'camera']);
    expect(find.byType(AlertDialog), findsNothing);
    expectExistingPhotoUnchanged(tester);
  });

  testWidgets('cancelling the explanation does not request access or change photos', (tester) async {
    await pump(tester);
    await openCamera(tester);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(events, ['status']);
    expectExistingPhotoUnchanged(tester);
  });

  for (final refused in [PermissionStatus.denied, PermissionStatus.permanentlyDenied]) {
    testWidgets('a request returning $refused shows guidance and never opens the camera', (tester) async {
      requestResult = refused;
      await pump(tester);
      await openCamera(tester);
      await tester.tap(find.text(AppStrings.continueText));
      await tester.pumpAndSettle();
      expect(events, ['status', 'request']);
      expect(
        find.text(
          refused.isPermanentlyDenied
              ? AppStrings.cameraPermissionPermanentlyDeniedMessage
              : AppStrings.cameraPermissionDeniedMessage,
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.openSettings), findsOneWidget);
      expectExistingPhotoUnchanged(tester);
    });
  }

  for (final blocked in [PermissionStatus.permanentlyDenied, PermissionStatus.restricted]) {
    testWidgets('$blocked access goes directly to existing recovery guidance', (tester) async {
      status = blocked;
      await pump(tester);
      await openCamera(tester);
      expect(events, ['status']);
      expect(find.text(AppStrings.cameraPermissionRationale), findsNothing);
      expect(find.text(AppStrings.cameraPermissionPermanentlyDeniedMessage), findsOneWidget);
      expectExistingPhotoUnchanged(tester);
    });
  }

  testWidgets('the next explicit camera action rechecks permission changed in Settings', (tester) async {
    status = PermissionStatus.permanentlyDenied;
    await pump(tester);
    await openCamera(tester);
    await tester.tap(find.text(AppStrings.openSettings));
    await tester.pumpAndSettle();
    expect(events, ['status', 'settings']);
    status = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(events, ['status', 'settings']);
    await openCamera(tester);
    expect(events, ['status', 'settings', 'status', 'camera']);
    expect(find.byType(AlertDialog), findsNothing);
    expectExistingPhotoUnchanged(tester);
  });

  testWidgets('previous approval is not cached when permission is revoked', (tester) async {
    status = PermissionStatus.granted;
    await pump(tester);
    await openCamera(tester);
    status = PermissionStatus.denied;
    await openCamera(tester);
    expect(events, ['status', 'camera', 'status']);
    expect(find.text(AppStrings.cameraPermissionRationale), findsOneWidget);
    expectExistingPhotoUnchanged(tester);
  });

  testWidgets('gallery selection does not check or request camera access', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip(AppStrings.addMorePhotos));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.galleryPhotoMultiple));
    await tester.pumpAndSettle();
    expect(events, ['gallery']);
    expectExistingPhotoUnchanged(tester);
  });

  for (final unmount in [false, true]) {
    testWidgets('a pending status result is ignored after ${unmount ? 'leaving' : 'disabling'} the picker', (
      tester,
    ) async {
      pendingStatus = Completer<int>();
      await pump(tester);
      await openCamera(tester);
      if (unmount) {
        await tester.pumpWidget(const SizedBox.shrink());
      } else {
        enabled.value = false;
        await tester.pump();
      }
      pendingStatus!.complete(PermissionStatus.granted.index);
      await tester.pumpAndSettle();
      expect(events, ['status']);
      expect(changes, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('permission approval after leaving the picker does not open the camera', (tester) async {
    pendingRequest = Completer<Map<int, int>>();
    await pump(tester);
    await openCamera(tester);
    await tester.tap(find.text(AppStrings.continueText));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    pendingRequest!.complete({Permission.camera.value: PermissionStatus.granted.index});
    await tester.pumpAndSettle();
    expect(events, ['status', 'request']);
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
