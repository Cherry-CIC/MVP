class FeatureFlags {
  const FeatureFlags._();

  // Hide incomplete inbox and messaging UI for the MVP without removing the code.
  static const bool showInbox = false;

  // Show the single homepage search entry point approved for the MVP.
  static const bool showSearch = true;

  // Keep the duplicate footer search entry point hidden for the MVP.
  static const bool showSearchNavigation = false;

  // Hide charity advert placeholders for the MVP without removing the code.
  static const bool showCharityAds = false;

  // Hide inactive donor-discount UI for the MVP without removing the code.
  static const bool showDonorDiscounts = false;

  // Hide request/open-to-other-charity controls for the MVP without removing the code.
  static const bool showOtherCharityRequests = false;

  // Hide make-offer and open-to-offers controls for the MVP without removing the code.
  static const bool showOffers = false;

  // Hide ask-seller controls for the MVP until seller messaging is implemented.
  static const bool showAskSeller = false;

  // Hide ratings and review-count UI for the MVP until ratings are actionable.
  static const bool showRatings = false;

  // Hide static impact summaries for the MVP until impact data is live.
  static const bool showImpactSummaries = false;

  // Hide non-functional Discover category filters for the MVP.
  static const bool showDiscoverSelectionBar = false;

  // Hide product rows within Discover charity cards for the MVP.
  static const bool showItemsInSupport = false;

  // Show basic profile contact rows requested for the MVP.
  static const bool showProfileContactDetails = true;

  // Show profile shortcut cards requested for the MVP.
  static const bool showProfileShortcutCards = true;

  // Hide placeholder profile stats and inactive profile shortcuts for the MVP.
  static const bool showProfileStats = false;

  // Hide inactive post-purchase shortcuts on the confirmation page for the MVP.
  static const bool showCheckoutConfirmationShortcuts = false;

  // Hide audited controls that are visible but do not trigger real MVP actions.
  static const bool showDeferredControls = false;
}
