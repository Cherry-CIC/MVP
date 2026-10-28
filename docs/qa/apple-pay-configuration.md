# Apple Pay configuration and verification

## Report and scope

The affected app is TestFlight **0.1.1 (12)**, connected to the **production backend**, as confirmed by the tester. The payment screen does not open and checkout displays a generic failure. Its exact source revision and signed entitlements have not been established.

This change was prepared from `8681b87da99521b4a95f81e5fe4ac6a01a588328` and integrated with updated `origin/main` at `53e30f070721106aa0f4c878ee16e06d137fecee`, including wallet platform filtering in PR #558. The latest successful GitHub TestFlight run inspected was [40216784957](https://github.com/Cherry-CIC/MVP/actions/runs/40216784957), for `Release-prod` at `8298601805f9975349d9452d39db2c27ae2c0e16`. Its log records build number 9, so it does not establish the provenance of build 12.

## Cause established in source

Checkout configured `PaymentSheetApplePay` without assigning `Stripe.merchantIdentifier`. The installed `flutter_stripe` / `stripe_ios` 12.6.0 implementation rejects this: the Dart debug assertion and native iOS `missingMerchantId` check both guard PaymentSheet initialisation. The native check also applies to release builds. The generic catch concealed the cause.

`Runner.entitlements` also omitted `com.apple.developer.in-app-payments`. All Runner configurations already reference that file.

## Changes

- Assign `merchant.uk.org.cherry` before applying Stripe settings, keeping the backend's publishable key.
- Add that merchant to the Apple Pay entitlement and declare the capability in the Xcode target. Preserve Sign in with Apple.
- Treat Stripe cancellation as `Status.canceled`; retain the basket and clear payment/order IDs without displaying a payment failure.
- Log only a fixed checkout stage and failure code in release console diagnostics. No provider messages, keys, payment IDs or personal details are accepted by the logger. Preparation includes backend and parsing failures because the repository returns both as a failed result.
- Make the TestFlight workflow check the archived app's signed merchant, team and application entitlements before export/upload. `codesign --xml` is required for the plist parser. The workflow is still manually triggered.

Amounts, fees, shipping, backend requests, payment ownership and order/webhook contracts are unchanged. No certificates or account settings have been changed.

## Automated verification

Run with Flutter 3.44.4 / Dart 3.12.2:

```sh
flutter test --no-pub test/checkout_payment_sheet_test.dart test/checkout_payment_platform_test.dart test/payment_type_test.dart test/checkout_view_model_test.dart test/checkout_repository_test.dart test/payment_intent_test.dart test/core/services/network/safe_http_log_interceptor_test.dart
flutter analyze --no-pub lib/core/services/safe_log.dart lib/features/checkout/checkout_view_model.dart test/checkout_payment_sheet_test.dart
bash tool/check_safe_logging.sh
plutil -lint ios/Runner/Runner.entitlements ios/Runner.xcodeproj/project.pbxproj
```

All 70 focused tests pass, including the platform-filtering tests from PR #558. They exercise the real Dart Stripe serialisation through a mocked native channel: settings order, merchant ID, GB Apple Pay, card checkout, cancellation, failures/timeouts, safe log content, and IDs used for order confirmation. They do not exercise Apple's payment UI, signing, Stripe servers or real orders. Targeted analysis, logging guard and plist validation pass.

The merchant regression was also run with only the new merchant assignment temporarily removed: it failed, and passed again after restoring the assignment. This reproduces the source defect at the Dart SDK boundary without a real payment.

Workflow YAML/shell/Python syntax and six synthetic entitlement cases were checked. The actual signed-archive step has not run on CI.

Native compilation remains unverified on this Mac (Xcode 26.6). `flutter build ios --release --no-codesign --no-pub --flavor dev` stopped with a signing/team error. A direct `Release-prod` Xcode build with signing explicitly disabled exited with status 139 during package setup. Neither attempt produced a verified app. These are local validation limitations; no unrelated signing or SDK changes have been included to work around them.

The existing lockfile is incompatible with this installed Flutter SDK's pinned versions of `matcher`, `meta`, `test_api` and `vector_math`. Local tests used `flutter pub get` to resolve those SDK dependencies. The original tracked lockfile is retained; no dependency changes form part of this fix. Stripe remains at 12.6.0. Reproduce with a compatible SDK or resolve locally before using `--no-pub`.

## Remaining verification

1. Establish the source/archive used for build 12. Match its version, build, configuration and bundle identifier.
2. Confirm that the App ID `uk.org.cherry.app` for team `63U2HM4MQA` permits Apple Pay with `merchant.uk.org.cherry`, and that the distribution profile includes it. Local inspection found no valid signing identities and only a wildcard development profile without Apple Pay. No account changes were attempted.
3. In the Stripe account used by the backend, check [iOS Certificate Settings](https://dashboard.stripe.com/settings/ios_certificates). Confirm the existing certificate belongs to the merchant and was issued from Stripe's CSR. Account sign-in is required to inspect this. The handover reports an active certificate expiring 6 December 2027; that association remains unverified. Do not replace or revoke certificates without evidence. See [Stripe's setup guide](https://docs.stripe.com/apple-pay?platform=ios).
4. Build and distribute a new signed build after approval. Inspect the exported IPA's app and embedded profile as well as the archive; export may re-sign the app. Verify merchant, team, application identifier, retained Sign in with Apple and distribution signing. The new CI check covers the archived app only.
5. Confirm the test backend actually uses **Stripe test mode** before completing a payment. Build 12 points to production; TestFlight alone does not make a transaction a test. Do not submit a live payment as an automated check.
6. On a supported iPhone with Apple Pay configured, open checkout, confirm the payment screen appears, cancel and check that the basket remains with no failure toast. Retry using the controlled test environment, complete payment, and verify the same order is correctly recorded and finalised. Check card checkout too. Inspect sanitised device console output for a deliberately failed test.

PR #558 handles hiding Google Pay on iOS and Apple Pay on Android. It was merged into `main` during this task and is included in the integrated branch and test run. Its implementation has not been duplicated. Check the selector on the final device build too. The older platform-filtering draft is not needed for this fix.

No merge, deployment, TestFlight upload or real payment has been performed. The source defects are corrected; full payment resolution remains unverified until the signed-device and account checks above pass.
