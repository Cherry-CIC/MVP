# Cherry MVP Smoke Test Checklist

## Purpose
This checklist is used for quick MVP verification before broader regression testing.

## Environment
- Branch:
- Commit:
- Build source:
- Device:
- OS:
- Tester:
- Date:

## P0 Smoke Tests

### App launch
- [ ] App launches without crash
- [ ] No blank screen
- [ ] No blocking terminal error

### Authentication
- [ ] Email sign-up works
- [ ] Email sign-in works
- [ ] Google sign-in works or known issue is linked
- [ ] Logout works

### Home
- [ ] Product list loads
- [ ] Product images load
- [ ] Product details open
- [ ] Products do not disappear after app remains open
- [ ] Returning to Home does not cause unnecessary loader or empty list

### Profile
- [ ] Profile opens for authenticated user
- [ ] Core account information loads
- [ ] Empty states are clear and not misleading
- [ ] Listings / Orders / Liked items are functional or hidden
- [ ] No placeholder statistics or dead shortcuts are visible

### Give / Listing
- [ ] Give flow opens
- [ ] Required-field validation works
- [ ] Category can be selected
- [ ] Charity can be selected
- [ ] Postage size can be selected
- [ ] Valid listing can be submitted without duplicate submission

### Checkout
- [ ] Checkout opens from product
- [ ] Checkout summary is correct
- [ ] Payment method is required
- [ ] Failed/cancelled payment does not show success
- [ ] Successful controlled test payment reaches confirmation page

### MVP hidden/deferred controls
- [ ] Inbox is hidden or functional
- [ ] Search is hidden or functional
- [ ] Make Offer is hidden
- [ ] Ask Seller is hidden
- [ ] Ratings are hidden unless functional
- [ ] Donor discounts are hidden unless functional
- [ ] Impact summaries are hidden unless real
- [ ] No ghost buttons are visible

### Settings / legal / compliance
- [ ] Settings opens
- [ ] FAQ opens
- [ ] Privacy Policy opens
- [ ] Terms and Conditions opens
- [ ] Account deletion entry point exists or known issue is linked

### Logging / security
- [ ] No auth token is printed in logs
- [ ] No sensitive user data is exposed in terminal output