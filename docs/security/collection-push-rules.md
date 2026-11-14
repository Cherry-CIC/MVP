# Collection push notification rules

## Scope and release status

These prototype rules exclude the new `pushDevices` and `collectionPushJobs` collections, including every descendant, from direct Firebase client access. Device registration and removal go through the authenticated backend. The backend uses the Admin SDK and is responsible for ownership checks, input validation, sending and job transitions.

**This is not a secure ruleset for production.** The pre-existing time-based wildcard still grants public read and write access to all other collections until 31 December 2030. Its overall audit score remains **1/5, critical**. This change preserves unrelated behaviour so that a collection reminder change does not silently break existing app access patterns. A separate review must replace that wildcard with tested access and validation rules before push is enabled.

In particular, locking push records alone does not establish trustworthy notification eligibility. A client can still forge or change an order or shipment, including ownership, status and deadlines. Backend checks against those documents cannot undo that exposure. Keep `COLLECTION_PUSH_ENABLED` disabled until the deployed rules protect both the new collections and the source order/shipment data. Inspect the rules actually deployed to the intended project rather than assuming this repository matches production.

## Protected data and access

| Collection | Backend data | Direct client access |
| --- | --- | --- |
| `pushDevices/{sha256(token)}` | Device token, authenticated buyer ID, platform, update timestamp | Denied, including to the buyer or a client with an admin claim |
| `collectionPushJobs/{sha256(shipmentId)}` | Shipment/order/buyer IDs, expiry, attempts, worker lease and device delivery receipts | Denied, including all nested paths |

No client-side validator is needed for these paths because no client create or update is permitted. The API and worker must still validate their writes: server SDKs bypass these rules. The Flutter notification repository uses the authenticated API rather than direct Firestore queries.

The exclusion sits inside the wildcard `allow` condition. A separate `allow ...: if false` block would not override an overlapping grant. This follows [Firebase's rule matching behaviour](https://firebase.google.com/docs/rules/rules-behavior).

## Verification

The isolated suite uses the Firestore emulator with the demo project `demo-cherry-push-rules`. It refuses to run without the expected local emulator host and never contacts the production Firestore database. Follow [Firebase's rules testing guidance](https://firebase.google.com/docs/rules/unit-tests) when extending it.

Run from `tool/push_rules`:

```sh
npm ci --ignore-scripts
npm test
```

Node 20 or later and Java 17 or later are required by the pinned test tooling. The suite checks:

- Anonymous and authenticated get, list, create, update and delete operations at three depths under both protected collections.
- Collection-group queries, orphan descendants and attempted forged ownership/status fields.
- Rejection of an entire batch containing both legacy and protected writes.
- Denial despite admin custom claims.
- Continued unrelated legacy access, explicitly labelled as a known security exposure rather than an acceptable security property.

All **74 tests passed** locally on 13 November 2026 with Firestore emulator 1.19.8 and Java 17. The pretest step copies the root rules into an ignored local file because the CLI rejects rules paths outside its project directory. The test setup independently loads the root source too.

The machine-readable audit is `collection-push-rules-audit.json`. Emulator success validates these scoped assertions and rule syntax. It does not prove the wider ruleset safe, validate the deployed policy or replace live access checks.

The pinned Firebase CLI 14 is compatible with the installed Java 17. Its isolated npm development dependency tree reported 28 advisories (16 moderate, 11 high and one critical) on that date. These packages are not shipped in the Flutter app. This suite uses only local, trusted test fixtures and a demo project. Before adopting the test harness in shared CI, review the advisories and move to a maintained CLI and Java version together. Do not apply `npm audit fix --force` blindly: the audit currently proposes downgrading Firebase SDKs as well as upgrading the CLI.

## Deployment handover

The root `firebase.json` now explicitly references `firestore.rules`. No rules have been deployed as part of this work. Do not deploy this repository file over an independently hardened production ruleset without comparing it first. Merging or deployment requires separate authorisation.

Before enabling push, review and test the wider policy, confirm the intended Firebase project, deploy the reviewed policy with explicit authorisation, and verify the protected collections and source data reject unauthorised client operations in that environment. APNs credentials, Android notification permission, worker scheduling and physical-device delivery remain separate checks.
