/// Constants for shipping address functionality
class AddressConstants {
  // Address component keys
  static const String streetKey = 'street';
  static const String cityKey = 'city';
  static const String stateKey = 'state';
  static const String postalCodeKey = 'postalCode';
  static const String countryKey = 'country';

  // Google Places API types
  static const String streetNumberType = 'street_number';
  static const String routeType = 'route';
  static const String localityType = 'locality';
  static const String administrativeAreaLevel1Type =
      'administrative_area_level_1';
  static const String postalCodeType = 'postal_code';
  static const String countryType = 'country';

  // API settings
  static const String apiKeyEnvVar = 'GOOGLE_API_KEY';
  static const String countryRestriction = 'country:us'; // Adjust as needed
  static const String addressTypeFilter = 'address';

  // UI strings
  static const String addressHintText = 'Enter your shipping address';
  static const String deliveryAddressTitle = 'Delivery Address';
  static const String addressConfirmedTitle = 'Address Confirmed';
  static const String editButtonText = 'Edit';
  static const String editAddressTooltip = 'Edit address';
  static const String postalCodeHintText = 'Enter your postalcode';
  static const String addressHinText = 'address';
  static const String cityHintText = 'city';
  static const String postCodeHintText = 'postcode';

  // Error messages
  static const String addressSearchError = 'Error searching places';
  static const String placeDetailsError = 'Error getting place details';
  static const String apiKeyMissingError = 'Google API key not found';
  static const String checkoutError = 'Checkout error';
}
