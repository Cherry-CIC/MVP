# Public user profile API handover

Status: proposed backend contract, inspected on 19 September 2026. This endpoint does **not** exist in the published Swagger documentation or the inspected backend `main` revision. The Flutter profile flow cannot load live profiles or satisfy the full definition of done until this API is implemented, tested and deployed.

## Verified existing behaviour

- [Published Swagger](https://cherry-backend-401854471349.europe-west2.run.app/api-docs/) documents `/api/auth/profile` for the authenticated user's own profile. Its user schema includes email and authentication identifiers, so it is unsuitable for a public profile.
- `/api/products` and `/api/products/with-details` support `limit` and `cursor`, but expose no documented seller filter. The [query validator](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/modules/products/validators/productValidator.ts) omits `userId`; [request validation](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/shared/middleware/validateRequest.ts) strips unknown query fields. Adding `?userId=...` would not select that seller.
- `/api/products/my-products` explicitly uses the authenticated user's UID. Do not repurpose it.
- [ProductService](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/modules/products/services/ProductService.ts) already supports owner filtering internally. Its public feed requires `status == active` and `number > 0`; its current owner-listing method does not apply that availability rule. Reusing that method unchanged would expose non-public listings.
- [Mounted routes](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/app.ts) contain no public-user module. Source inspection used backend revision `acf818eaa05c86e3356f1ba06440d967e52bae74`; the deployed revision was not verified. No real user records were queried.

## Minimum endpoint

`GET /api/users/{userId}/public-profile?limit=20&cursor=...`

Use the existing Firebase bearer-token authentication. Here, public means visible to other authorised cherry users; anonymous access is not required by this contract.

`userId` is the seller identifier already returned as `Product.userId`, currently the Firebase UID. [Product creation](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/modules/products/controllers/productController.ts) writes the verified caller's `uid`. [UserRepository](https://github.com/Cherry-CIC/cherry-Backend/blob/acf818eaa05c86e3356f1ba06440d967e52bae74/src/modules/auth/repositories/UserRepository.ts) resolves the stored `id` field, which is distinct from the generated user document ID. Do not interchange those identifiers or add separate authentication fields to this response.

Return the user on every page, including when the listing array is empty:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "seller-uid",
      "username": "Alex",
      "profileImageUrl": null
    },
    "products": [
      {
        "id": "listing-id",
        "userId": "seller-uid",
        "name": "Blue cotton shirt",
        "description": "A pre-loved cotton shirt in good condition.",
        "quality": "Good",
        "product_images": ["https://example.org/listing.jpg"],
        "donation": 10,
        "price": 10,
        "securityFee": 1,
        "likes": 0,
        "number": 1,
        "size": "M",
        "postageSize": "small-parcel-id",
        "categoryId": "shirts-id",
        "charityId": "charity-id",
        "status": "active",
        "visibility": "public"
      }
    ]
  },
  "meta": {
    "limit": 20,
    "nextCursor": null,
    "hasMore": false
  }
}
```

The sample amounts are illustrative. Use the existing server-side price and security-fee calculation, not these example values.

## Public fields and visibility

- Build a dedicated response allowlist. `user` contains only `id`, `username` and nullable `profileImageUrl`. Map the intended public name and photo into these fields; current backend naming includes `displayName`/`photoURL` and legacy `firstname`/`photoUrl`. `username` in this contract is a public display label, not a newly required unique handle. Never derive it from email or a private full name.
- Never spread an entire user document into the response. Exclude email, phone, addresses, authentication metadata, tokens, settings and account administration fields, including nested relations.
- Product objects use only the public listing fields in the example. Optional `createdAt`/`updatedAt` timestamps and explicitly allowlisted public `category`/`charity` display details may be included for existing listing components. Do not include raw owner, order, shipment or payment records.
- Force the requested owner and public availability on the server, before producing the page and pagination metadata. Every returned product must have that `userId`, `status: active`, `visibility: public` and positive stock. Exclude drafts, unlisted, sold, removed, deleted and moderation-hidden products. A client-provided status or visibility must never broaden access.
- `visibility` is a required declaration in this new contract, not an existing documented backend field. It must reflect actual publication/moderation checks. Missing or unknown publication state must not silently become public; any legacy-state mapping needs backend review and tests.
- Confirm the target account exists and is publicly available on every request. Missing, deleted, disabled or otherwise unavailable users return no profile or listings. The existing anonymised owner marker `deleted_user` is unavailable. Respect any applicable existing viewer/block restrictions without exposing their reason.

## Pagination and errors

- `limit`: integer, default 20, minimum 1, maximum 50, matching current listing pagination.
- Use stable descending creation time and product ID ordering. `nextCursor` is an opaque URL-encoded query value. Scope cursor validation to the target user, viewer and visibility policy; the existing product cursor signature does not include an owner and must not be copied unchanged.
- Require `meta.limit`, `meta.nextCursor` and `meta.hasMore`. `hasMore: true` requires a non-empty next cursor. `hasMore: false` requires `nextCursor: null`. Excluded records must not leak through counts, cursors or later pages.
- `200` with `products: []`: available user with no public listings.
- `404` or `410`: unavailable user, with no user details or products. Use a generic response that does not disclose account status or blocking details.
- `400`: invalid identifier, page size or cursor. `401`/`403`: caller authentication/access failure. `429`/`5xx`: retryable service failure. These must not be labelled as a deleted user in Flutter.

## Verification before release

Backend tests must cover the public allowlist, owner isolation, missing/deleted/disabled users, every excluded listing state, positive stock, empty profiles, stable multi-page results, invalid/cross-user cursors and authentication failures. Assert that responses contain no private fields, including nested data. Add the endpoint and its exact response schema to Swagger.

Flutter navigation, repository and widget tests can use contract fixtures before deployment. Final checks must also verify the deployed endpoint using approved test accounts: listing seller to public profile, public profile to normal listing detail, pagination, unavailable users and absence of private data in network responses. This handover does not claim those backend or live integration checks have passed; record final Flutter static-analysis and test results in the implementation handover.

## Flutter implementation and verification

Implemented on 20 September 2026:

- `NavigationProvider.openPublicUserProfile(userId)` is the shared entry point for future user links. It rejects missing, malformed and anonymised identifiers. The active seller identity on product details uses it; the charity logo is a separate element.
- `PublicUserProfile` owns its loading and pagination state. It shows the public username, optional photo and active/public listings using `SellerListingCard`. It includes retry, empty and unavailable states, image fallbacks, refresh and large-text layouts. No personal-profile, account or settings model is reused.
- `PublicUserProfileRepository` calls the proposed endpoint, checks that the returned user matches the requested ID, keeps only explicitly public fields and rejects unavailable or wrong-owner listing entries. These client checks do not replace server filtering.
- Product detail routes retain their own `Product` argument. Returning from another listing therefore restores the original listing, including its seller, like action and purchase target.
- Seller names/photos on product details now use this public API with `limit=1`, once per detail route, instead of reading a complete Firestore user document. **Deploy the endpoint before releasing these Flutter changes.** Until then, seller names fall back to `User`, and profile requests may show unavailable/error states. This is an API-dependent implementation, not a completed live rollout.
- No new dependencies, reporting/blocking features or backend deployment are included.

Validation: `flutter test --no-pub` passed all **203 tests**. `flutter analyze --no-pub` reported **no issues**. Dart formatting, `git diff --check` and `bash tool/check_safe_logging.sh` passed. Tests cover navigation and nested back navigation, API error status handling, public-field projection, owner/visibility checks, pagination, unavailable accounts, late-response isolation, retry and accessibility semantics/layout.

The checkout initially had no `.env`, which causes an existing missing-asset analysis warning. Verification used a temporary, credential-free `.env` pointing to `https://example.test`; it was removed afterwards. Supply a local test configuration before repeating Flutter checks, without overwriting an existing configuration. No live user records, backend mutations or device/store submission checks were performed.
