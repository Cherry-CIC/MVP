# Cherry MVP Smoke Test Checklist

## Purpose

This checklist provides a fast, reproducible verification of the Cherry MVP before broader functional or regression testing.

The checklist covers critical P0 user journeys and important P1 behaviour on Android and iOS.

## Test Result Definitions

* **Pass** — the actual result matches the expected result.
* **Fail** — the actual result does not match the expected result.
* **Blocked** — the test cannot be completed because of an environment problem, unavailable dependency or existing defect.
* **Not run** — the test has not been executed.

A known issue must not be recorded as **Pass**. Record it as **Fail** or **Blocked** and add the GitHub issue reference in the Evidence / Issue column.

## Environment

* **Branch:**
* **Commit:**
* **Build source:**
* **App version:**
* **Device:**
* **OS and version:**
* **Tester:**
* **Test date:**
* **Network:**
* **Test environment:**

## Preconditions

* The application is installed from the intended build.
* A valid test email account is available.
* A valid Google test account is available.
* At least one active product is available.
* Test payment credentials are available where payment testing is permitted.
* Device logs or terminal output are available for inspection.
* The approved Cherry Figma design is available for comparison.
* No production credentials or real payment details are used.

# P0 Smoke Tests

P0 tests cover functionality whose failure blocks the principal MVP journeys or makes the build unsuitable for further testing.

## Application Launch

| ID           | Test                     | Steps                                                                                                                         | Expected Result                                                                            | Status  | Evidence / Issue |
| ------------ | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------- | ---------------- |
| P0-LAUNCH-01 | Launch the application   | 1. Install or update the intended build.<br>2. Tap the Cherry application icon.<br>3. Observe the application during startup. | The application launches successfully and does not crash.                                  | Not run |                  |
| P0-LAUNCH-02 | Initial screen rendering | 1. Launch the application.<br>2. Wait for the initial screen to finish loading.                                               | The initial screen displays correctly. No persistent blank, white or black screen appears. | Not run |                  |
| P0-LAUNCH-03 | Startup errors           | 1. Start log capture.<br>2. Launch the application.<br>3. Review terminal or device logs.                                     | No blocking exception, fatal error or repeated startup failure is recorded.                | Not run |                  |

## Authentication

| ID         | Test                | Steps                                                                                                                        | Expected Result                                                                                                                                          | Status  | Evidence / Issue |
| ---------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-AUTH-01 | Email sign-up       | 1. Open the registration flow.<br>2. Enter valid, previously unused test-user details.<br>3. Submit the form.                | The account is created successfully, the user is authenticated and the expected post-registration screen opens.                                          | Not run |                  |
| P0-AUTH-02 | Email sign-in       | 1. Open the email sign-in flow.<br>2. Enter valid credentials.<br>3. Tap **Sign in**.                                        | The user is authenticated and the Home screen opens without an authentication error or unexpected redirect.                                              | Not run |                  |
| P0-AUTH-03 | Google sign-in      | 1. Select **Continue with Google**.<br>2. Choose a valid Google test account.<br>3. Complete the Google authentication flow. | The user is authenticated and the Home screen opens. A known Google sign-in defect must be recorded as Fail or Blocked with the related issue reference. | Not run |                  |
| P0-AUTH-04 | Invalid credentials | 1. Open email sign-in.<br>2. Enter invalid credentials.<br>3. Submit the form.                                               | Authentication is rejected and a clear error message is displayed. The application does not crash or authenticate the user.                              | Not run |                  |
| P0-AUTH-05 | Logout              | 1. Sign in.<br>2. Open the account or Settings area.<br>3. Select **Logout**.<br>4. Confirm logout if prompted.              | The user session ends and the authentication screen is displayed. Authenticated content is no longer accessible.                                         | Not run |                  |

## Session Persistence

| ID            | Test                          | Steps                                                                                            | Expected Result                                                                                              | Status  | Evidence / Issue |
| ------------- | ----------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ | ------- | ---------------- |
| P0-SESSION-01 | Restore authenticated session | 1. Sign in successfully.<br>2. Close the application completely.<br>3. Relaunch the application. | The valid authenticated session is restored and the user is not unexpectedly returned to the sign-in screen. | Not run |                  |
| P0-SESSION-02 | Logout persistence            | 1. Log out.<br>2. Close the application completely.<br>3. Relaunch the application.              | The user remains logged out and the authentication screen is displayed.                                      | Not run |                  |

## Main Navigation

| ID        | Test               | Steps                                                                                         | Expected Result                                                                                             | Status  | Evidence / Issue |
| --------- | ------------------ | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-NAV-01 | Primary navigation | 1. Sign in.<br>2. Tap each visible primary navigation item.<br>3. Observe the opened screen.  | Every visible navigation item opens the correct screen without a crash, blank screen or incorrect redirect. | Not run |                  |
| P0-NAV-02 | Back navigation    | 1. Open a product or secondary screen.<br>2. Use the application or device Back control.      | The previous screen opens and the application remains in a valid state.                                     | Not run |                  |
| P0-NAV-03 | Navigation state   | 1. Open a primary screen.<br>2. Navigate to another screen.<br>3. Return to the first screen. | The correct navigation item is selected and the screen does not show an unexpected empty or broken state.   | Not run |                  |

## Home and Product Journey

| ID         | Test                   | Steps                                                                                                                                  | Expected Result                                                                                                      | Status  | Evidence / Issue |
| ---------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-HOME-01 | Load product list      | 1. Sign in.<br>2. Open Home.<br>3. Wait for loading to complete.                                                                       | The product list loads and available products are displayed.                                                         | Not run |                  |
| P0-HOME-02 | Load product images    | 1. Open Home.<br>2. Review visible product cards.                                                                                      | Product images load correctly, or an intentional fallback image is displayed. Broken image controls are not visible. | Not run |                  |
| P0-HOME-03 | Open product details   | 1. Tap an available product card.                                                                                                      | The corresponding product-details screen opens and shows the correct product information.                            | Not run |                  |
| P0-HOME-04 | Product-list stability | 1. Open Home and wait for products to load.<br>2. Leave the application open for several minutes.<br>3. Review the product list again. | Previously loaded products do not disappear unexpectedly and the screen does not change to an incorrect empty state. | Not run |                  |
| P0-HOME-05 | Return to Home         | 1. Open a product-details screen.<br>2. Navigate to another primary screen.<br>3. Return to Home.                                      | Home displays the product list without an unnecessary persistent loader, blank screen or incorrect empty list.       | Not run |                  |

## Basket

| ID           | Test                              | Steps                                                                                                         | Expected Result                                                                                                              | Status  | Evidence / Issue |
| ------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-BASKET-01 | Add product to basket             | 1. Open an available product.<br>2. Select the add-to-basket action.<br>3. Open the basket.                   | The selected product appears once in the basket with the correct name, image and price.                                      | Not run |                  |
| P0-BASKET-02 | Basket total                      | 1. Add a product to the basket.<br>2. Open the basket.<br>3. Review the displayed total.                      | The basket subtotal and total are calculated correctly for the selected product.                                             | Not run |                  |
| P0-BASKET-03 | Remove product from basket        | 1. Add a product to the basket.<br>2. Open the basket.<br>3. Remove the product.                              | The product is removed and the basket totals and empty state update correctly.                                               | Not run |                  |
| P0-BASKET-04 | Prevent unintended duplicate item | 1. Add a product to the basket.<br>2. Tap the add-to-basket action again where this action remains available. | The application follows the intended quantity or duplicate-item behaviour and does not create an unintended duplicate entry. | Not run |                  |

## Give / Listing Journey

| ID         | Test                      | Steps                                                                                                                   | Expected Result                                                                                             | Status  | Evidence / Issue |
| ---------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-GIVE-01 | Open Give flow            | 1. Sign in.<br>2. Select the Give or create-listing action.                                                             | The first listing screen opens without a crash, blank screen or blocking error.                             | Not run |                  |
| P0-GIVE-02 | Required-field validation | 1. Open the Give flow.<br>2. Leave required fields empty.<br>3. Attempt to continue or submit.                          | Submission is prevented and clear validation is displayed for each required field.                          | Not run |                  |
| P0-GIVE-03 | Select category           | 1. Open the category selector.<br>2. Select an available category.<br>3. Continue through the flow.                     | The selected category is displayed and retained.                                                            | Not run |                  |
| P0-GIVE-04 | Select charity            | 1. Open the charity selector.<br>2. Select an available charity.<br>3. Continue through the flow.                       | The selected charity is displayed and retained.                                                             | Not run |                  |
| P0-GIVE-05 | Select postage size       | 1. Open the postage-size selector.<br>2. Select an available size.<br>3. Continue through the flow.                     | The selected postage size is displayed and retained.                                                        | Not run |                  |
| P0-GIVE-06 | Submit valid listing      | 1. Complete all required listing fields with valid test data.<br>2. Submit the listing once.<br>3. Wait for the result. | The listing is submitted once, clear success feedback is displayed and duplicate submission does not occur. | Not run |                  |

## Checkout and Payment

| ID             | Test                          | Steps                                                                                                                                                         | Expected Result                                                                                                                                 | Status  | Evidence / Issue |
| -------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-CHECKOUT-01 | Open checkout                 | 1. Open a purchasable product.<br>2. Add it to the basket if required.<br>3. Select the checkout action.                                                      | Checkout opens for the selected product without a crash or incorrect redirect.                                                                  | Not run |                  |
| P0-CHECKOUT-02 | Checkout summary              | 1. Open checkout.<br>2. Compare the checkout information with the selected product and basket.                                                                | Product details, price, delivery information, fees and total are correct and internally consistent.                                             | Not run |                  |
| P0-CHECKOUT-03 | Payment-method validation     | 1. Open checkout.<br>2. Leave the payment method unselected.<br>3. Attempt to continue.                                                                       | Payment cannot continue and a clear payment-method validation message is displayed.                                                             | Not run |                  |
| P0-CHECKOUT-04 | Pickup-point selection        | 1. Choose delivery to a pickup point where supported.<br>2. Open the pickup-point selector.<br>3. Select an available pickup point.<br>4. Return to checkout. | The selected pickup point is shown correctly and is retained in the checkout summary.                                                           | Not run |                  |
| P0-CHECKOUT-05 | Failed or cancelled payment   | 1. Begin payment with approved test credentials.<br>2. Cancel the payment or use the controlled failure scenario.<br>3. Return to the application.            | No success confirmation is displayed. The order is not incorrectly marked as paid and the user receives clear failure or cancellation feedback. | Not run |                  |
| P0-CHECKOUT-06 | Successful controlled payment | 1. Complete checkout with approved test payment credentials.<br>2. Finish the external or embedded payment flow.<br>3. Return to the application.             | The payment succeeds once, the confirmation screen opens and the displayed order information is correct.                                        | Not run |                  |

## Logging and Security

| ID        | Test                         | Steps                                                                                                                           | Expected Result                                                                                                         | Status  | Evidence / Issue |
| --------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-SEC-01 | Authentication-token logging | 1. Start log capture.<br>2. Sign up, sign in and navigate through authenticated screens.<br>3. Review terminal and device logs. | Access tokens, refresh tokens and complete authentication credentials are not printed in logs.                          | Not run |                  |
| P0-SEC-02 | Sensitive user-data logging  | 1. Start log capture.<br>2. Complete authentication, profile, listing and checkout actions.<br>3. Review logs.                  | Passwords, payment details and unnecessary sensitive personal information are not exposed in terminal or device output. | Not run |                  |

## E2E / Release Readiness

| ID        | Test                                  | Steps                                                                                                                                                               | Expected Result                                                                                                                        | Status  | Evidence / Issue |
| --------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P0-E2E-01 | Buyer can complete controlled checkout | 1. Sign in as a buyer.<br>2. Open a purchasable product.<br>3. Complete checkout using approved test payment credentials.<br>4. Return to the app.                | Checkout completes once, the confirmation screen opens, and the order is created with the correct product and payment information.     | Not run |                  |
| P0-E2E-02 | Purchased item appears in My Orders   | 1. Complete a controlled purchase.<br>2. Open Profile.<br>3. Open My Orders.<br>4. Review the purchased item.                                                       | The purchased item appears in My Orders with correct product, price, delivery status and charity/order information where available.    | Not run |                  |
| P0-E2E-03 | Purchased item is removed from public purchase flow | 1. Record the exact test listing/product before checkout.<br>2. Complete a controlled purchase.<br>3. Return to Home as the buyer or another user.<br>4. Search for the same purchased listing. | The exact purchased item is either absent from the public Home/search feed or clearly unavailable, with no Buy Now, checkout or other purchase action available. | Not run |                  |
| P0-E2E-04 | Seller can still trace sold/listed item | 1. Carry forward the exact listing/product used in the controlled purchase.<br>2. Sign in as the seller.<br>3. Open Profile → Listings.<br>4. Locate and review that same listing. | The exact purchased listing is not hard-deleted unexpectedly. It remains traceable for seller/order/support context with a clear sold, inactive or unavailable state. | Not run |                  |
| P0-E2E-05 | Seller cannot purchase own listing | 1. Sign in as a seller with an existing listing.<br>2. Open that listing from Profile → Listings or another available route.<br>3. Inspect the purchase action.<br>4. Attempt to initiate purchase if any purchase action is available.<br>5. Check My Orders afterwards. | The seller's own listing cannot be purchased. Buy Now is disabled or unavailable, checkout/payment does not start, and no order is created for the seller's own listing. | Not run | |
| P0-E2E-06 | Order/payment status is consistent     | 1. Complete a controlled payment.<br>2. Open confirmation and My Orders.<br>3. Compare payment/order status shown to the user.                                      | The app does not show a false success state. Payment/order status is consistent between checkout confirmation and My Orders.           | Not run |                  |
| P0-E2E-07 | No sensitive logs during E2E flow      | 1. Start terminal/device log capture.<br>2. Complete authentication, product, checkout and order-history actions.<br>3. Review logs.                              | No full Authorization Bearer token, refresh token, password, payment detail or unnecessary sensitive user data is printed in logs.     | Not run |                  |

# P1 Smoke Tests

P1 tests cover important MVP behaviour that may not block every primary journey but must be assessed before release.

## Profile

| ID            | Test                    | Steps                                                                                                | Expected Result                                                                                      | Status  | Evidence / Issue |
| ------------- | ----------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P1-PROFILE-01 | Open Profile            | 1. Sign in.<br>2. Open Profile.                                                                      | Profile opens for the authenticated user without a crash, blank screen or authentication error.      | Not run |                  |
| P1-PROFILE-02 | Account information     | 1. Open Profile.<br>2. Review the displayed account information.                                     | Core account information loads and belongs to the authenticated test user.                           | Not run |                  |
| P1-PROFILE-03 | Profile empty states    | 1. Use an account without listings, orders or liked items.<br>2. Open the relevant Profile sections. | Each empty state is clear, accurate and does not imply that data is still loading.                   | Not run |                  |
| P1-PROFILE-04 | Profile shortcuts       | 1. Tap visible Listings, Orders and Liked-items shortcuts.                                           | Each visible shortcut opens functional content. Incomplete shortcuts are hidden or clearly disabled. | Not run |                  |
| P1-PROFILE-05 | Placeholder information | 1. Review statistics, counters and account shortcuts in Profile.                                     | No fabricated statistics, misleading values, placeholder content or dead shortcuts are visible.      | Not run |                  |

## Settings, Legal and Compliance

| ID          | Test                         | Steps                                                                   | Expected Result                                                                                                                                 | Status  | Evidence / Issue |
| ----------- | ---------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P1-LEGAL-01 | Open Settings                | 1. Sign in.<br>2. Open Settings.                                        | Settings opens without a crash, blank screen or blocking error.                                                                                 | Not run |                  |
| P1-LEGAL-02 | Open FAQ                     | 1. Open Settings.<br>2. Select FAQ.                                     | FAQ content opens and is readable. The control does not lead to an empty or broken screen.                                                      | Not run |                  |
| P1-LEGAL-03 | Open Privacy Policy          | 1. Open Settings.<br>2. Select Privacy Policy.                          | The Privacy Policy opens and is readable.                                                                                                       | Not run |                  |
| P1-LEGAL-04 | Open Terms and Conditions    | 1. Open Settings.<br>2. Select Terms and Conditions.                    | Terms and Conditions open and are readable.                                                                                                     | Not run |                  |
| P1-LEGAL-05 | Account-deletion entry point | 1. Open Profile or Settings.<br>2. Locate the account-deletion control. | A functional account-deletion entry point exists. A missing or defective flow is recorded as Fail or Blocked with the relevant issue reference. | Not run |                  |

## MVP Hidden or Deferred Controls

| ID        | Test                      | Steps                                                                                 | Expected Result                                                                                                      | Status  | Evidence / Issue |
| --------- | ------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P1-VIS-01 | Inbox visibility          | Review all primary navigation, Home and Profile controls for Inbox access.            | Inbox is hidden when incomplete. If visible, it opens a functional MVP-supported flow.                               | Not run |                  |
| P1-VIS-02 | Search visibility         | Review Home and primary navigation for Search controls.                               | Search is hidden when incomplete. If visible, it returns appropriate results and does not open a placeholder screen. | Not run |                  |
| P1-VIS-03 | Make Offer visibility     | Open product details and review available actions.                                    | The Make Offer control is not visible unless the complete flow is supported.                                         | Not run |                  |
| P1-VIS-04 | Ask Seller visibility     | Open product details and review available actions.                                    | The Ask Seller control is not visible unless the complete flow is supported.                                         | Not run |                  |
| P1-VIS-05 | Ratings visibility        | Review product, seller and Profile screens.                                           | Ratings are hidden unless they display genuine data and the related flow is functional.                              | Not run |                  |
| P1-VIS-06 | Donor-discount visibility | Review product, checkout and Profile screens.                                         | Donor discounts are hidden unless the data and redemption behaviour are implemented.                                 | Not run |                  |
| P1-VIS-07 | Impact-summary visibility | Review Home, Profile, listing and checkout screens.                                   | Impact summaries are hidden unless they are calculated from real supported data.                                     | Not run |                  |
| P1-VIS-08 | Ghost controls            | Review all screens visited during smoke testing and tap visible interactive controls. | No visible button, icon, card or link is unresponsive or opens an unintended placeholder screen.                     | Not run |                  |

## Resilience and Application Lifecycle

| ID        | Test                   | Steps                                                                                                                                                   | Expected Result                                                                                                           | Status  | Evidence / Issue |
| --------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P1-RES-01 | Network interruption   | 1. Open the product list.<br>2. Disable network access.<br>3. Refresh the list or open a product.<br>4. Restore network access.<br>5. Retry the action. | The application displays a clear error or offline state, does not crash and recovers after connectivity is restored.      | Not run |                  |
| P1-RES-02 | Resume from background | 1. Open Home, product details or checkout.<br>2. Put the application in the background.<br>3. Wait briefly.<br>4. Return to the application.            | The application resumes without a crash, maintains a valid session and returns to an appropriate screen state.            | Not run |                  |
| P1-RES-03 | Interrupted loading    | 1. Begin loading Home or product details.<br>2. Temporarily interrupt connectivity.<br>3. Restore connectivity and retry.                               | A persistent loader does not remain indefinitely. The application provides an error, retry option or successful recovery. | Not run |                  |

## Visual Comparison

| ID       | Test                               | Steps                                                                                                                                                                                            | Expected Result                                                                                                | Status  | Evidence / Issue |
| -------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| P1-UI-01 | Compare with approved Figma design | 1. Open each MVP screen covered by this checklist.<br>2. Compare it with the corresponding approved Figma design.<br>3. Review layout, typography, colours, spacing, icons, images and controls. | No material visual differences are present. Any discrepancy is recorded with a screenshot and issue reference. | Not run |                  |

# Test Summary

| Priority  | Passed | Failed | Blocked | Not Run |
| --------- | -----: | -----: | ------: | ------: |
| P0        |        |        |         |         |
| P1        |        |        |         |         |
| **Total** |        |        |         |         |

## Failed or Blocked Tests

| Test ID | Actual Result | Evidence | GitHub Issue | Release Impact |
| ------- | ------------- | -------- | ------------ | -------------- |
|         |               |          |              |                |

## Final Decision

* [ ] **Pass** — all P0 tests passed and no release-blocking P1 defect was identified.
* [ ] **Pass with known issues** — all P0 tests passed and accepted non-blocking defects are documented.
* [ ] **Fail** — one or more P0 tests failed or a release-blocking defect was identified.
* [ ] **Blocked** — the checklist could not be completed because of an environment or dependency problem.

## Recommendation

* [ ] Approve for broader testing
* [ ] Retest required
* [ ] Release decision required
* [ ] Build rejected

## Notes

*
