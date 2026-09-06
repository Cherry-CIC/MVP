# Checkout delivery validation

Implemented and verified on 6 September 2026. Scope: Flutter checkout state, UI and regression tests.

## Problem and corrected flow

Previously, `payWithPaymentSheet()` checked for a selected pickup point and shipping method, but only `createOrder()` checked the pickup point's complete address. A point without a city could therefore start payment before the client rejected its order. Telephone edits reached the view model only on submission or an outside tap, and a delayed profile response unconditionally replaced both the controller and view-model value.

`CheckoutPage` now validates before opening the payment-method chooser. `CheckoutViewModel` repeats the same validation at the payment boundary, before loading state or any payment-intent request. Both payment and order submission use one delivery validator and the existing `_hasCompletePickupPoint()` rule. Required pickup fields remain ID, name, address, city, postcode and a country that normalises to two characters. Pickup delivery also requires a non-blank telephone and a selected shipping method. The existing home-address validation and confirmation are checked for the hidden home mode; this change does not enable home delivery or change the existing payment integration's pickup dependency.

Telephone `onChanged` events immediately update the view model. The controller reflects that value. An explicit edited flag prevents profile prefill after any buyer edit, including clearing the field. A checkout-session counter rejects profile responses belonging to a reset checkout.

Each payment attempt captures an immutable product ID, payment type and delivery/contact snapshot. Checkout setters, reset, basket edits and UI controls are locked from payment initiation until order submission finishes. `createOrder()` uses the same snapshot. Overlapping payment/order calls and repeated Pay taps are guarded, including while the payment-method chooser is open. Cancellation and failures release the lock. Inline delivery/telephone errors retain entered values and guide the buyer towards the relevant input.

## Files

| File | Change |
| --- | --- |
| `lib/features/checkout/checkout_view_model.dart` | Shared validation, protected prefill, attempt snapshot and submission guards. |
| `lib/features/checkout/checkout_page.dart` | Submission sequencing, repeat-tap guard, locked controls/back navigation and error scrolling. |
| `lib/features/checkout/widgets/delivery_options.dart` | Immediate phone binding, controller lifecycle, inline errors and locked selectors. |
| `lib/core/config/app_strings.dart` | Actionable incomplete-pickup copy and home-address validation message. |
| `test/checkout_delivery_validation_test.dart` | 20 deterministic view-model regressions. |
| `test/checkout_delivery_widgets_test.dart` | 6 widget regressions. |
| `test/support/checkout_fakes.dart` | Recording repository and fake native payment-sheet channel. |

## Verification

Commands ran from the repository root using the installed Flutter SDK at `/Users/bradleyvenn/Documents/cherry/flutter`. Flutter and Dart below refer to that SDK's `bin/flutter` and `bin/cache/dart-sdk/bin/dart`. Tests and analysis used a temporary empty `.env` solely because the manifest requires the asset. It contained no secrets and was removed afterwards.

```sh
flutter test --no-pub test/checkout_delivery_validation_test.dart test/checkout_delivery_widgets_test.dart test/checkout_view_model_test.dart test/product_self_purchase_test.dart --reporter expanded
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
dart format lib/core/config/app_strings.dart lib/features/checkout/checkout_view_model.dart lib/features/checkout/checkout_page.dart lib/features/checkout/widgets/delivery_options.dart test/support/checkout_fakes.dart test/checkout_delivery_validation_test.dart test/checkout_delivery_widgets_test.dart
dart format --output=none --set-exit-if-changed lib/core/config/app_strings.dart lib/features/checkout/checkout_view_model.dart lib/features/checkout/checkout_page.dart lib/features/checkout/widgets/delivery_options.dart test/support/checkout_fakes.dart test/checkout_delivery_validation_test.dart test/checkout_delivery_widgets_test.dart
git diff --check
```

- Targeted suite: 38 passed.
- Full suite: 163 passed, including the existing 137 tests and 26 new regressions.
- Static analysis: no issues.
- Formatter check: seven files checked, no changes required.
- Diff whitespace check: passed.

The regressions cover all required pickup fields, missing selections, blank telephone values, corrected retries, delayed profile loading, cleared fields, controller recreation, old-session responses, visible versus submitted telephone, locking through all three asynchronous stages, cancellation, request failures, order failures, repeated submissions, one payment-method chooser and inline phone errors on a 390 by 600 logical-pixel screen.

## Review limits

No backend, API contract, Firestore, logistics, pricing or Stripe-processing changes were made. No architectural layer or dependency was added. Existing public payment/order methods remain available; callers must await payment and then submit the order, as the page does.

Tests intercept both the repository payment-intent boundary and the native Stripe method channel. No live payment or native-device payment-sheet check was performed. No native debug build was run: the repository's existing CI workflow checks GitHub Actions with CodeQL and does not define a Flutter build.

This fix prevents failures from delivery details already known to be invalid. It does not provide payment recovery if the backend rejects an order after successful payment, nor payment/order idempotency across app restarts. Those existing concerns require separate work. Existing country and telephone validation rules were retained; no new phone-format or carrier-specific validation was introduced.

## PR #489 merge verification

Merged main at `b72fca0` into the PR branch. The single conflict in `createOrder()` was resolved by retaining main's sanitised error message and typed safe logging alongside this PR's `finally` block, which releases both submission guards and notifies listeners. All other main changes were retained.

Added a regression for an unexpected repository exception: the buyer receives the sanitised message, checkout unlocks, entered telephone data remains intact and a subsequent order call can complete.

Verification after resolving the conflict: locked dependencies resolved with `flutter pub get --offline --enforce-lockfile`; `flutter test --no-pub --reporter expanded` passed all 185 tests; `flutter analyze --no-pub` reported no issues; `bash tool/check_safe_logging.sh`, formatting checks for the two edited Dart files and `git diff --check` passed. The temporary empty `.env` was removed. No live payment or native build was performed. Main now also includes the safe-logging CI workflow, in addition to the CodeQL workflow described above.
