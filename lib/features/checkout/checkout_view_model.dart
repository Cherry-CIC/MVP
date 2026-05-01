import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost_model.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

enum CheckoutFlowState {
  uninitialized,
  paymentProcessing,
  paymentCompleted,
  orderCreationProcessing,
  orderCreated,
  shipmentCreated,
  shipmentPending,
  paymentFailure,
  orderCreationFailure,
  shipmentFailure,
}

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  static const int _mvpDefaultShippingWeightGrams = 500;
  static const String _gbCountryCode = 'GB';
  static const String _pickupDeliveryChoice = 'pickup';
  static const String _pickupDeliveryType = 'pickup_point';
  static const String _homeDeliveryType = 'home';
  static const String _pickupShippingOptionId = 'mvp-pickup-point-delivery';
  static const String _homeShippingOptionId = 'mvp-home-delivery';
  static const String _pickupShippingOptionName = 'MVP pick-up point delivery';
  static const String _homeShippingOptionName = 'MVP home delivery';
  static const String _pickupShippingCarrier = 'inpost';
  static const String _homeShippingCarrier = 'evri';

  final ICheckoutRepository checkoutRepository;
  final NavigationProvider navigator;
  final _log = Logger('CheckoutViewModel');

  CheckoutViewModel({required this.checkoutRepository, required this.navigator});

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  CheckoutFlowState _checkoutFlowState = CheckoutFlowState.uninitialized;
  CheckoutFlowState get checkoutFlowState => _checkoutFlowState;

  String? _lastPaymentIntentId;
  String? get lastPaymentIntentId => _lastPaymentIntentId;

  bool get isCheckoutProcessing =>
      _checkoutFlowState == CheckoutFlowState.paymentProcessing ||
      _checkoutFlowState == CheckoutFlowState.paymentCompleted ||
      _checkoutFlowState == CheckoutFlowState.orderCreationProcessing;

  bool get hasCompletedCheckout =>
      _checkoutFlowState == CheckoutFlowState.shipmentCreated ||
      _checkoutFlowState == CheckoutFlowState.shipmentPending;

  bool get canRetryOrderCreation =>
      _checkoutFlowState == CheckoutFlowState.orderCreationFailure &&
      (_lastPaymentIntentId?.trim().isNotEmpty ?? false);

  final List<Product> _basketItems = [];

  final List<InpostModel> _nearestInpost = [];
  List<InpostModel> get nearestInpost => _nearestInpost;

  InpostModel? selectedInpost;

  bool showLocker = false;

  bool hasLocker = false;

  String? deliveryChoice;

  void setDeliveryChoice(String val) {
    deliveryChoice = val;
    notifyListeners();
  }

  void setShowLocker(bool val) {
    showLocker = val;
    notifyListeners();
  }

  void setSelectedInpost(var data) {
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

  //Whether user or logic has confirmed the shipping address
  bool isShippingAddressConfirmed = false;

  // Payment properties
  bool _hasPaymentMethod = false;

  /// Whether a payment method has been set
  bool get hasPaymentMethod => selectedPaymentType != null || _hasPaymentMethod;

  /// Whether the order is ready for checkout (has both address and payment method)
  bool get canCheckout => hasShippingAddress && hasPaymentMethod;

  bool get hasValidDeliveryDetails {
    if ((deliveryChoice ?? '').isEmpty) return false;
    if (_isPickupDelivery) return selectedInpost != null;
    return isShippingAddressConfirmed && hasShippingAddress && validateShippingAddress();
  }

  void setAddressConfirmed(bool value) {
    isShippingAddressConfirmed = value;
    notifyListeners();
  }

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

  PaymentType? selectedPaymentType;
  // Payment method methods
  void setPaymentType(PaymentType type) {
    selectedPaymentType = type;
    _hasPaymentMethod = true;
    notifyListeners();
  }

  PaymentType? getPaymentType() {
    return selectedPaymentType;
  }

  /// Sets whether a payment method has been configured
  void setPaymentMethod(bool hasPayment) {
    _hasPaymentMethod = hasPayment;
    if (!hasPayment) {
      selectedPaymentType = null;
    }
    notifyListeners();
  }

  /// Clears any selected payment method.
  void clearPaymentMethod() {
    selectedPaymentType = null;
    _hasPaymentMethod = false;
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
      AddressConstants.streetKey: '${_shippingAddress!.streetNumber} ${_shippingAddress!.route}'.trim(),
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
    selectedPaymentType = null;
    _hasPaymentMethod = false;
    isShippingAddressConfirmed = false;
    selectedInpost = null;
    _basketItems.clear();
    deliveryChoice = null;
    _createOrderStatus = Status.uninitialized;
    _checkoutFlowState = CheckoutFlowState.uninitialized;
    _lastPaymentIntentId = null;
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
    return street.isNotEmpty && city.isNotEmpty && postalCode.isNotEmpty && _isValidPostalCode(postalCode);
  }

  /// Helper method to validate postal code format (UK postcode validation)
  bool _isValidPostalCode(String postalCode) {
    // UK postcode pattern: 1-2 letters, 1-2 digits, optional letter/digit, space, digit, 2 letters
    final RegExp postcodePattern = RegExp(
      r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$',
      caseSensitive: false,
    );
    return postcodePattern.hasMatch(postalCode.trim());
  }

  /// Processes the checkout order
  /// Returns true if successful, false if validation fails or error occurs
  Future<bool> processCheckout() async {
    if (!canCheckout) return false;
    if (!validateShippingAddress()) return false;

    await submitCheckout();
    return hasCompletedCheckout;
  }

  Future<void> onConfirmLocation(String postalCode) async {
    await fetchNearestInPosts(postalCode);
    navigator.goBack();
  }

  // fetch nearest inPost locker for pickup
  Future<void> fetchNearestInPosts(String postalCode) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchNearestInPosts(postalCode);
      final parsedInposts = result.isSuccess && result.value != null
          ? _parseInpostList(result.value)
          : const <InpostModel>[];

      _nearestInpost
        ..clear()
        ..addAll(parsedInposts);

      if (parsedInposts.isNotEmpty) {
        showLocker = true;
        _status = Status.success;
      } else {
        showLocker = false;
        _status = Status.failure(
          result.isSuccess
              ? 'Pickup points currently unavailable, please try again later'
              : (result.error ?? 'Pickup points currently unavailable, please try again later'),
        );
        _log.warning(
          result.isSuccess
              ? 'Fetch nearest inPost locker returned an empty or invalid '
                    'payload for postcode $postalCode'
              : 'Fetch nearest inPost locker failed: ${result.error}',
        );
      }
    } catch (e) {
      showLocker = false;
      _nearestInpost.clear();
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
      if (doc != null && doc.exists && doc.data() is Map<String, dynamic>) {
        final data = doc.data() as Map<String, dynamic>;
        final id = (data[FirestoreConstants.id] ?? '').toString();
        final name = (data[FirestoreConstants.name] ?? '').toString();
        final address = (data[FirestoreConstants.address] ?? '').toString();
        final postcode = (data[FirestoreConstants.postcode] ?? '').toString();
        final lat = (data[FirestoreConstants.lat] ?? '').toString();
        final long = (data[FirestoreConstants.long] ?? '').toString();

        if (id.isNotEmpty && name.isNotEmpty && address.isNotEmpty && postcode.isNotEmpty) {
          selectedInpost = InpostModel(
            id: id,
            name: name,
            address: address,
            postcode: postcode,
            lat: lat,
            long: long,
          );
          hasLocker = true;
          showLocker = true;
          _status = Status.success;
        } else {
          hasLocker = false;
          showLocker = false;
          selectedInpost = null;
        }
      } else {
        hasLocker = false;
        showLocker = false;
        selectedInpost = null;
      }
      notifyListeners();
      return Result.success(null);
    } else {
      _status = Status.failure(result.error?.toString() ?? 'Unknown error');
      notifyListeners();
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
              'image': item.productImages.isNotEmpty ? item.productImages.first : null,
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
    try {
      await checkoutRepository.storeOrderInFirestore(orderData);
    } catch (e) {
      _log.severe('Error storing order to firestore:: $e');
      rethrow;
    }
  }

  Future<void> submitCheckout() async {
    final paymentIntentId = await payWithPaymentSheet(amount: total);
    if (paymentIntentId == null) return;

    await createOrder(paymentIntentId: paymentIntentId);
  }

  Future<void> retryOrderCreation() async {
    final paymentIntentId = _lastPaymentIntentId?.trim();
    if (paymentIntentId == null || paymentIntentId.isEmpty) {
      _checkoutFlowState = CheckoutFlowState.orderCreationFailure;
      _createOrderStatus = Status.failure(
        AppStrings.checkoutPaymentDetailsUnavailable,
      );
      notifyListeners();
      return;
    }

    await createOrder(paymentIntentId: paymentIntentId);
  }

  Future<String?> payWithPaymentSheet({required double amount}) async {
    if (!hasPaymentMethod || selectedPaymentType == null) {
      _checkoutFlowState = CheckoutFlowState.paymentFailure;
      _createOrderStatus = Status.failure(
        AppStrings.checkoutPaymentMethodRequired,
      );
      notifyListeners();
      return null;
    }

    _checkoutFlowState = CheckoutFlowState.paymentProcessing;
    _createOrderStatus = Status.loading;
    notifyListeners();

    try {
      final response = await checkoutRepository.createPaymentIntent(amount);

      if (response.isSuccess && response.value != null) {
        final paymentResponse = response.value!;

        Stripe.publishableKey = paymentResponse.publishableKey;
        await Stripe.instance.applySettings();

        final setupParams = _buildPaymentSheetParameters(
          paymentResponse,
          selectedPaymentType!,
        );

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: setupParams,
        );

        // Present the native PaymentSheet (it will show ApplePay/GooglePay if available)
        await Stripe.instance.presentPaymentSheet();

        final paymentIntentId = _resolvePaymentIntentId(paymentResponse);
        if (paymentIntentId == null) {
          _checkoutFlowState = CheckoutFlowState.paymentFailure;
          _createOrderStatus = Status.failure(
            AppStrings.checkoutPaymentDetailsUnavailable,
          );
          _log.severe('Payment details unavailable after PaymentSheet completion');
          notifyListeners();
          return null;
        }

        _lastPaymentIntentId = paymentIntentId;
        _checkoutFlowState = CheckoutFlowState.paymentCompleted;
        notifyListeners();
        return paymentIntentId;
      } else {
        _checkoutFlowState = CheckoutFlowState.paymentFailure;
        _createOrderStatus = Status.failure(
          AppStrings.checkoutPaymentDetailsUnavailable,
        );
        _log.severe('Unexpected payment failure');
        notifyListeners();
        return null;
      }
    } on StripeException catch (e) {
      final wasCancelled = e.error.code == FailureCode.Canceled;
      _checkoutFlowState = CheckoutFlowState.paymentFailure;
      _createOrderStatus = Status.failure(
        wasCancelled ? AppStrings.checkoutPaymentCancelled : AppStrings.checkoutPaymentFailed,
      );
      _log.severe('Stripe payment failed during PaymentSheet presentation');
      notifyListeners();
      return null;
    } catch (e) {
      _checkoutFlowState = CheckoutFlowState.paymentFailure;
      _createOrderStatus = Status.failure(AppStrings.checkoutPaymentFailed);
      _log.severe('Unexpected payment failure');
      notifyListeners();
      return null;
    }
  }

  Future<void> createOrder({required String paymentIntentId}) async {
    final trimmedPaymentIntentId = paymentIntentId.trim();

    if (trimmedPaymentIntentId.isEmpty) {
      _checkoutFlowState = CheckoutFlowState.orderCreationFailure;
      _createOrderStatus = Status.failure(
        AppStrings.checkoutPaymentDetailsUnavailable,
      );
      notifyListeners();
      return;
    }

    final validationMessage = _orderCreationValidationMessage();
    if (validationMessage != null) {
      _checkoutFlowState = CheckoutFlowState.orderCreationFailure;
      _createOrderStatus = Status.failure(validationMessage);
      notifyListeners();
      return;
    }

    _checkoutFlowState = CheckoutFlowState.orderCreationProcessing;
    _createOrderStatus = Status.loading;
    notifyListeners();

    final orderData = _buildOrderPayload(trimmedPaymentIntentId);
    try {
      final result = await checkoutRepository.createOrder(orderData);
      if (result.isSuccess) {
        _checkoutFlowState = _resolveShipmentFlowState(result.value);
        _createOrderStatus = _checkoutFlowState == CheckoutFlowState.shipmentFailure
            ? Status.failure(AppStrings.checkoutShipmentFailed)
            : Status.success;
      } else {
        _checkoutFlowState = CheckoutFlowState.orderCreationFailure;
        _createOrderStatus = Status.failure(
          AppStrings.checkoutOrderCreationFailed,
        );
        _log.warning('Order creation failed after payment');
      }
    } catch (e) {
      _checkoutFlowState = CheckoutFlowState.orderCreationFailure;
      _createOrderStatus = Status.failure(
        AppStrings.checkoutOrderCreationFailed,
      );
      _log.severe('Unexpected order creation failure');
    }
    notifyListeners();
  }

  String? _orderCreationValidationMessage() {
    if (basketItems.isEmpty) return 'Your basket is empty';
    if ((deliveryChoice ?? '').isEmpty) {
      return AppStrings.checkoutDeliveryOptionRequired;
    }
    if (_isPickupDelivery) {
      return selectedInpost == null ? AppStrings.checkoutPickupLockerRequired : null;
    }
    if (!isShippingAddressConfirmed || !hasShippingAddress || !validateShippingAddress()) {
      return AppStrings.checkoutDeliveryAddressRequired;
    }
    return null;
  }

  bool get _isPickupDelivery => deliveryChoice == _pickupDeliveryChoice;

  Map<String, dynamic> _buildOrderPayload(String paymentIntentId) {
    final product = basketItems.first;
    final isPickup = _isPickupDelivery;

    // TODO: Replace these MVP fallback values with the selected Sendcloud
    // shipping option once option selection is wired into checkout.
    return {
      'amount': _toMinorUnits(total),
      'paymentIntentId': paymentIntentId,
      'deliveryType': isPickup ? _pickupDeliveryType : _homeDeliveryType,
      'shippingOptionId': isPickup ? _pickupShippingOptionId : _homeShippingOptionId,
      'shippingWeight': _mvpDefaultShippingWeightGrams,
      'shipping': {
        'address': isPickup ? _buildPickupAddress() : _buildHomeAddress(),
        'name': _resolveShippingName(),
      },
      'productId': product.id,
      'productName': product.name,
      'shippingOptionName': isPickup ? _pickupShippingOptionName : _homeShippingOptionName,
      'shippingOptionPrice': isPickup ? 0 : _toMinorUnits(postage),
      'shippingCarrier': isPickup ? _pickupShippingCarrier : _homeShippingCarrier,
      if (isPickup) 'pickupPoint': _buildPickupPointPayload(),
    };
  }

  Map<String, dynamic> _buildHomeAddress() {
    return {
      'line1': shippingAddressComponents[AddressConstants.streetKey] ?? '',
      'city': shippingAddressComponents[AddressConstants.cityKey] ?? '',
      'postal_code': shippingAddressComponents[AddressConstants.postalCodeKey] ?? '',
      'country': _gbCountryCode,
    };
  }

  Map<String, dynamic> _buildPickupAddress() {
    final pickup = selectedInpost;
    return {
      'line1': pickup?.address ?? '',
      'city': _resolvePickupCity(),
      'postal_code': pickup?.postcode ?? '',
      'country': _gbCountryCode,
    };
  }

  Map<String, dynamic> _buildPickupPointPayload() {
    final pickup = selectedInpost;
    return {
      'id': pickup?.id ?? '',
      'name': pickup?.name ?? '',
      'addressLine1': pickup?.address ?? '',
      'city': _resolvePickupCity(),
      'postalCode': pickup?.postcode ?? '',
      'country': _gbCountryCode,
      'carrier': _pickupShippingCarrier,
    };
  }

  String _resolvePickupCity() {
    final pickup = selectedInpost;
    if (pickup == null) return '';

    // TODO: Replace this best-effort parsing with structured Sendcloud pickup
    // point address fields when they are available in checkout.
    final postcode = pickup.postcode.trim();
    var addressWithoutPostcode = pickup.address.trim();
    if (postcode.isNotEmpty) {
      addressWithoutPostcode = addressWithoutPostcode
          .replaceAll(RegExp(RegExp.escape(postcode), caseSensitive: false), '')
          .trim();
    }

    final addressParts = addressWithoutPostcode
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (addressParts.length < 2) return '';

    return addressParts.last;
  }

  String _resolveShippingName() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final displayName = user?.displayName?.trim();
      if (displayName != null && displayName.isNotEmpty) return displayName;

      final email = user?.email?.trim();
      if (email != null && email.isNotEmpty) {
        final emailPrefix = email.split('@').first.trim();
        if (emailPrefix.isNotEmpty) return emailPrefix;
      }
    } catch (_) {
      // Firebase may be unavailable in tests. The fallback remains safe.
    }

    return 'cherry customer';
  }

  String? _resolvePaymentIntentId(PaymentIntentResponse paymentResponse) {
    final explicitPaymentIntentId = paymentResponse.paymentIntentId?.trim();
    if (explicitPaymentIntentId != null && explicitPaymentIntentId.isNotEmpty) {
      return explicitPaymentIntentId;
    }

    return _paymentIntentIdFromClientSecret(paymentResponse.paymentIntent);
  }

  String? _paymentIntentIdFromClientSecret(String clientSecret) {
    final trimmed = clientSecret.trim();
    const secretDelimiter = '_secret_';
    final secretIndex = trimmed.indexOf(secretDelimiter);
    if (secretIndex <= 0) return null;

    // TODO: Ask the backend to return paymentIntentId explicitly so the
    // frontend does not need to derive it from the Stripe client secret.
    return trimmed.substring(0, secretIndex);
  }

  CheckoutFlowState _resolveShipmentFlowState(dynamic payload) {
    final shipmentStatus = _shipmentStatusFromResponse(payload)?.toLowerCase();
    switch (shipmentStatus) {
      case 'pending':
        return CheckoutFlowState.shipmentPending;
      case 'failed':
      case 'failure':
      case 'error':
        return CheckoutFlowState.shipmentFailure;
      default:
        return CheckoutFlowState.shipmentCreated;
    }
  }

  String? _shipmentStatusFromResponse(dynamic payload) {
    final map = _asStringKeyedMap(payload);
    if (map == null) return null;

    return _firstStringValue([
      map['shipmentStatus'],
      map['shipment_status'],
      _nestedMapValue(map['shipment'], 'status'),
      _nestedMapValue(map['data'], 'shipmentStatus'),
      _nestedMapValue(map['data'], 'shipment_status'),
      map['status'],
    ]);
  }

  dynamic _nestedMapValue(dynamic value, String key) {
    return _asStringKeyedMap(value)?[key];
  }

  String? _firstStringValue(List<dynamic> values) {
    for (final value in values) {
      final stringValue = value?.toString().trim();
      if (stringValue != null && stringValue.isNotEmpty) {
        return stringValue;
      }
    }
    return null;
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int _toMinorUnits(double amount) {
    return (amount * 100).round();
  }

  SetupPaymentSheetParameters _buildPaymentSheetParameters(
    PaymentIntentResponse paymentResponse,
    PaymentType paymentType,
  ) {
    final customerId = paymentResponse.customer.trim();
    final ephemeralKey = paymentResponse.ephemeralKey.trim();
    final hasCustomerContext = customerId.isNotEmpty && ephemeralKey.isNotEmpty;

    final googlePay = paymentType == PaymentType.google
        ? const PaymentSheetGooglePay(merchantCountryCode: "GB", testEnv: true)
        : null;
    final applePay = paymentType == PaymentType.apple ? const PaymentSheetApplePay(merchantCountryCode: "GB") : null;

    if (hasCustomerContext) {
      return SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentResponse.paymentIntent,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
        merchantDisplayName: "cherry",
        googlePay: googlePay,
        applePay: applePay,
      );
    }

    return SetupPaymentSheetParameters(
      paymentIntentClientSecret: paymentResponse.paymentIntent,
      merchantDisplayName: "cherry",
      googlePay: googlePay,
      applePay: applePay,
    );
  }

  void resetCreateOrderStatus() {
    _createOrderStatus = Status.uninitialized;
    notifyListeners();
  }

  List<InpostModel> _parseInpostList(dynamic payload) {
    final dynamic listData = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload['lockers'] ?? payload['items'])
        : payload;

    if (listData is! List) return [];

    final lockers = <InpostModel>[];
    for (final item in listData) {
      final locker = _parseInpostItem(item);
      if (locker != null) {
        lockers.add(locker);
      }
    }
    return lockers;
  }

  InpostModel? _parseInpostItem(dynamic item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);

    String readFirst(List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    final id = readFirst(['id', 'lockerId', 'code']);
    final name = readFirst(['name', 'lockerName']);
    final address = readFirst(['address', 'line1', 'street']);
    final postcode = readFirst(['postcode', 'postalCode', 'postCode']);
    final lat = readFirst(['lat', 'latitude']);
    final long = readFirst(['long', 'lng', 'longitude']);

    if (id.isEmpty || name.isEmpty || address.isEmpty || postcode.isEmpty) {
      return null;
    }

    return InpostModel(
      id: id,
      name: name,
      address: address,
      postcode: postcode,
      lat: lat,
      long: long,
    );
  }

  Future<void> goToHome() async {
    await navigator.navigateToAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
  }

  Future<void> gotoCheckoutComplete() async {
    await Future.delayed(const Duration(seconds: 1));
    await navigator.replaceWith(AppRoutes.checkoutComplete);
  }

  Future<void> showPurchaseSecurity() async {
    await navigator.showPurchaseSecurity();
  }
}
