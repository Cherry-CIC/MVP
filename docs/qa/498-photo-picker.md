# #498: photo picker and camera permissions

Photo-only implementation audit, 13 September 2026. No video or microphone functionality was added. This is a client UI, error-handling and iOS configuration change; upload contracts, image sizing and backend behaviour are unchanged.

## Entry points and changes

| Entry point | Behaviour after this change |
| --- | --- |
| `RegisterPage` → `RegisterForm._pickImage` | Single existing profile photo; now passes `requestFullMetadata: false`. Original image sizing remains unchanged. Cancellation preserves the current photo. Errors, repeated taps and disposal are handled. |
| `DonationPage` → `PhotoUpload` → existing photos | Multiple listing photos; retains `requestFullMetadata: false`, maximum height 1024 and quality 85. Existing representation-error fallback also keeps metadata disabled. |
| `DonationPage` → `PhotoUpload` → take photo | Single photo; same existing sizing and fallback. Camera access occurs only after choosing Take Photo. Denial shows concise recovery guidance; on iOS, Open settings opens cherry's system settings. |

The listing add-more control uses the same `PhotoUpload` flow. Full repository searches found no other picker, capture, video, microphone, permission-request or card-scanning call sites. Image imports in donation models, forms and view models carry photos or select the source; they do not independently open a picker. There was no central picker or system-settings helper to reuse. A small shared snackbar helper keeps errors consistent; picker and upload interfaces remain intact.

Both components ignore late results after disposal and prevent overlapping picker flows. The listing source sheet also guards repeated option taps. Cancellation neither changes the images nor displays a failure. No permission state is cached and there are no new loading indicators to strand.

## Permission model and dependencies

Locked packages: `image_picker 1.2.2`, `image_picker_android 0.8.13+19`, `image_picker_ios 0.8.13+6`, `image_picker_platform_interface 2.11.1`. No runtime permission dependency was added. The existing platform interface is now an explicit development dependency for platform-fake widget tests; its version is unchanged.

- iOS minimum deployment target is 15.0. The installed plugin uses PHPicker for existing photos. Disabling full metadata avoids requesting photo-library authorisation.
- Android's installed plugin defaults `useAndroidPhotoPicker` to false and uses the system `ACTION_GET_CONTENT` picker with an image filter. cherry does not explicitly enable `PickVisualMedia`. This system selection path grants access to chosen content without broad storage/media permissions.
- Android capture delegates to the system camera with `ACTION_IMAGE_CAPTURE`. The plugin only requests cherry-owned CAMERA permission if it is declared in the merged manifest. It is absent and unnecessary for this integration.
- iOS capture checks current `AVCaptureDevice` authorisation on every camera attempt and requests access only if undetermined. Both the first refusal and subsequent refusals produce `camera_access_denied`; after refusal, Settings is required. `camera_access_restricted` is handled separately without promising that Settings can remove a device restriction.
- The iOS settings channel only opens Settings after the user presses the snackbar action. It requests no permissions. Failure to open Settings leaves manual instructions. After enabling Camera and returning, the next picker attempt checks the platform's current state.

These conclusions use the locked packages' native source, including `ImagePickerUtils.java`, `ImagePickerDelegate.java` and `FLTImagePickerPlugin.m`. The [image_picker 1.2.2 documentation](https://pub.dev/packages/image_picker/versions/1.2.2) requires the iOS photo-library purpose string even when full metadata is disabled. That declaration does not itself request access. The settings action uses Apple's [openSettingsURLString](https://developer.apple.com/documentation/uikit/uiapplication/opensettingsurlstring).

## Platform declarations

All Runner build configurations use `Runner/Info.plist`. Release target build settings confirm `INFOPLIST_FILE = Runner/Info.plist`, `GENERATE_INFOPLIST_FILE = NO` and `INFOPLIST_PREPROCESS = NO`. No additional usage-description overrides were found.

| iOS declaration | Value |
| --- | --- |
| `NSCameraUsageDescription` | cherry uses your camera so you can take photos to add to cherry. |
| `NSPhotoLibraryUsageDescription` | cherry uses the photos you choose for your listings and profile. |
| `NSMicrophoneUsageDescription` | Absent. |
| `NSPhotoLibraryAddUsageDescription` | Absent. |

The camera text replaces the inaccurate card-scanning explanation. No microphone declaration existed to remove. No unrelated active microphone feature was found.

Android main, debug and profile manifest sources and the generated Release merge were inspected. The effective manifest is generated at `build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`; provenance is in `build/app/outputs/logs/manifest-merger-release-report.txt`.

The Release merge contains **none** of CAMERA, RECORD_AUDIO, READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, READ_MEDIA_AUDIO, READ_MEDIA_VISUAL_USER_SELECTED, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE or MANAGE_EXTERNAL_STORAGE. No Android source change or manifest-removal override is needed.

Remaining merged permissions are listed below. These originate from existing dependencies and were preserved; no media permission was retained for another feature.

| Permission | Merge provenance |
| --- | --- |
| `android.permission.INTERNET` | Google sign-in, Firebase and other network dependencies |
| `android.permission.ACCESS_NETWORK_STATE` | Existing network dependencies |
| `android.permission.USE_BIOMETRIC`, `android.permission.USE_FINGERPRINT` | AndroidX biometric through payment dependencies |
| `android.permission.WAKE_LOCK`, `com.google.android.c2dm.permission.RECEIVE` | Firebase IID / Google Play cloud messaging dependencies |
| `com.google.android.providers.gsf.permission.READ_GSERVICES` | reCAPTCHA |
| `uk.org.cherry.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX Core; app-specific signature permission |

## Automated verification

- `flutter pub get --offline`: passed using cached packages; no runtime package upgrades.
- `dart format` on the changed Dart files and `git diff --check`: passed.
- `flutter test --no-pub test/photo_picker_test.dart`: all 20 focused widget tests passed. Cover selection options, image preservation, cancellation, denial, settings and settings-opening failures, fresh retries, gallery after denial, repeated taps, disposal and the existing transform fallback. Platform UI is simulated, not exercised by these tests.
- `flutter analyze --no-pub`: passed with no issues. The first run identified the absent local `.env`; a later test-only unused import was removed before the clean final run.
- `flutter test --no-pub`: all 178 tests passed in the final full-suite run.
- Gradle 8.14.5, `--offline :app:processReleaseMainManifest` from `android`: passed. Invoked the locally cached Gradle executable because this checkout does not contain `gradlew`. Existing plugin deprecation/Kotlin warnings remain.
- Parsed the generated Android XML and asserted the unwanted permissions above are absent: passed.
- `plutil -lint ios/Runner/Info.plist`: passed. Parsed privacy declarations and asserted microphone and photo-library-add keys are absent.
- `xcodebuild -project ios/Runner.xcodeproj -target Runner -configuration Release -sdk iphoneos -showBuildSettings`: passed. Scheme-based inspection first reported no destinations; direct target inspection succeeded.
- `xcrun swiftc -typecheck -parse-as-library`, targeting arm64 iOS 15 with the installed iOS SDK, Flutter release framework and Runner bridging header: passed for `AppDelegate.swift`.
- Unsigned iOS Release build: **blocked by missing CocoaPods file lists in this checkout**. No completed iOS bundle or archive was produced, so final bundled privacy declarations remain to be checked after CocoaPods installation. No APK/AAB was built; Android verification covers the actual Release manifest merge.

The ignored `.env` used for local checks was copied from `.env.example`; no production credentials were introduced.

## Remaining device and release checks

Run on a physical iPhone and Android phone. Include an older supported Android version and Android 13 or later when available. Record device/OS, build and actual results.

1. Fresh install: open registration, then listing; merely rendering either form must show no permission prompt. Select an existing photo in each flow, verify preview, and complete the existing upload flow with a test account. No camera, microphone or broad library prompt should appear.
2. Cancel registration and listing pickers, including when a photo already exists. Confirm existing photos and form inputs remain, no error appears, and another selection succeeds. Dismiss the listing source sheet without choosing an option too.
3. Choose Take Photo explicitly. On fresh iOS installation, grant Camera and capture a photo; verify preview/upload. On Android, verify the system camera opens without a cherry-owned Camera permission prompt. Any camera-app permission prompt belongs to that app. Neither flow should request microphone access.
4. On iOS, deny Camera, then retry. Both attempts must show recovery guidance without repeated OS prompts or a stuck form. Confirm gallery selection still succeeds. Test a device restriction if available; the message must not offer an ineffective Settings action.
5. From denied iOS capture, press Open settings, enable Camera, return to cherry and try again. Confirm capture succeeds without restarting. Repeat after externally revoking Camera. If Settings cannot open, verify the manual instructions remain usable.
6. On Android, test cancellation and unavailable/restricted system-camera behaviour, then select an existing photo. cherry has no app-owned camera denial/permanent-denial state in this configuration, so iOS-style cherry permission toggles do not apply.
7. Rapidly tap source controls and picker controls. Navigate away while picking; cancel or select afterwards. Confirm there are no extra pickers, unexpected route pops, crashes or stale updates.
8. Check JPEG/PNG and a real-device HEIC image, multiple listing photos, add-more, removal and the existing image conversion fallback. No action should request microphone access.
9. With CocoaPods installed, build the intended iOS Release archive and inspect the app bundle's Info.plist for exactly the privacy strings above and no microphone key. Recheck the final packaged Android APK/AAB permissions, particularly after any dependency change.
10. Before submission, check the actual App Store privacy answers, Play Data Safety answers and published privacy policy against photo/profile uploads and current services. These external declarations were not inspected or edited here. This implementation and audit do not constitute store approval.

Android process-death recovery using `retrieveLostData` remains an existing limitation. No draft persistence or upload redesign was introduced in this permission-focused change.
