# Issue #492: post-upload navigation

The existing upload confirmation sent users to a new Home shell. Home excludes their own listings. The form also handled submission success in both its submit callback and a callback scheduled during widget builds.

The confirmation screen is retained. Continue or system Back now closes it, completes the upload route with a successful result, and returns to the existing Profile listings experience. The completed upload cannot be reopened with Back. This is a navigation and state-handling change; media upload, API persistence and submission logging remain unchanged.

## Navigation and data flow

- Give from Home selects Profile using HomePage's existing PageController and bottom-navigation handler. This also exits the Orders section if it was open.
- Give from Profile's empty listings state stays on Profile and refreshes listings.
- Give from Liked returns to the existing Profile and refreshes listings.
- Listings are part of Profile's default view, so there is no separate listings route or tab to select.
- The form handles completion once. Repeated Submit and Continue actions are guarded. Failure retains the form and shows its error once.
- A successful submission closes any selection screen covering the upload. A dismissed upload does not redirect after its request finishes.

Profile loads listings from the existing authenticated `/api/products/my-products` endpoint. Creation does not insert the response into that view model. The existing refresh operation is therefore reused. Explicit refresh now supersedes an older first-page request, so a pre-upload response cannot overwrite the post-upload list. No extra writes, delays, data cache or routing package were added.

## Files changed

- `lib/features/donation/widgets/donation_form.dart`: one guarded completion handler and upload-route result.
- `lib/features/donation/donation_view_model.dart`: await dismissal of the existing confirmation route.
- `lib/features/donation/successful_upload_page.dart`: return to the upload completion handler instead of clearing navigation to Home.
- `lib/features/home/home_page.dart`: select Profile after successful Give completion.
- `lib/features/profile/profile_page.dart`: refresh after the named upload route completes successfully.
- `lib/features/liked_items/liked_items_page.dart`: return to Profile and refresh after successful Give completion.
- `lib/features/profile/profile_listings_view_model.dart`: let explicit refresh supersede stale requests.
- `test/donation_navigation_test.dart`: submission, failure, duplicate action, dismissal and back-navigation coverage.
- `test/home_orders_navigation_test.dart`: destination selection, existing shell, named upload entry and listing visibility.
- `test/liked_items_page_test.dart`: successful and cancelled Give completion from Liked.
- `test/profile_listings_view_model_test.dart`: both completion orders for overlapping initial-load and refresh requests.

## Verification

Executed with Flutter 3.44.4 and Dart 3.12.2:

- `flutter test --no-pub`: all 202 tests passed.
- `dart format --output=none --set-exit-if-changed` on all changed Dart files: passed.
- `bash tool/check_safe_logging.sh`: passed.
- `git diff --check`: passed.
- `flutter analyze --no-pub`: 18 existing diagnostics remain, comprising one warning and 17 informational lints. Comparison with the unchanged source confirms no new diagnostics.

The installed SDK resolved four SDK-pinned transitive packages to older versions than the checked-in lockfile during local setup. The lockfile was restored unchanged; no dependency change is part of this fix.

## Live verification still required

Device testing and uploads against the live backend were not performed. Automated tests use controlled repository responses, so they do not prove backend read-after-write consistency or listing ordering.

On a test account, post from Home, Profile and Liked. Use Continue or system Back on the existing confirmation. Confirm Profile is selected, the new item appears in Listings, and Back does not reopen the completed upload. Also check a failed upload retains the form and that a slow listings request cannot replace the refreshed list with old data.

If the listings API fails after a successful upload, its existing error/retry behaviour still applies. This change does not claim offline visibility of newly created listings.
