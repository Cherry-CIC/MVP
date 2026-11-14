# Category search

## Behaviour

Opening the home search bar shows Charities and the current categories from the same API used when listing an item. Categories refresh each time search opens. Their IDs and names come from the catalogue. Incomplete records are skipped individually. Charities opens the existing Discover page.

The keyboard opens with the field. Dragging the list dismisses it without closing search. The back arrow exits search and clears its state. Deleting the last character returns to categories unless a category is selected. Clearing the text retains a selected category. Clearing the category retains any text. Opening a listing and returning preserves the search.

Text is trimmed and sent after a 400 ms typing delay. Submitting runs immediately. Category selection queries immediately. Changing text or category invalidates older requests before the next response can update the screen. Failures show retry actions. Pagination retains its category and query, with an explicit Load more results action.

## Search contract and limits

The existing product endpoint accepts `search`, `categoryId`, `limit` and `cursor`. This change adds category IDs to the frontend request. The backend currently matches a case-insensitive, contiguous phrase against the combined item name, description, size and quality. Results are newest first, with document ID breaking timestamp ties. Available marketplace results exclude sold, unlisted and moderation-hidden items.

This is MVP item search. It does not provide member search, camera search, AI interpretation, spelling correction, relevance ranking or arbitrary word-order matching. The previous AI placeholder has been replaced with Search items. The backend scans batches until it fills a page or exhausts matching database records, so rare terms can incur many reads as the catalogue grows. An indexed text-search service is a separate scalability decision.

## Release dependency

Deploy [backend PR #78](https://github.com/Cherry-CIC/cherry-Backend/pull/78) and add the products composite index on `categoryId ASC`, `createdAt DESC`, `__name__ DESC` before releasing category search. Retain all existing indexes and wait until the new index is READY. Verify the active environment explicitly. Development and production catalogues can differ.

The footer Search entry remains disabled through `FeatureFlags.showSearchNavigation`. Enable it only after the deployed API, index and app pass the checks below. No database writes or deployment are included in this frontend change.

## Automated and visual checks

- Category-only search, combined text and category, clearing, retry and out-of-order requests.
- Category refresh on reopening, including a removed category.
- Back navigation, returning from a listing and Charities navigation.
- Keyboard dismissal, screen reader activation, dark mode and 200% text at 320 px width.
- Empty results, pagination errors and empty visible pages that still have a continuation.
- Repository parsing and category query parameters.
- Existing listing edits, deletions and feed regression tests.

The category list and empty-state layout have been rendered and inspected. The heart icon and empty-state background come from Figma file `E2MZsDUl54mmFzLAeqrbAb`, frames `2061:3263` and `11854:14357`. Category icons use catalogue images with existing bundled fallbacks.

## Local verification on 14 November 2026

The full frontend suite passed 695 tests. The final affected screens and parsing changes passed 28 targeted tests, followed by all 10 search-screen tests after the final accessibility assertion and lint tidy-up. The Android development debug build and safe logging guard passed. Analysis reported SDK deprecation information with no errors or warnings.

Local iOS verification remains incomplete. Xcode did not offer a simulator destination for Runner. A build attempted without that destination stopped while preparing Flutter.framework with a resource-fork signing error. No Xcode project, dependency-resolution or signing changes are included. Native keyboard and screen reader checks remain outstanding.

## Checks required against the deployed service

1. Confirm the release catalogue has all intended categories and no Electronics entry. Check the same list in Give and Search.
2. Select each category and confirm its listings have that category ID. Check an empty category too.
3. Search for a known phrase globally and inside a category. Compare all pages with a controlled set of listings, including multiple items created in the same millisecond.
4. Confirm sold, unlisted and moderation-hidden items stay absent. Avoid editing production listings merely to run this check.
5. Disconnect the network, retry, clear the query during a slow request and navigate back during loading.
6. On iOS and Android, check the real keyboard, backspace, swipe dismissal, system back, clear buttons and returning from item details. Check VoiceOver or TalkBack and enlarged text.
7. Enable the footer only after these checks pass, then verify entry from Home and Liked items.
