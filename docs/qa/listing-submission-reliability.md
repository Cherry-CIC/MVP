# Listing submission reliability

This frontend state-management and navigation change gives each accepted listing submission one completion owner. It preserves the request fields, validation, pricing, repository, upload service and backend behaviour.

The work starts from main at `b72fca0`, on `cherry/reliable-listing-submission`. PR #489 was checked on 8 September 2026 and remained open. Its checkout changes are not included.

Previously, submission and postage requests shared one status. Postage notifications could change the submission spinner, overlapping calls could reach the repository, and both a build callback and the Submit callback handled completion. Forms also accepted asynchronous selector and picker results after disposal.

| File | Responsibility after the change |
| --- | --- |
| `lib/features/donation/donation_view_model.dart` | Owns independent `submissionStatus` and `postageStatus`, plus an independent submission lock. Returns `null` to ignored overlapping callers and a request-specific result to the accepted caller. Copies both image lists before notifying listeners. Releases the lock in `finally`. |
| `lib/features/donation/widgets/donation_form.dart` | The awaited Submit handler alone handles UI completion. Captures submission values and rejects stale selector results. Successful current forms are replaced by the existing success route. Failed forms retain their draft and permit deliberate retry. |
| `lib/features/donation/donation_page.dart` | Owns selected photos, disables Close, and registers a route pop guard that updates synchronously when submission starts. This blocks normal Back even before the next rebuild. |
| `lib/features/donation/postage_size_page.dart` | Uses only postage state for loading, errors, retry and selection. |
| `lib/features/donation/widgets/donation_form_field.dart`, `donation_dropdown_field.dart` | Allow form controls to be disabled while submitting. |
| `lib/features/donation/widgets/photo_upload.dart` | Preserves photo state, copies lists across widget boundaries, disables photo controls and ignores obsolete picker results. Checks lifecycle before callbacks and page animations. |
| `lib/features/donation/widgets/photo_tips_bar.dart` | Prevents the tips dialog from covering an active submission. |
| `lib/core/services/safe_log.dart` | Adds a typed donor-discount persistence failure event without payloads or raw exceptions. |

The application-scoped view model remains the submission boundary. Closing or disposing a form never resets that lock and does not cancel the upload or backend request. No form reads stored success as a navigation event, so reopening cannot replay an earlier completion.

The initiating form keeps its own completion guard until failure or route replacement. Give and Liked Items use fullscreen dialog routes; Profile uses the named donations route. All three replace their exact form route on success, disposing both the form and its photos. Back from success cannot reveal the submitted draft.

Forced navigation is handled separately from normal Close and Back. A disposed or already popped form performs no UI completion. If a newer route covers a still-active form, success removes only the old form beneath it, without opening success over the newer page. Failure leaves the original draft editable and suppresses the obsolete toast. The newer route remains current in both cases.

Failure preserves title, description, price, category, charity, quality, size, postage and photos. No automatic retry is introduced. The caller chooses when to try again. Accepted image lists are immutable copies, while the retained draft remains editable after failure.

Donor-discount persistence still runs only when `FeatureFlags.showDonorDiscounts` is enabled. Its captured value is passed to the accepted operation, which holds the lock until this local follow-up finishes. A persistence exception logs a typed warning and leaves listing creation successful. The flag remains false in the application.

Verification uses `ControlledDonationRepository` and `Completer` responses. There are no real listing creations or uploads. Tests exercise the real Home/Give, Profile and Liked Items controls and Navigator stacks. Category and charity selection futures are controlled in the fixture; postage-page routes are also exercised directly. Photo-picker results use a mocked method channel and local image fixtures.

| Automated coverage | Test file |
| --- | --- |
| Overlap rejection; postage success, failure and exceptions during submission; failure and exception retry; immutable image snapshots; disposed view-model completion; donor-discount persistence and its failure | `test/donation_view_model_test.dart` |
| Rapid taps before rebuild; one success replacement across all three entry points; full draft preservation and retry; immediate Close/Back/tips guards; forced disposal, exit animations, covering routes and reopening; late category, charity, postage and gallery results; unchanged invalid-form checks; postage loading, retry, initial choice, selection and empty state | `test/donation_submission_widgets_test.dart` |
| Existing postage-ID request serialisation contract | `test/donation_model_test.dart` |

The verified SDK is Flutter 3.44.4 with Dart 3.12.2 at `/Users/bradleyvenn/Documents/cherry/flutter`. Dependencies were resolved with `flutter pub get --enforce-lockfile`; `pubspec.lock` did not change. Main's baseline passed 158 tests and had no analyser issues. An empty, temporary `.env` asset was used for tests and removed afterwards.

Final checks:

- Targeted donation tests: 34 passed, including 33 new regression cases and the existing model test.
- `flutter test --no-pub`: 191 passed.
- `flutter analyze --no-pub`: no issues found.
- `bash tool/check_safe_logging.sh`: passed.
- `git diff --check`: passed.
- Changed Dart files formatted; a second format check made no changes.

This prevents overlapping submissions through the shared frontend view model. It does not guarantee exactly-once creation across an ambiguous network response, process termination, another app instance or multiple devices. A deliberate retry after an ambiguous failure can still create a duplicate. Server-side idempotency remains outside this change.

Native Android/iOS camera and gallery permission flows, native image conversion, predictive-back gestures on a device, real uploads, backend behaviour and the enabled donor-discount UI have not been exercised. The gallery callback lifecycle and donor-discount persistence branch are covered with fakes. A hung request continues to hold the lock until its existing repository/network behaviour completes; no cancellation or new timeout policy is introduced.
