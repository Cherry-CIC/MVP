import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:logging/logging.dart';

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  final ICheckoutRepository checkoutRepository;
  final _log = Logger('CheckoutViewModel');

  CheckoutViewModel({required this.checkoutRepository});

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  final List<Product> _basketItems = [];

  final List<InpostModel> _nearestInpost = [
    InpostModel(
      id: "002",
      name: "Aldi Locker — Camden",
      address: "Camden High Street, London",
      postcode: "NW1 8QP",
      lat: "51.5413",
      long: "-0.1460",
    ),
    InpostModel(
      id: "010",
      name: "Aldi Locker — Deansgate",
      address: "Deansgate, Manchester",
      postcode: "M3 2BW",
      lat: "53.4808",
      long: "-2.2474",
    ),
    InpostModel(
      id: "030",
      name: "Aldi Locker — Temple Gate",
      address: "Temple Gate, Bristol",
      postcode: "BS1 6PL",
      lat: "51.4490",
      long: "-2.5830",
    ),
  ];
  List<InpostModel> get nearestInpost => _nearestInpost;

  InpostModel? selectedInpost;

  bool showLocker = false;

  bool hasLocker = false;

  String? deliveryChoice;

  setDeliveryChoice(String val) {
    deliveryChoice = val;
    notifyListeners();
  }

  setShowLocker(bool val) {
    showLocker = val;
    notifyListeners();
  }

  setSelectedInpost(var data) {
    selectedInpost = data;
    notifyListeners();
  }

  /// Unmodifiable list of items in the basket
  List<Product> get basketItems => List.unmodifiable(_basketItems);

  /// Total price of all items in the basket
  double get itemTotal => _basketItems.fold(0, (sum, item) => sum + item.price);

  /// Security fee calculated as 10% of item total
  double get securityFee => itemTotal * 0.1;

  /// Fixed postage fee
  double get postage => 2.99;

  /// Total order amount including all fees
  double get total => itemTotal + securityFee + postage;

  // Shipping Address properties
  PlaceDetails? _shippingAddress;

  /// Currently selected shipping address
  PlaceDetails? get shippingAddress => _shippingAddress;

  /// Whether a valid shipping address has been selected
  bool get hasShippingAddress => _shippingAddress != null;

  // Payment properties
  bool _hasPaymentMethod = false;

  /// Whether a payment method has been set
  bool get hasPaymentMethod => _hasPaymentMethod;

  /// Whether the order is ready for checkout (has both address and payment method)
  bool get canCheckout => hasShippingAddress && hasPaymentMethod;

  // Existing basket methods
  void addItem(Product product) {
    _basketItems.add(product);
    notifyListeners();
  }

  void removeItem(Product product) {
    _basketItems.remove(product);
    notifyListeners();
  }

  void clearBasket() {
    _basketItems.clear();
    notifyListeners();
  }

  // Shipping address methods

  /// Sets the shipping address from Google Places API result
  /// Notifies listeners when address is updated
  void setShippingAddress(PlaceDetails address) {
    _shippingAddress = address;
    notifyListeners();
  }

  /// Clears the currently selected shipping address
  void clearShippingAddress() {
    _shippingAddress = null;
    notifyListeners();
  }

  // Payment method methods

  /// Sets whether a payment method has been configured
  void setPaymentMethod(bool hasPayment) {
    _hasPaymentMethod = hasPayment;
    notifyListeners();
  }

  /// Returns the formatted shipping address for display purposes
  String get formattedShippingAddress {
    return _shippingAddress?.formattedAddress ?? "2, Court yard";
  }

  /// Returns shipping address components as a map for backend processing
  /// Keys are standardized using AddressConstants
  Map<String, String> get shippingAddressComponents {
    if (_shippingAddress == null) return {};

    return {
      AddressConstants.streetKey:
          '${_shippingAddress!.streetNumber} ${_shippingAddress!.route}'.trim(),
      AddressConstants.cityKey: _shippingAddress!.locality,
      AddressConstants.stateKey: _shippingAddress!.administrativeAreaLevel1,
      AddressConstants.postalCodeKey: _shippingAddress!.postalCode,
      AddressConstants.countryKey: _shippingAddress!.country,
    };
  }

  /// Resets checkout state for a new order
  /// Clears shipping address and payment method but preserves basket items
  void resetCheckout() {
    _shippingAddress = null;
    _hasPaymentMethod = false;
    _basketItems.clear();
    deliveryChoice = null;
    _createOrderStatus = Status.uninitialized;
    notifyListeners();
  }

  /// Validates that the shipping address has all required components
  /// Returns true if address is valid for checkout
  bool validateShippingAddress() {
    if (_shippingAddress == null) return false;

    final components = shippingAddressComponents;

    // Check required fields are present and non-empty
    final street = components[AddressConstants.streetKey]?.trim() ?? '';
    final city = components[AddressConstants.cityKey]?.trim() ?? '';
    final postalCode = components[AddressConstants.postalCodeKey]?.trim() ?? '';

    // Basic validation - could be enhanced with format validation
    return street.isNotEmpty &&
        city.isNotEmpty &&
        postalCode.isNotEmpty &&
        _isValidPostalCode(postalCode);
  }

  /// Helper method to validate postal code format (basic US ZIP code validation)
  bool _isValidPostalCode(String postalCode) {
    // Basic US ZIP code pattern (5 digits or 5+4 format)
    final RegExp zipPattern = RegExp(r'^\d{5}(-\d{4})?$');
    return zipPattern.hasMatch(postalCode);
  }

  /// Processes the checkout order
  /// Returns true if successful, false if validation fails or error occurs
  /// TODO: Implement actual API integration
  Future<bool> processCheckout() async {
    if (!canCheckout) return false;
    if (!validateShippingAddress()) return false;

    try {
      // Prepare order data for API call
      final Map<String, dynamic> orderData = {
        'items': basketItems
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'price': item.price,
                // Add other product fields as needed
              },
            )
            .toList(),
        'shipping_address': {
          'formatted_address': formattedShippingAddress,
          AddressConstants.streetKey:
              shippingAddressComponents[AddressConstants.streetKey],
          AddressConstants.cityKey:
              shippingAddressComponents[AddressConstants.cityKey],
          AddressConstants.stateKey:
              shippingAddressComponents[AddressConstants.stateKey],
          'postal_code':
              shippingAddressComponents[AddressConstants.postalCodeKey],
          AddressConstants.countryKey:
              shippingAddressComponents[AddressConstants.countryKey],
          'latitude': _shippingAddress?.latitude,
          'longitude': _shippingAddress?.longitude,
        },
        'totals': {
          'item_total': itemTotal,
          'security_fee': securityFee,
          'postage': postage,
          'total': total,
        },
      };

      // TODO: Implement actual API call here
      // Example: await checkoutService.processOrder(orderData);
      // For now, we'll just validate the order data is properly structured
      if (orderData['items'] == null || (orderData['items'] as List).isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      // Log error for debugging purposes only
      debugPrint('${AddressConstants.checkoutError}: $e');
      return false;
    }
  }

  // fetch nearest inPost locker for pickup
  Future<void> fetchNearestInPosts(String postalCode) async {
    _status = Status.loading;
    notifyListeners();

    try {
      //final result = await checkoutRepository.fetchNearestInPosts(postalCode);
      if (_nearestInpost.isNotEmpty) {
        showLocker = true;
        _status = Status.success;
      } else {
        _status = Status.failure(
          //result.error ??
          'Pickup points currently unavailable, please try again later',
        );
        _log.warning('Fetch nearest inPost locker failed! ');
      }
    } catch (e) {
      _status = Status.failure(e.toString());
      _log.severe('Fetch nearest inPost locker error:: $e');
    }

    notifyListeners();
  }

  Future<void> storeLockerInFirestore() async {
    try {
      await checkoutRepository.storeLockerInFirestore(selectedInpost!);
    } catch (e) {
      _log.severe('Error storing locker to firestore:: $e');
    }
  }

  Future<Result> fetchUserLocker() async {
    final result = await checkoutRepository.fetchUserLocker();
    if (result.isSuccess) {
      final doc = result.value;
      if (doc != null && doc.exists) {
        // hydrate your selectedInpost here
        selectedInpost = InpostModel(
          id: doc.get(FirestoreConstants.id),
          name: doc.get(FirestoreConstants.name),
          address: doc.get(FirestoreConstants.address),
          postcode: doc.get(FirestoreConstants.postcode),
          lat: doc.get(FirestoreConstants.lat),
          long: doc.get(FirestoreConstants.long),
        );
        hasLocker = true;
        showLocker = true;
        _status = Status.success;
        notifyListeners();
      }
      return Result.success(null);
    } else {
      return Result.failure(result.error);
    }
  }

  /// Store a dummy order in Firestore
  Future<void> storeOrderInFirestore() async {
    final Map<String, dynamic> orderData = {
      'items': _basketItems
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'image': item.productImages.isNotEmpty
                  ? item.productImages.first
                  : null,
            },
          )
          .toList(),
      'shipping_address': {
        'formatted_address': formattedShippingAddress,
        ...shippingAddressComponents,
        'latitude': _shippingAddress?.latitude,
        'longitude': _shippingAddress?.longitude,
      },
      'totals': {
        'item_total': itemTotal,
        'security_fee': securityFee,
        'postage': postage,
        'total': total,
      },
      'created_at': DateTime.now().toIso8601String(),
    };
    await checkoutRepository.storeOrderInFirestore(orderData);
  }

  Future<bool> payWithPaymentSheet({required double amount}) async {
    _createOrderStatus = Status.loading;
    notifyListeners();

    try {
      // To create a PaymentIntent and return the client_secret
      final response = await checkoutRepository.createPaymentIntent(amount);

      if (response.isSuccess && response.value != null) {
        String clientSecret = response.value!.paymentIntent;
        String customer = response.value!.customer;

        // Init the payment sheet (configure Apple/Google Pay here)
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            customerId: customer,
            merchantDisplayName: "cherry",
            //applePay: PaymentSheetApplePay(merchantCountryCode: "GB"),
            googlePay: PaymentSheetGooglePay(
              merchantCountryCode: "GB",
              testEnv: true, // true for testing
            ),
          ),
        );

        // Present the native PaymentSheet (it will show ApplePay/GooglePay if available)
        await Stripe.instance.presentPaymentSheet();
        return true;
      }
    } on StripeException catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe(
        'Stripe Payment Error :: ${e.error.localizedMessage ?? e.toString()}',
      );
      return false;
    } catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe('Error making payment:: $e');
      return false;
    }
    notifyListeners();
    return false;
  }

  Future<void> createOrder() async {
    _createOrderStatus = Status.loading;
    notifyListeners();

    final Map<String, dynamic> address = deliveryChoice == "pickup"
        ? {
            "line1": selectedInpost?.address ?? '',
            "city": "London",
            "state": "London",
            "postal_code": selectedInpost?.postcode ?? '',
            "country": "United kingdom",
          }
        : {
            'line1': formattedShippingAddress,
            "city":
                shippingAddressComponents[AddressConstants.cityKey] ?? "London",
            "state":
                shippingAddressComponents[AddressConstants.stateKey] ??
                "London",
            'postal_code':
                shippingAddressComponents[AddressConstants.postalCodeKey] ??
                "SW1 7AX",
            "country":
                shippingAddressComponents[AddressConstants.countryKey] ??
                "United kingdom",
          };

    final Map<String, dynamic> orderData = {
      "amount": total.toInt(),
      "productId": basketItems[0].id,
      "productName": basketItems[0].name,
      "shipping": {"address": address, "name": "John Doe"},
    };
    try {
      final result = await checkoutRepository.createOrder(orderData);
      if (result.isSuccess) {
        _createOrderStatus = Status.success;
      } else {
        _createOrderStatus = Status.failure(result.error ?? "");
        _log.warning('Create order failed! ${result.error}');
      }
    } catch (e) {
      _createOrderStatus = Status.failure(e.toString());
      _log.severe('Create order failed! ${e.toString()}');
    }
    notifyListeners();
  }
}
