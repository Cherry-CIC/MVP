# Edit listing: frontend scope and verification

Branch: `cherry/edit-listing-frontend`, based on MVP `00fbc19`.

This change adds UI, client logic, API integration and tests. It does not change or deploy the backend or Firebase rules. **Editing is disabled by default and is not ready to enable against the existing live backend.**

## Editable fields

| Field | Frontend behaviour | Reason |
| --- | --- | --- |
| Title, description | Pre-filled; trimmed; title 3–100 characters; description optional, up to 500 characters | Matches the update API's limits while retaining Give's free-text validation |
| Photos | Retain, add, remove and choose the main photo; at least one required | Reuses the Give picker and Firebase Storage upload service |
| Category, condition, size | Pre-filled where available; existing category selection and Give options | Descriptive fields, subject to backend checkout/history protection |
| Charity, price/donation, postage, quantity | Excluded from the form and update payload | Affect donation destination, payment, fulfilment or stock |
| Owner, ID, likes, timestamps, status | Never submitted as editable fields | Controlled by the backend |

The entry point requires an owned listing, positive stock, an `active` or `unlisted` status and an integer `editVersion`. Missing/unknown status or version prevents editing. The repository repeats these checks, loads current data before saving, and rejects stale drafts. UI checks complement server authorisation; they cannot enforce it against a modified client.

## Saving and photos

- Only changed descriptive fields are sent to `PUT /api/products/{id}`. A whole `Product` is never serialised for the update.
- New files upload first to unique `products/{uid}/edit_{random}.{extension}` paths. Existing files are never overwritten or deleted, including photos removed from the listing.
- Partial upload failure does not send a listing update. Uploaded but unreferenced files may remain, including after cancellation/conflict. Server-side retention and cleanup are prerequisites for release.
- The user cannot submit twice or leave normally while saving. Unsaved changes require confirmation before discarding.
- An uncertain PUT result freezes further saves until an explicit reload. The UI does not claim success without a successful response, an advanced version and canonical readback.
- Both confirmed and uncertain writes invalidate the caller's cached views on return. Upload-only failures preserve the original listing and draft.

## Consistency and buying

Home and search share a cache. After an edit, their results and profile listings are cleared and reloaded; pending older requests cannot restore old cards. Confirmed product and liked-item caches are updated by ID and version. Product routes from Home/search/liked items fetch by ID rather than displaying only the original card snapshot.

Buy now re-fetches the listing. Changed details are shown for review and require another explicit Buy now. Checkout checks again before requesting a payment intent. A changed or unavailable item is removed from the basket and payment is stopped. Lookup failures also stop payment. Versioned items include `expectedEditVersion` in the payment-intent request. This reduces stale client behaviour; only the backend can close the race between checking and charging.

Discover currently contains dummy product data and its product rows are hidden. The charity screen has no live product feed. No duplicate product documents or historical orders are written by this feature. Other devices receive changes on their next API read; this is not a real-time cross-device subscription. Already-open feeds retain their normal refresh behaviour, but details and payment are rechecked.

## Proposed backend contract for step two

The current backend inspected at `eedbbb6` has an ordinary update endpoint. It strips unknown update fields, so it would ignore `expectedEditVersion`. It does not yet provide the safeguards below. **Do not expose `editVersion` as an early migration or enable the frontend flag before these requirements are met.**

1. Return a non-negative integer `editVersion` and lifecycle `status` on canonical product reads. Return versions consistently on feed/liked reads too. Advance the version for descriptive and availability changes; likes need not change it.
2. Require `expectedEditVersion` on editing requests. In one atomic operation, verify authenticated ownership, allowed fields, current version, stock/lifecycle and checkout eligibility; update and increment the version. Reject stale/blocked edits without modifying anything. Unknown fields must not bypass safeguards.
3. Successful PUT responses must include `success: true`, `data.id` and the new `data.editVersion`. Canonical readback must expose that version or a later one. The client sends, for example, `{ "name": "Blue wool jumper", "expectedEditVersion": 4 }`.
4. Bind payment intent creation to the buyer-reviewed version and coordinate edits with in-progress payments before a charge can occur. Cover legacy clients and direct API calls. The new client sends the same `expectedEditVersion` field to `/api/payment/create-payment-intent` when a version is present.
5. Preserve immutable purchased details and media, or reject edits after any unit has been sold. Existing order enrichment reads live product images/size/charity, so merely blocking fully sold stock is insufficient for multi-unit listings. Any order-snapshot API change also needs a later frontend consumer change.
6. Validate media origin/ownership, size/type/count and define safe retention/cleanup. Verify deployed Firestore and Storage rules. The checked-in Firestore rules allow broad access until 2030; deployment state was not verified, and Storage rules are not tracked here. The API checks cannot protect canonical data if direct writes bypass them.

Only after backend integration tests pass should a separate reviewed release enable `--dart-define=ENABLE_LISTING_EDIT=true`. The default-off flag and required server version deliberately make this frontend branch safe to stage separately. Even with the flag enabled, today's unversioned backend cannot trigger uploads or PUTs through the editor.

## Verification

Use the tracked `.env.example` as a local `.env` for test asset bundling. No live account, production listing, upload or payment is needed for automated tests.

```sh
flutter test --no-pub
flutter test --no-pub --dart-define=ENABLE_LISTING_EDIT=true test/edit_listing_navigation_test.dart
flutter analyze --no-pub
bash tool/check_safe_logging.sh
```

Tests cover the release/version/owner/state gates, sparse payloads, text/photo validation, upload ordering/failure, account changes, stale and uncertain writes, readback, duplicate saves, discard/reload, photo ordering, large text at 320px, cache invalidation, owner navigation, buyer review and checkout freshness/selection races.

Results on Flutter 3.44.4 / Dart 3.12.2:

- Full suite: 370 passed, four enabled-feature cases skipped by the default flag, one pre-existing failure in `auth_password_visibility_test.dart` at line 126. That failure was reproduced using an untouched archive of base commit `00fbc19`.
- Separate enabled-feature navigation run: six passed; the default-off assertion was skipped.
- Analysis: 18 pre-existing findings (one warning and 17 informational findings), matching the untouched base; no new findings.
- `flutter build bundle --debug --no-pub`, the safe logging guard and `git diff --check` passed. The bundle check compiles Dart/assets; it does not validate native platform packaging or device behaviour.

Device camera/gallery permissions, real Firebase Storage uploads, backend conditional updates, simultaneous buyer/seller sessions and native payments still require staging/device verification. No production data was changed during this work.
