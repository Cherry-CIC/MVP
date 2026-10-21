# Listing deletion and owner menus

Branch: `cherry/listing-deletion-menu`, based on frontend `ccb66a3`.

This change adds frontend UI, client logic, API integration and tests. It does not deploy backend changes. Deletion depends on [backend PR #69](https://github.com/Cherry-CIC/cherry-Backend/pull/69), inspected at `8843334`. That PR was still open and draft on 21 October 2026; deployed staging acceptance has not been verified.

## Owner experience

- A three-dot menu sits eight logical pixels from the top-right of each photo in the signed-in owner's profile listings. It has a contrasting theme surface, a 48-by-48 target and an accessible tooltip, such as “Manage Blue jacket”. Tapping the card still opens its details.
- The same menu sits at the top-right of the listing details. It replaces the previous bottom Edit listing button. Non-owners retain the existing report/block menu.
- Edit listing uses the existing editor and eligibility checks: owner, positive stock, and active or unlisted status. The latest main branch has no separate edit feature flag; this change does not introduce one.
- Delete listing appears only when deletion is enabled, ownership is known and the listing is not known to be sold or out of stock. The backend remains authoritative for all eligibility checks. Empty menus are hidden.
- Confirmation offers Cancel and Delete listing. During a request, the dialogue shows progress and disables both buttons and normal Back dismissal. Duplicate requests for the same listing are prevented across callers.
- Confirmed deletion shows “Listing deleted”. From an owner's profile detail route, Back returns to that existing profile. From another entry point, the detail route is replaced with the owner's profile. A card deletion stays on the profile.
- Large text switches the owner-card layout to one column. The dialogue scrolls and action buttons can wrap vertically. Native VoiceOver/TalkBack verification remains outstanding.

## API and failure handling

The existing ProductRepository and DioApiService send `DELETE /api/products/{id}` with a Firebase ID token, no request body and no edit version. Success requires HTTP 200 and `success: true`; `data: null` is valid. Status and the top-level backend `code` are retained, without showing raw backend error text.

| Response | Behaviour |
| --- | --- |
| 401 | Offers Sign in through the existing login route. Deletion is not retried automatically. |
| 403 LISTING_NOT_OWNER | Explains ownership, immediately refreshes details and the owner's list. Direct Product arguments from Home/Liked also reload by ID. |
| 404 LISTING_NOT_FOUND | Removes the stale entry and shows “This listing is no longer available.” |
| 409 LISTING_PAYMENT_PENDING | Explains that a payment is in progress; offers a deliberate retry. |
| 409 LISTING_HAS_SALES | Explains the purchase-record restriction. |
| 409 LISTING_REVIEW_REQUIRED | Explains that review is required. |
| Network error, timeout, 5xx, unexpected status/envelope/code | Says deletion could not be confirmed; offers a deliberate retry. |

A retry can succeed after the original request timed out because the backend keeps an owner deletion receipt. A GET 404 is not treated as proof of deletion: moderated or hidden listings can also produce it. There is no optimistic removal or Undo action.

The shared DELETE transport now fails closed when authentication is absent, token retrieval fails or the account changes before dispatch. This also applies to the existing account-deletion endpoint. GET retains its existing retry policy; DELETE is never automatically retried.

## Local state and account safety

`DeletedListings` stores confirmed removed IDs for the app session. Product details, selected products, home/feed, search, owner listings, public seller listings and liked-item state filter against it. It also filters late reads, pagination, like updates and edit updates, so stale responses cannot restore a removed card.

Confirmed deletion and structured DELETE-not-found responses trigger removal before background refresh. Surviving profile/home cards are retained on refresh failure; the profile offers Refresh again. Details caches are invalidated and reopened deleted routes show unavailable. Tombstones survive sign-out within the app process; they are not persisted to disk, and this is not a cross-device subscription.

The deletion flow captures account identity and a session revision before confirmation. It rechecks after the response. Signing out, switching accounts or switching away and back prevents an earlier result from changing the current account's lists or navigating it. Profile requests are invalidated on authentication changes, and asynchronous listeners are detached on disposal.

Firestore documents, Storage objects, likes and cleanup jobs are never deleted directly by this feature. A success message says only that the listing was deleted; backend photo cleanup may happen later. Checkout, historical orders and backend retention rules remain backend responsibilities.

## Rollout gate

`FeatureFlags.enableListingDeletion` defaults to false. Ordinary builds show Edit where available and hide Delete. The controller also refuses deletion while the flag is off. Deletion is independent of editing.

For a dedicated staging build, after confirming its API and Firebase configuration, supply `--dart-define=ENABLE_LISTING_DELETION=true`. Do not add this define to production distribution until backend deployment and the staging checks below are complete. No deployment or production setting was changed during this task.

Before release, also verify editing against the deployed backend: current frontend photo uploads use `products/{uid}/edit_…`, while the backend PR describes a newer media policy. This pre-existing compatibility difference was not changed by the deletion task.

## Automated verification

Flutter 3.44.4 / Dart 3.12.2. A local copy of `.env.example` supplies test asset bundling; no live listing, payment or upload is used. `flutter pub get` resolves the local SDK's transitive packages; the tracked dependency files are unchanged.

- 142 focused tests passed across API/repository, deletion controller/dialogue, cache races, owner-card/detail navigation, existing edits, profile cards, Home navigation and Liked items.
- Full suite: 517 passed, 14 failed. All 14 failures also occur in an untouched archive of base `ccb66a3`; the base has 396 passes and 18 failures. Remaining failures are one Create Account password-layout test, four public-profile navigation tests and nine public-profile widget tests. Public-profile tests lack the FirebaseAuth provider required by the existing safety menu. This is not a clean full-suite result.
- `flutter analyze --no-pub` reports the same 19 baseline findings, with no new findings: one warning and 18 informational findings.
- `flutter build bundle --debug --no-pub`, the safe logging guard and `git diff --check` passed. The bundle check compiles Dart and assets; it does not validate native packaging or device behaviour.

Useful commands:

```sh
flutter test --no-pub test/delete_listing_view_model_test.dart test/delete_listing_dialog_test.dart test/listing_actions_integration_test.dart test/deleted_listing_caches_test.dart test/product_deletion_repository_test.dart test/core/services/network/api_service_delete_test.dart
flutter test --no-pub
flutter analyze --no-pub
bash tool/check_safe_logging.sh
```

## Staging checks still required

Use disposable staging listings and two test accounts after the backend deployment:

1. Confirm owner/non-owner visibility, cancellation and one active request under rapid taps on cards and details.
2. Delete an eligible listing, check the 200/null response and return to the owner's listings. Confirm feed, search, liked items and public profile no longer show it.
3. Exercise every structured error above, including a listing sold or entering payment while the confirmation is open.
4. Drop the first response after the backend commits, then retry with the original owner. Check the receipt response and separately check expired/missing receipts.
5. Delay list/pagination responses across deletion and fail refresh afterwards. Confirm the item stays absent and Refresh again works.
6. Sign out or switch accounts during confirmation, token retrieval and the request, including switching away and back. Confirm there is no stale notification, navigation or list mutation.
7. Verify focus order, announcements, touch targets and large text with VoiceOver and TalkBack, in light and dark themes.
8. Recheck browsing, likes, editing, account deletion and checkout against the deployed backend. Confirm cleanup is recorded server-side without claiming immediate media erasure.

Native builds, device accessibility and the complete deployed staging flow have not been verified. Keep deletion disabled until those checks pass.
