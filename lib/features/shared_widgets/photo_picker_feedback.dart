import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _settingsChannel = MethodChannel('uk.org.cherry.app/settings');

/// Keep platform errors out of photo flows and leave other form actions usable.
void showPhotoPickerError(BuildContext context, [PlatformException? error]) {
  final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  final cameraDenied = error?.code == 'camera_access_denied';
  final message = switch (error?.code) {
    // On iOS, both the first refusal and subsequent attempts return this code.
    // Once refused, iOS requires Settings; the picker checks again on each use.
    'camera_access_denied' =>
      isIOS
          ? 'Camera access is off. Enable it in Settings to take a photo, or choose an existing photo.'
          : 'Camera access was declined. You can try again or choose an existing photo.',
    'camera_access_restricted' => 'Camera access is restricted on this device. You can still choose an existing photo.',
    'photo_access_denied' ||
    'photo_access_restricted' => 'Photo selection is unavailable. Check your device restrictions and try again.',
    'invalid_source' ||
    'no_available_camera' => 'The camera or selected photo is unavailable. Please choose another photo.',
    'invalid_image' =>
      'Some selected photos could not be loaded. Please try different photos or add them one at a time.',
    _ => 'The photo could not be added. Please try again.',
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: cameraDenied && isIOS
          ? SnackBarAction(
              label: 'Open settings',
              onPressed: () => _openSettings(messenger),
            )
          : null,
    ),
  );
}

Future<void> _openSettings(ScaffoldMessengerState messenger) async {
  var opened = false;
  try {
    opened = await _settingsChannel.invokeMethod<bool>('openAppSettings') ?? false;
  } on PlatformException {
    // Keep a manual recovery route if the system cannot open Settings.
  } on MissingPluginException {
    // Also keep recovery usable on hosts without the native settings bridge.
  }
  if (!opened && messenger.mounted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Open your device Settings, find cherry and enable Camera access.'),
      ),
    );
  }
}
