# Ready to collect: reminders and push notifications

The collection dialog now uses buyer order API data through the existing reminder host. It appears on entry or app resume when a stored arrival and collection deadline are available, then hands over to confirmation after customer collection. A separate local preview remains available for design review.

![Ready to collect dialog with sample item details](images/ready-to-collect.png)

## Dependencies and scope

- Frontend PR #564: https://github.com/Cherry-CIC/MVP/pull/564. This branch is based on that PR and reuses its item summary and countdown formatter.
- Backend PR #74: https://github.com/Cherry-CIC/cherry-Backend/pull/74 supplies the confirmation foundation. [Backend PR #75](https://github.com/Cherry-CIC/cherry-Backend/pull/75), stacked on #74, adds arrival, deadline and locker details.
- [Frontend PR #573](https://github.com/Cherry-CIC/MVP/pull/573) covers the pop-up, Home countdown and optional push notifications. The existing confirmation Home timer is preserved. Neither collection PR has been merged or deployed. Backend push registration and sending default to disabled until the release gates below are satisfied.

## Agreed 72-hour rule

On 6 November 2026 the product owner chose a flat 72-hour collection window from recorded locker arrival. `collectionDeadlineFromArrival` normalises the recorded arrival to UTC and adds 72 elapsed hours. The dialog accepts an absolute deadline. It never calculates a new window from the time it opens.

The companion backend persists the arrival and deadline across retries and app launches. The Flutter app reads these values and does not calculate a window when it opens. Keep Sendcloud's update-ordering timestamp separate from the carrier event timestamp. Do not use historical locker-arrival fields without checking their meaning.

InPost documents the usual 72-hour window and an exception for grouped parcels, where the window starts from its notification that everything is ready. The flat rule is an agreed MVP assumption, not a verified per-parcel deadline from Sendcloud. Follow-up integration must document this limitation and allow a future carrier deadline to take precedence.

Sources:
- https://inpost.co.uk/help/how-long-do-i-have-to-pick-up-my-parcel
- https://inpost.co.uk/blog/dont-ghost-your-parcels

## Dialog contract

`ReadyToCollectDialog` takes an `OrderSummary`, an absolute `collectionDeadline`, and optional `canOpenMap` / `canTrackParcel` flags. Both flags default to false. Enable them only when the caller has a real destination and can handle the returned action.

The returned `ReadyToCollectAction` is `openMap`, `trackParcel` or `dismiss`. Back and barrier dismissal return null. A dismissal must not confirm receipt. A map tap is rechecked against the deadline, including between timer ticks.

Before expiry, show Open map when available, otherwise Track parcel when available, plus Not yet. On expiry, replace the countdown with Collection window ended, optionally show Track parcel, and offer I understand. Expiry alone does not claim that the parcel was returned or alter the order status.

The host refreshes on entry/resume and every minute while Home or its dialog is visible. It replaces a changed dialog or removes one after cancellation, return or resolution. Concurrent fetches are guarded and backgrounded responses are invalidated. Collection-ready, collection-expired and confirmation dismissals use separate identities in per-buyer device preferences; legacy confirmation dismissals remain valid.

Map links use only the saved locker address, never the buyer's delivery address. Incomplete addresses hide the map action; a valid HTTPS tracking URL provides a fallback. Links open externally, and a failed launch offers a retry. See [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started). Notification permission is not needed for the in-app flow. Notification taps refresh authenticated order data before presenting a reminder.

Missing carrier arrival/deadline fields suppress the timed collection reminder. No historical arrival backfill or fresh 72-hour window is invented. Expired awaiting-collection orders receive neutral expiry copy, not an assertion that a return has occurred.

## Design and accessibility

Uses the supplied screenshot's bottom card, 24-pixel corners, blurred background, item details, charity logo and pink/grey buttons. The primary button uses the existing darker cherry action colour for white-text contrast. Content scrolls at large text sizes; controls have a minimum height of 48 logical pixels. The countdown has a spoken label and is not a live region. Product and charity images are decorative because the adjacent text supplies the item context.

The local preview uses sample data and bundled images. Its map/tracking actions show a preview message and do not navigate to a real parcel. Rendered images use the bundled Raleway font for reproducibility; the app retains its existing theme typography.

## Review and verification

Validation on 7 November 2026: 90 focused tests passed, including 12 new API/host integration tests; the render check passed for light, expired and dark states. Static analysis passed for all changed Dart files. The widget tests include 320-pixel width at 200% text, spoken countdown labels, tap targets and light/dark contrast. Physical screen-reader use is still outstanding.

The earlier pop-up/timer validation used Flutter 3.44.4 / Dart 3.12.2. Push validation uses the installed Flutter 3.47.9 / Dart 3.13.7. This stage adds `firebase_messaging` 16.3.0 and its platform packages to the lockfile.

Run from the isolated Flutter worktree:

```sh
flutter pub get
flutter test --no-pub test/ready_to_collect_dialog_test.dart
flutter test --no-pub test/delivery_reminder_test.dart test/home_orders_navigation_test.dart test/orders_repository_test.dart test/orders_view_model_test.dart test/orders_widgets_test.dart
flutter test --no-pub tool/render_collection_preview_test.dart
flutter run -d chrome -t tool/ready_to_collect_preview.dart
```

The render tool writes ready, expired and dark previews to `build/collection-preview/`. It makes no network or backend requests.

Live InPost events, external map/tracking launch on devices, physical-device layout, VoiceOver/TalkBack and the full deployed collection-to-confirmation lifecycle still need verification. Foreground push events request an immediate refresh. Without push, foreground state may take up to a minute to refresh after the backend processes an event.


## Home timer (13 November 2026)

After dismissal, Home displays the earliest active collection or confirmation deadline in one tappable pill. Tapping reopens the matching order. Equal deadlines use order ID as a stable tie-breaker. Collection uses the pale-pink stopwatch design and “left to collect”; confirmation retains its existing wording. Dismissal and deadlines survive relaunch without restarting either window.

At zero, the timer disappears and requests fresh order data. Collection or return reported by the API takes precedence over an expiry notice. Background expiry waits for foregrounding before fetching. A failed refresh does not invent a shipment outcome. The timer stays above Home navigation and is hidden on other tabs.

![Home collection timer using sample data](images/collection-home-timer.png)

Validation: all 110 focused Flutter tests pass; static analysis passes for all seven changed Dart files. Six visual previews pass, including light/dark timers and 320-pixel width with 200% text. A width constraint preserves screen margins at large text sizes. Physical-device and live-courier verification remain outstanding. Those results describe the earlier Home timer stage; push validation is recorded below.


## Optional push notifications (13 November 2026)

Settings contains an accessible Collection notifications switch. Permission is requested only after the buyer turns it on. A denied permission, missing APNs token, offline request or disabled backend endpoint never prevents the pop-up or Home timer. The switch explains that in-app reminders always work and presents a retry when registration fails. If permission is later revoked in phone settings, the app removes its registration and explains how to restore permission. Web and desktop do not request push permission.

The app registers `POST /api/notifications/devices` with `{token, platform}` and removes registrations through `DELETE` with `{token}`. Each request captures the current Firebase user and bearer, checks that the session still belongs to that buyer, and never logs tokens. Token refresh removes the old registration. Logout and account deletion revoke before losing authentication and delete the FCM token. If offline cleanup fails, local ownership/rotation markers survive preference clearing; another account cannot register until token rotation succeeds. Settings preferences are per buyer. A notification already accepted by the delivery service can still arrive during logout; the payload is generic and taps never expose another buyer's order.

Both a terminated-app launch (`getInitialMessage`) and a background-app tap (`onMessageOpenedApp`) use a validated inbox. Pending cold-launch intent waits for the matching authenticated buyer. Explicit taps return to Home, refresh the buyer's orders and reopen the target despite a previous dismissal. Current collection, confirmation or expiry state comes from the API. Returned/cancelled/resolved orders are not reopened. Another open reminder is replaced without overlapping dialogs. Failed refreshes retain the intent for retry on resume. Foreground messages refresh the host without requesting another OS banner. The inbox ignores duplicate event hints in the running session.

Native configuration includes Android notification permission and disabled messaging auto-initialisation; iOS includes disabled messaging auto-initialisation, remote-notification/background-fetch modes and an APS entitlement. Flutter generates the Swift package and plugin registration for Firebase Messaging. Existing Firebase method swizzling remains enabled. The Firebase static linkage flags inherit `-ObjC`.

### Release gates and remaining checks

- Deploy and verify the server-only collection exclusions described in [the rules audit](../security/collection-push-rules.md) before enabling registration or sending. The broader existing public database rules remain a separate critical release blocker.
- Verify APNs authentication in Firebase for each shipped iOS app, enable Push Notifications on its Apple App ID, and regenerate signing profiles as needed. The source entitlement is `development`; verify that distribution signing exports the `production` APS entitlement before TestFlight or App Store release.
- Deploy and schedule the backend queue worker, then explicitly enable `COLLECTION_PUSH_ENABLED`. A scheduler or feature flag was not changed by this work. Review [backend PR #75](https://github.com/Cherry-CIC/cherry-Backend/pull/75) for delivery guarantees and its unavoidable send/receipt crash window.
- On physical iOS and Android devices, test permission denied/allowed, token refresh, cold launch and background taps, foreground refresh, offline logout, account switching, and receipt/return before a tap. Verify VoiceOver/TalkBack and live InPost events. Simulator/unit tests do not prove APNs or FCM delivery.

Validation on 14 November 2026: 134 focused Flutter tests pass, including device ownership/session races, opt-in/denial, restored phone permission, disabled registration, token rotation, offline logout markers, notification tap transitions, existing auth/settings behaviour and the existing collection/confirmation suite. Notification settings fit a 320-pixel screen at 200% text. Static analysis passes for all 14 changed/new Dart files, and formatting/whitespace checks pass. Tests use an isolated Flutter 3.47.9 SDK because the shared installation had advanced to 3.50.0 while this worktree's generated package configuration still referenced 3.47.9. Lockfile-enforced dependency resolution passed without additional version changes.

The Android development debug APK and iOS development simulator app both build successfully. Native iOS validation exposed an existing launch scheme issue: `shouldUseLaunchSchemeArgsEnv="YES"` on `LaunchAction` caused recursive argument inheritance and an Xcode stack overflow while querying build settings. Removing that attribute from the development and production launch actions allows both the settings query and simulator build to pass. Test/profile actions still inherit launch arguments. This small native prerequisite is recorded in a separate commit. Simulator compilation does not verify distribution signing or real push delivery.

```sh
flutter test test/collection_push_test.dart test/notification_device_repository_test.dart test/delivery_reminder_test.dart test/auth_view_model_test.dart test/settings_legal_information_test.dart test/ready_to_collect_dialog_test.dart test/collection_timer_bubble_test.dart test/orders_repository_test.dart test/orders_view_model_test.dart test/orders_widgets_test.dart test/home_orders_navigation_test.dart
```

Implementation references: [Firebase Flutter messaging setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) and [message interaction handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).
