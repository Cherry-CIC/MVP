# Native wallet platform eligibility

The existing native wallet integration offers:

| Platform | Payment methods |
| --- | --- |
| Native iOS | Card and Apple Pay |
| Native Android | Card and Google Pay |
| Web, including iOS and Android browsers | Card only |
| Other platforms | Card only |

`PaymentType.isPlatformEligible` is the shared rule for the selector, checkout
summary and payment validation. It checks the web exclusion before allowing a
native wallet. It does not check wallet readiness or merchant configuration.

An unsupported stored choice remains stored until the user chooses a replacement.
The summary prompts for a payment method, no radio is selected and Continue is
disabled. Pay opens the selector again. Dismissing it does not create a payment.
Direct calls to `payWithPaymentSheet()` also reject the unsupported choice before
the request that creates a PaymentIntent and pending order.

## Automated checks

After resolving dependencies with the project's Flutter SDK, run:

```sh
flutter test --no-pub test/payment_type_test.dart test/checkout_payment_platform_test.dart test/checkout_view_model_test.dart test/checkout_repository_test.dart test/payment_intent_test.dart test/theme_dark_mode_test.dart
flutter test --no-pub --platform chrome test/payment_type_test.dart
flutter analyze --no-pub lib/features/checkout test/payment_type_test.dart test/checkout_payment_platform_test.dart test/checkout_view_model_test.dart test/checkout_repository_test.dart test/payment_intent_test.dart
```

The browser run tests the actual `kIsWeb` branch with every target-platform
override, including iOS and Android. Set `CHROME_EXECUTABLE` if the test browser
is installed outside the default location. Platform overrides are restored after
each test. Repository fakes count payment and order requests without contacting
the backend or opening Stripe.

## Visual and device checks

- Check the table above in light and dark themes. Rows should retain their labels,
  icons and radio controls, with no empty wallet section or duplicate divider.
- Choose Card and the eligible wallet in turn. Continue should close the selector
  and the checkout summary should show the chosen method.
- Check the unsupported-selection regression tests before changing selection
  handling. Do not silently replace an unsupported wallet with Card.

Widget renders cover layout and theme behaviour. They do not establish physical
device wallet readiness or successful payments. Apple Pay merchant configuration
and entitlements remain unresolved; Google Pay configuration also needs separate
review. No real payment is required for this change.
