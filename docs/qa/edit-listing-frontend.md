# Edit listing: frontend scope and verification

Branch: `cherry/edit-listing-frontend`, based on MVP `00fbc19`.

This change adds UI, client logic, API integration and tests. It does not change or deploy the backend or Firebase rules. Editing is available for listings that pass the client checks below; the backend remains authoritative.

## Editable fields

| Field | Frontend behaviour | Reason |
| --- | --- | --- |
| Title, description | Pre-filled; trimmed; title 3–100 characters; description optional, up to 500 characters | Matches the update API's limits while retaining Give's free-text validation |
| Photos | Retain, add, remove and choose the main photo; at least one required | Reuses the Give picker and Firebase Storage upload service |
| Category, condition, size | Pre-filled where available; existing category selection and Give options | Descriptive fields, subject to backend checkout/history protection |
| Charity, price/donation, postage, quantity | Excluded from the form and update payload | Affect donation destination, payment, fulfilment or stock |
| Owner, ID, likes, timestamps, status | Never submitted as editable fields | Controlled by the backend |

The entry point requires an owned listing, positive stock, and an `active` or `unlisted` status. The repository repeats these checks, loads current data before saving, and rejects stale drafts. UI checks complement server authorisation; they cannot enforce it against a modified client.

## Saving and photos

- Only changed descriptive fields are sent to `PUT /api/products/{id}`. A whole `Product` is never serialised for the update.
- New JPEG, PNG and WebP files upload first to unique `listing-media-v1/{uid}/edit_{random}.{extension}` paths with the owner and media-policy metadata required by the backend. Existing files are never overwritten or deleted, including photos removed from the listing.
- Photo bytes are inspected before upload, with a 10 MiB per-file limit and a maximum of 10 photos. File names are not trusted for format detection.
- Partial upload failure does not send a listing update. Uploaded but unreferenced files may remain, including after cancellation/conflict. Server-side retention and cleanup are prerequisites for release.
- The user cannot submit twice or leave normally while saving. Unsaved changes require confirmation before discarding.
- An uncertain PUT result freezes further saves until an explicit reload. The UI does not claim success without a successful response and canonical readback.
- Both confirmed and uncertain writes invalidate the caller's cached views on return. Upload-only failures preserve the original listing and draft.

## Consistency

Home and search share a cache. After an edit, their results and profile listings are cleared and reloaded; pending older requests cannot restore old cards. Confirmed product and liked-item caches are updated by ID and version. Product routes from Home/search/liked items fetch by ID rather than displaying only the original card snapshot.

Discover currently contains dummy product data and its product rows are hidden. The charity screen has no live product feed. No duplicate product documents or historical orders are written by this feature. Other devices receive changes on their next API read; this is not a real-time cross-device subscription. Already-open feeds retain their normal refresh behaviour, but details and payment are rechecked.

## Proposed backend contract for step two

The backend is authoritative for ownership, listing state, pending payments, sales history, and the allowed editable fields. Deploy and verify the backend listing-edit endpoint before enabling editing in a target environment.
5. Preserve immutable purchased details and media, or reject edits after any unit has been sold. Existing order enrichment reads live product images/size/charity, so merely blocking fully sold stock is insufficient for multi-unit listings. Any order-snapshot API change also needs a later frontend consumer change.
6. Validate media origin/ownership, size/type/count and define safe retention/cleanup. Verify deployed Firestore and Storage rules. The checked-in Firestore rules allow broad access until 2030; deployment state was not verified, and Storage rules are not tracked here. The API checks cannot protect canonical data if direct writes bypass them.

The backend must be deployed and integration-tested before release. The frontend does not use a separate rollout flag; server authorization and the client eligibility checks control the edit entry point.

## Verification

Use the tracked `.env.example` as a local `.env` for test asset bundling. No live account, production listing, upload or payment is needed for automated tests.

```sh
flutter test --no-pub
flutter test --no-pub test/edit_listing_navigation_test.dart
flutter analyze --no-pub
bash tool/check_safe_logging.sh
```

Tests cover owner/state gates, sparse payloads, text/photo validation, protected upload paths and metadata, format/size limits, upload ordering/failure, account changes, stale and uncertain writes, readback, duplicate saves, discard/reload, photo ordering, large text at 320px, cache invalidation and owner navigation.

Results on Flutter 3.44.4 / Dart 3.12.2:

- Full suite: 370 passed, four enabled-feature cases skipped by the default flag, one pre-existing failure in `auth_password_visibility_test.dart` at line 126. That failure was reproduced using an untouched archive of base commit `00fbc19`.
- Separate enabled-feature navigation run: six passed; the default-off assertion was skipped.
- Analysis: 18 pre-existing findings (one warning and 17 informational findings), matching the untouched base; no new findings.
- `flutter build bundle --debug --no-pub`, the safe logging guard and `git diff --check` passed. The bundle check compiles Dart/assets; it does not validate native platform packaging or device behaviour.

Device camera/gallery permissions, real Firebase Storage uploads, backend conditional updates, simultaneous buyer/seller sessions and native payments still require staging/device verification. No production data was changed during this work.
