# Ready to collect: pop-up stage

This change implements the collection dialog and a local preview. It does not yet show the dialog automatically for real orders. It is deliberately separate from the existing post-collection confirmation host.

![Ready to collect dialog with sample item details](images/ready-to-collect.png)

## Dependencies and scope

- Frontend PR #564: https://github.com/Cherry-CIC/MVP/pull/564. This branch is based on that PR and reuses its item summary and countdown formatter.
- Backend PR #74: https://github.com/Cherry-CIC/cherry-Backend/pull/74. Later collection integration must retain its separate collection and confirmation states and timestamp ordering.
- This draft covers the first UI stage. Backend storage, live eligibility, Home countdown, dismissal persistence between stages, push notifications and the collection-to-confirmation handover remain later work. No backend change or deployment is included.

## Agreed 72-hour rule

On 6 November 2026 the product owner chose a flat 72-hour collection window from recorded locker arrival. `collectionDeadlineFromArrival` normalises the recorded arrival to UTC and adds 72 elapsed hours. The dialog accepts an absolute deadline. It never calculates a new window from the time it opens.

The eventual backend must persist the arrival and deadline and preserve them across retries and app launches. Keep Sendcloud's update-ordering timestamp separate from the carrier event timestamp. Do not use historical locker-arrival fields without checking their meaning.

InPost documents the usual 72-hour window and an exception for grouped parcels, where the window starts from its notification that everything is ready. The flat rule is an agreed MVP assumption, not a verified per-parcel deadline from Sendcloud. Follow-up integration must document this limitation and allow a future carrier deadline to take precedence.

Sources:
- https://inpost.co.uk/help/how-long-do-i-have-to-pick-up-my-parcel
- https://inpost.co.uk/blog/dont-ghost-your-parcels

## Dialog contract

`ReadyToCollectDialog` takes an `OrderSummary`, an absolute `collectionDeadline`, and optional `canOpenMap` / `canTrackParcel` flags. Both flags default to false. Enable them only when the caller has a real destination and can handle the returned action.

The returned `ReadyToCollectAction` is `openMap`, `trackParcel` or `dismiss`. Back and barrier dismissal return null. A dismissal must not confirm receipt. A map tap is rechecked against the deadline, including between timer ticks.

Before expiry, show Open map when available, otherwise Track parcel when available, plus Not yet. On expiry, replace the countdown with Collection window ended, optionally show Track parcel, and offer I understand. Expiry alone does not claim that the parcel was returned or alter the order status.

The parent remains responsible for refreshing order state and removing or replacing an open dialog after collection, cancellation or return. A notification tap must refresh current state before presenting the dialog. Collection dismissal must not hide the later confirmation reminder.

## Design and accessibility

Uses the supplied screenshot's bottom card, 24-pixel corners, blurred background, item details, charity logo and pink/grey buttons. The primary button uses the existing darker cherry action colour for white-text contrast. Content scrolls at large text sizes; controls have a minimum height of 48 logical pixels. The countdown has a spoken label and is not a live region. Product and charity images are decorative because the adjacent text supplies the item context.

The local preview uses sample data and bundled images. Its map/tracking actions show a preview message and do not navigate to a real parcel. Rendered images use the bundled Raleway font for reproducibility; the app retains its existing theme typography.

## Review and verification

Validation on 6 November 2026: 78 focused tests passed (14 new collection tests and 64 existing order/confirmation tests); the render check passed for light, expired and dark states. Static analysis passed for all changed Dart files. The widget tests include 320-pixel width at 200% text, spoken countdown labels, tap targets and light/dark contrast. Physical screen-reader use is still outstanding.

Local validation used Flutter 3.44.4 / Dart 3.12.2. Offline dependency resolution adjusted four transitive test dependencies for this installed SDK; the repository lockfile was restored and no dependency changes are included.

Run from the isolated Flutter worktree:

```sh
flutter pub get
flutter test --no-pub test/ready_to_collect_dialog_test.dart
flutter test --no-pub test/delivery_reminder_test.dart test/home_orders_navigation_test.dart test/orders_repository_test.dart test/orders_view_model_test.dart test/orders_widgets_test.dart
flutter test --no-pub tool/render_collection_preview_test.dart
flutter run -d chrome -t tool/ready_to_collect_preview.dart
```

The render tool writes ready, expired and dark previews to `build/collection-preview/`. It makes no network or backend requests.

Live InPost events, map navigation, push delivery, physical-device layout, VoiceOver/TalkBack and the complete collection-to-confirmation lifecycle still need verification during integration.
