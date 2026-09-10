import 'package:cherry_mvp/core/models/model.dart';
import 'package:cherry_mvp/core/services/safe_log.dart';
import 'package:cherry_mvp/features/donation/donation_repository.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/models/inpost_shipping_method.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_repository.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/models/payment_intent.dart';
import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';

enum DeliveryType { pickup, home, undefined }

/// ViewModel for managing checkout state including basket items, shipping address, and payment method
class CheckoutViewModel extends ChangeNotifier {
  final ICheckoutRepository checkoutRepository;
  final IDonationRepository _donationRepository;
  final NavigationProvider navigator;
  final String? Function() _currentUserIdProvider;

  CheckoutViewModel({
    required this._donationRepository,
    required this.checkoutRepository,
    required this.navigator,
    String? Function()? currentUserIdProvider,
  }) : _currentUserIdProvider = currentUserIdProvider ?? (() => null);

  Status _status = Status.uninitialized;

  Status get status => _status;

  Status _createOrderStatus = Status.uninitialized;
  Status get createOrderStatus => _createOrderStatus;

  bool _isCheckoutInProgress = false;
  bool _isCreatingOrder = false;
  bool get isCheckoutInProgress => _isCheckoutInProgress;
  _CheckoutAttempt? _checkoutAttempt;

  String? _deliveryError;
  String? _mobilePhoneError;
  String? get deliveryError => _deliveryError;
  String? get mobilePhoneError => _mobilePhoneError;

  final List<Product> _basketItems = [];

  final List<InpostSearchResult> _nearestInposts = [];
  List<InpostSearchResult> get nearestInposts => _nearestInposts;

  final List<InpostShippingMethod> _inpostShippingMethods = [];
  List<InpostShippingMethod> get inpostShippingMethods => _inpostShippingMethods;

  Inpost? _selectedInpost;
  Inpost? get selectedInpost => _selectedInpost;

  String get pickupBuilding {
    if (_selectedInpost == null) return '';
    final address = _selectedInpost!.address;
    final separator = AddressConstants.inpostAddressSeparator;
    final index = address.indexOf(separator);

    // If separator exists, building is the second part; otherwise use the name
    return index >= 0 ? address.substring(index + separator.length).trim() : _selectedInpost!.name;
  }

  String get pickupAddress {
    if (_selectedInpost == null) return '';
    final address = _selectedInpost!.address;
    final separator = AddressConstants.inpostAddressSeparator;
    final index = address.indexOf(separator);

    // Get the street part
    String street = index >= 0 ? address.substring(0, index).trim() : address.trim();
    // Combine with postcode
    return [street, _selectedInpost!.postcode].where((s) => s.isNotEmpty).join(', ');
  }

  List<PostageSizeInfo> _postageSizeInfos = [];
  List<PostageSizeInfo> get postageSizeInfos => _postageSizeInfos;

  String _mobilePhoneNumber = '';
  String get mobilePhoneNumber => _mobilePhoneNumber;
  bool _hasEditedMobilePhone = false;
  int _checkoutSession = 0;

  void setMobilePhoneNumber(String value) {
    if (_isCheckoutInProgress) return;
    // Clearing a prefilled number is also an intentional edit.
    _hasEditedMobilePhone = true;
    _mobilePhoneNumber = value;
    _mobilePhoneError = null;
    notifyListeners();
  }

  Future<void> prefillMobilePhoneNumber() async {
    final session = _checkoutSession;
    final profile = await fetchUserProfile();
    if (session != _checkoutSession || _hasEditedMobilePhone || _isCheckoutInProgress) return;
    _mobilePhoneNumber = profile?.phoneNumber ?? '';
    notifyListeners();
  }

  InpostShippingMethod? _selectedInpostShippingMethod;
  InpostShippingMethod? get selectedInpostShippingMethod => _selectedInpostShippingMethod;
  bool _showLocker = false;
  bool get showLocker => _showLocker;

  DeliveryType _deliveryChoice = DeliveryType.undefined;
  DeliveryType get deliveryChoice => _deliveryChoice;
  void setDeliveryChoice(DeliveryType val) {
    if (_isCheckoutInProgress) return;
    _deliveryChoice = val;
    _deliveryError = null;
    notifyListeners();
  }

  void setShowLocker(bool val) {
    _showLocker = val;
    notifyListeners();
  }

  void setSelectedInpost(Inpost? data) {
    if (_isCheckoutInProgress) return;
    _selectedInpost = data;
    _deliveryError = null;
    notifyListeners();
  }

  void setSelectedInpostShippingMethod(InpostShippingMethod? method) {
    if (_isCheckoutInProgress) return;
    _selectedInpostShippingMethod = method;
    _deliveryError = null;
    notifyListeners();
  }

  /// Unmodifiable list of items in the basket
  List<Product> get basketItems => List.unmodifiable(_basketItems);

  /// Total price of all items in the basket
  double get itemTotal => _basketItems.fold(0, (sum, item) => sum + item.price);

  /// Security fee retrieved from product from backend
  double get securityFee => _basketItems.fold(0, (sum, item) => sum + (item.securityFee ?? 0));

  /// postage fee
  double get postage => (_selectedInpostShippingMethod?.pricePence.toDouble() ?? 0) / 100;

  /// Total order amount including all fees
  double get total => itemTotal + securityFee + postage;

  // Shipping Address properties
  PlaceDetails? _shippingAddress;

  /// Currently selected shipping address
  PlaceDetails? get shippingAddress => _shippingAddress;

  /// Whether a valid shipping address has been selected
  bool get hasShippingAddress => _shippingAddress != null;

  //Whether user or logic has confirmed the shipping address
  bool _isShippingAddressConfirmed = false;
  bool get isShippingAddressConfirmed => _isShippingAddressConfirmed;
  set isShippingAddressConfirmed(bool value) {
    if (!_isCheckoutInProgress) _isShippingAddressConfirmed = value;
  }

  // Payment properties
  bool _hasPaymentMethod = false;
  String? _lastPaymentIntentId;

  String? get lastPaymentIntentId => _lastPaymentIntentId;

  /// Whether a payment method has been set
  bool get hasPaymentMethod => _selectedPaymentType != null || _hasPaymentMethod;

  /// Whether the order is ready for checkout (has both address and payment method)
  bool get canCheckout => hasShippingAddress && hasPaymentMethod && !_containsOwnProduct;

  void setAddressConfirmed(bool value) {
    if (_isCheckoutInProgress) return;
    isShippingAddressConfirmed = value;
    _deliveryError = null;
    notifyListeners();
  }

  // Existing basket methods
  bool addItem(Product product) {
    if (_isCheckoutInProgress || isOwnProduct(product)) {
      return false;
    }

    _basketItems.add(product);
    notifyListeners();
    return true;
  }

  void removeItem(Product product) {
    if (_isCheckoutInProgress) return;
    _basketItems.remove(product);
    notifyListeners();
  }

  void clearBasket() {
    if (_isCheckoutInProgress) return;
    _basketItems.clear();
    notifyListeners();
  }

  bool isOwnProduct(Product product) {
    final currentUserId = _currentUserIdProvider()?.trim();
    final sellerId = product.userId?.trim();
    return currentUserId != null &&
        currentUserId.isNotEmpty &&
        sellerId != null &&
        sellerId.isNotEmpty &&
        sellerId == currentUserId;
  }

  bool get _containsOwnProduct => _basketItems.any(isOwnProduct);

  // Shipping address methods

  /// Sets the shipping address from Google Places API result
  /// Notifies listeners when address is updated
  void setShippingAddress(PlaceDetails address) {
    if (_isCheckoutInProgress) return;
    _shippingAddress = address;
    _deliveryError = null;
    notifyListeners();
  }

  /// Clears the currently selected shipping address
  void clearShippingAddress() {
    if (_isCheckoutInProgress) return;
    _shippingAddress = null;
    notifyListeners();
  }

  PaymentType? _selectedPaymentType;

  PaymentType? get selectedPaymentType => _selectedPaymentType;
  // Payment method methods
  void setPaymentType(PaymentType type) {
    if (_isCheckoutInProgress) return;
    _selectedPaymentType = type;
    _hasPaymentMethod = true;
    notifyListeners();
  }

  PaymentType? getPaymentType() {
    return selectedPaymentType;
  }

  /// Sets whether a payment method has been configured
  void setPaymentMethod(bool hasPayment) {
    if (_isCheckoutInProgress) return;
    _hasPaymentMethod = hasPayment;
    if (!hasPayment) {
      _selectedPaymentType = null;
    }
    notifyListeners();
  }

  /// Clears any selected payment method.
  void clearPaymentMethod() {
    if (_isCheckoutInProgress) return;
    _selectedPaymentType = null;
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
    if (_isCheckoutInProgress) return;
    _checkoutSession++;
    _hasEditedMobilePhone = false;
    _mobilePhoneNumber = '';
    _deliveryError = null;
    _mobilePhoneError = null;
    _checkoutAttempt = null;
    _shippingAddress = null;
    _selectedPaymentType = null;
    _hasPaymentMethod = false;
    isShippingAddressConfirmed = false;
    _selectedInpost = null;
    _selectedInpostShippingMethod = null;
    _lastPaymentIntentId = null;
    _basketItems.clear();
    _deliveryChoice = DeliveryType.undefined;
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

  Future<void> onConfirmLocation(String postalCode, String country) async {
    await fetchNearestInposts(postalCode, country);
    navigator.goBack();
  }

  // fetch nearest InPost locker for pickup
  Future<void> fetchNearestInposts(String postalCode, String country) async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchNearestInposts(postalCode, country);
      final parsedInposts = result.isSuccess && result.value != null
          ? _parseInpostList(result.value)
          : const <InpostSearchResult>[];

      _nearestInposts
        ..clear()
        ..addAll(parsedInposts);

      if (parsedInposts.isNotEmpty) {
        _showLocker = true;
        _status = Status.success;
      } else {
        _showLocker = false;
        _status = Status.failure(
          result.isSuccess
              ? 'Pickup points currently unavailable, please try again later'
              : (result.error ?? 'Pickup points currently unavailable, please try again later'),
        );
        SafeLog.event(
          AppLogEvent.checkoutPickupPointsFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      _showLocker = false;
      _nearestInposts.clear();
      _status = Status.failure('Pickup points currently unavailable, please try again later');
      SafeLog.event(
        AppLogEvent.checkoutPickupPointsFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  Future<void> fetchShippingMethodsForInpost() async {
    _status = Status.loading;
    notifyListeners();

    try {
      final result = await checkoutRepository.fetchShippingMethodsForInpost(
        basketItems.first.id,
        selectedInpost!.id,
        selectedInpost!.postcode,
        selectedInpost!.country,
      );

      final parsedShippingMethods = result.isSuccess && result.value != null
          ? _parseShippingMethodList(result.value)
          : const <InpostShippingMethod>[];

      _inpostShippingMethods
        ..clear()
        ..addAll(parsedShippingMethods);

      if (parsedShippingMethods.isNotEmpty) {
        _status = Status.success;
        await _autoSelectShippingMethod();
      } else {
        _status = Status.failure(
          result.isSuccess
              ? 'InPost shipping methods currently unavailable, please try again later'
              : (result.error ?? 'InPost shipping methods currently unavailable, please try again later'),
        );
        SafeLog.event(
          AppLogEvent.checkoutShippingMethodsFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      _inpostShippingMethods.clear();
      _status = Status.failure('InPost shipping methods currently unavailable, please try again later');
      SafeLog.event(
        AppLogEvent.checkoutShippingMethodsFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  Future<void> _autoSelectShippingMethod() async {
    if (_basketItems.isEmpty || _inpostShippingMethods.isEmpty) return;

    if (_postageSizeInfos.isEmpty) {
      await fetchPostageSizes();
      if (_postageSizeInfos.isEmpty) {
        setSelectedInpostShippingMethod(_inpostShippingMethods.firstOrNull);
        return;
      }
    }

    final postageSizeId = _basketItems.first.postageSizeId;
    final info = _postageSizeInfos.firstWhere(
      (info) => info.id == postageSizeId,
      orElse: () => _postageSizeInfos.first,
    );

    final label = info.size.label; // e.g., "Small"
    final matchingMethod = _inpostShippingMethods.where((method) => method.name.contains(label)).firstOrNull;

    setSelectedInpostShippingMethod(matchingMethod ?? _inpostShippingMethods.firstOrNull);
  }

  Future<void> fetchPostageSizes({bool forceRefresh = false}) async {
    if (!forceRefresh && _postageSizeInfos.isNotEmpty) return;

    _status = Status.loading;
    notifyListeners();

    try {
      final result = await _donationRepository.fetchPostageSizes();

      if (result.isSuccess && result.value != null) {
        _postageSizeInfos = result.value!;
        _status = Status.success;
      }
    } catch (_) {
      _status = Status.failure('Could not load postage sizes');
      SafeLog.event(
        AppLogEvent.donationPostageSizesLoadFailed,
        level: SafeLogLevel.severe,
      );
    }

    notifyListeners();
  }

  // Future<void> storeLockerInFirestore() async {
  //   try {
  //     await checkoutRepository.storeLockerInFirestore(selectedInpost!);
  //   } catch (_) {
  //   }
  // }

  // Future<Result> fetchUserLocker() async {
  //   final result = await checkoutRepository.fetchUserLocker();
  //   if (result.isSuccess) {
  //     final doc = result.value;
  //     if (doc != null && doc.exists && doc.data() is Map<String, dynamic>) {
  //       final data = doc.data() as Map<String, dynamic>;
  //       final id = (data[FirestoreConstants.id] ?? '').toString();
  //       final name = (data[FirestoreConstants.name] ?? '').toString();
  //       final carrier = (data[FirestoreConstants.carrier] ?? '').toString();
  //       final address = (data[FirestoreConstants.address] ?? '').toString();
  //       final postcode = (data[FirestoreConstants.postcode] ?? '').toString();
  //       final city = (data[FirestoreConstants.city] ?? '').toString();
  //       final country = (data[FirestoreConstants.country] ?? '').toString();
  //       final lat = (data[FirestoreConstants.lat] ?? '').toString();
  //       final long = (data[FirestoreConstants.long] ?? '').toString();
  //
  //       if (id.isNotEmpty && name.isNotEmpty && address.isNotEmpty && postcode.isNotEmpty) {
  //         _selectedInpost = Inpost(
  //           id: id,
  //           name: name,
  //           carrier: carrier,
  //           address: address,
  //           postcode: postcode,
  //           city: city,
  //           country: country,
  //           lat: lat,
  //           long: long,
  //         );
  //         _showLocker = true;
  //         _status = Status.success;
  //       } else {
  //         _showLocker = false;
  //         _selectedInpost = null;
  //       }
  //     } else {
  //       _showLocker = false;
  //       _selectedInpost = null;
  //     }
  //     notifyListeners();
  //     return Result.success(null);
  //   } else {
  //     _status = Status.failure(result.error?.toString() ?? 'Unknown error');
  //     notifyListeners();
  //     return Result.failure(result.error);
  //   }
  // }
  //
  // /// Store a dummy order in Firestore
  // Future<void> storeOrderInFirestore() async {
  //   final Map<String, dynamic> orderData = {
  //     'items': _basketItems
  //         .map(
  //           (item) => {
  //             'id': item.id,
  //             'name': item.name,
  //             'price': item.price,
  //             'image': item.productImages.isNotEmpty ? item.productImages.first : null,
  //           },
  //         )
  //         .toList(),
  //     'shipping_address': {
  //       'formatted_address': formattedShippingAddress,
  //       ...shippingAddressComponents,
  //       'latitude': _shippingAddress?.latitude,
  //       'longitude': _shippingAddress?.longitude,
  //     },
  //     'totals': {
  //       'item_total': itemTotal,
  //       'security_fee': securityFee,
  //       'postage': postage,
  //       'total': total,
  //     },
  //     'created_at': DateTime.now().toIso8601String(),
  //   };
  //   try {
  //     await checkoutRepository.storeOrderInFirestore(orderData);
  //   } catch (_) {
  //     rethrow;
  //   }
  // }

  _CheckoutDeliveryDetails _captureDeliveryDetails() {
    return _CheckoutDeliveryDetails(
      deliveryChoice: _deliveryChoice,
      pickupPoint: _selectedInpost,
      shippingMethod: _selectedInpostShippingMethod,
      telephone: _mobilePhoneNumber,
      shippingAddress: _buildShippingAddress(),
      hasValidHomeAddress: isShippingAddressConfirmed && validateShippingAddress(),
    );
  }

  /// The same delivery requirements apply before payment and order submission.
  bool _validateDeliveryDetails(_CheckoutDeliveryDetails details) {
    _deliveryError = null;
    _mobilePhoneError = null;

    if (details.deliveryChoice == DeliveryType.undefined) {
      _deliveryError = AppStrings.checkoutDeliveryOptionRequired;
    } else if (details.deliveryChoice == DeliveryType.home && !details.hasValidHomeAddress) {
      _deliveryError = AppStrings.checkoutShippingAddressRequired;
    } else if (details.pickupPoint == null) {
      // The existing payment integration requires a pickup point.
      _deliveryError = AppStrings.checkoutPickupLockerRequired;
    } else if (details.deliveryChoice == DeliveryType.pickup && !_hasCompletePickupPoint(details.pickupPoint!)) {
      _deliveryError = AppStrings.checkoutPickupDetailsIncomplete;
    } else if (details.shippingMethod == null) {
      _deliveryError = AppStrings.checkoutShippingMethodRequired;
    }

    if (details.deliveryChoice == DeliveryType.pickup && details.telephone.trim().isEmpty) {
      _mobilePhoneError = AppStrings.checkoutMobilePhoneRequired;
    }

    return _deliveryError == null && _mobilePhoneError == null;
  }

  bool validateDeliveryDetails() {
    if (_isCheckoutInProgress) return true;
    final isValid = _validateDeliveryDetails(_captureDeliveryDetails());
    notifyListeners();
    return isValid;
  }

  Future<bool> payWithPaymentSheet() async {
    if (_isCheckoutInProgress) return false;
    if (basketItems.isEmpty) {
      _createOrderStatus = Status.failure('Your basket is empty');
      notifyListeners();
      return false;
    }

    if (_containsOwnProduct) {
      _createOrderStatus = Status.failure(
        AppStrings.checkoutOwnProductNotAllowed,
      );
      notifyListeners();
      return false;
    }

    if (_selectedPaymentType == null) {
      _createOrderStatus = Status.failure(
        AppStrings.checkoutPaymentMethodRequired,
      );
      notifyListeners();
      return false;
    }

    final delivery = _captureDeliveryDetails();
    if (!_validateDeliveryDetails(delivery)) {
      _createOrderStatus = Status.failure(_deliveryError ?? _mobilePhoneError!);
      notifyListeners();
      return false;
    }

    final attempt = _CheckoutAttempt(
      productId: basketItems.first.id,
      paymentType: _selectedPaymentType!,
      delivery: delivery,
    );
    _checkoutAttempt = attempt;
    _isCheckoutInProgress = true;
    _createOrderStatus = Status.loading;
    _lastPaymentIntentId = null;
    notifyListeners();

    var paid = false;
    try {
      // To create a PaymentIntent and return the client_secret
      final response = await checkoutRepository.createPaymentIntent(
        productId: attempt.productId,
        shippingMethodId: delivery.shippingMethod!.id,
        pickupPointId: delivery.pickupPoint!.id,
        country: delivery.pickupPoint!.country,
        postalCode: delivery.pickupPoint!.postcode,
      );

      if (response.isSuccess && response.value != null) {
        final paymentResponse = response.value!;

        Stripe.publishableKey = paymentResponse.publishableKey;
        await Stripe.instance.applySettings();

        final setupParams = _buildPaymentSheetParameters(
          paymentResponse,
          attempt.paymentType,
        );

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: setupParams,
        );

        // Present the native PaymentSheet (it will show ApplePay/GooglePay if available)
        await Stripe.instance.presentPaymentSheet();
        _lastPaymentIntentId = paymentResponse.paymentIntentId;
        paid = true;
        return true;
      } else {
        _createOrderStatus = Status.failure('Payment could not be completed. Please try again.');
        _lastPaymentIntentId = null;
        SafeLog.event(
          AppLogEvent.checkoutPaymentIntentFailed,
          level: SafeLogLevel.severe,
        );
        notifyListeners();
        return false;
      }
    } on StripeException {
      _createOrderStatus = Status.failure('Payment could not be completed. Please try again.');
      SafeLog.event(
        AppLogEvent.checkoutPaymentFailed,
        level: SafeLogLevel.severe,
      );
      _lastPaymentIntentId = null;
      notifyListeners();
      return false;
    } catch (_) {
      _createOrderStatus = Status.failure('Payment could not be completed. Please try again.');
      SafeLog.event(
        AppLogEvent.checkoutPaymentFailed,
        level: SafeLogLevel.severe,
      );
      _lastPaymentIntentId = null;
      notifyListeners();
      return false;
    } finally {
      if (!paid) {
        _checkoutAttempt = null;
        _isCheckoutInProgress = false;
        notifyListeners();
      }
    }
  }

  Future<void> createOrder() async {
    if (_isCreatingOrder) return;
    // A caller must wait for the payment sheet to finish before creating an
    // order. In particular, do not unlock an attempt whose payment is pending.
    if (_isCheckoutInProgress && _lastPaymentIntentId == null) return;

    _isCreatingOrder = true;
    try {
      if (basketItems.isEmpty) {
        _createOrderStatus = Status.failure('Your basket is empty');
        return;
      }
      if (_containsOwnProduct) {
        _createOrderStatus = Status.failure(AppStrings.checkoutOwnProductNotAllowed);
        return;
      }

      final attempt = _checkoutAttempt;
      final paymentIntentId = _lastPaymentIntentId?.trim() ?? '';
      if (attempt == null || paymentIntentId.isEmpty) {
        _createOrderStatus = Status.failure('Payment intent is missing');
        return;
      }
      if (!_validateDeliveryDetails(attempt.delivery)) {
        _createOrderStatus = Status.failure(_deliveryError ?? _mobilePhoneError!);
        return;
      }

      _isCheckoutInProgress = true;
      _createOrderStatus = Status.loading;
      notifyListeners();

      final delivery = attempt.delivery;
      final Map<String, dynamic> orderData = {
        "productId": attempt.productId,
        "paymentIntentId": paymentIntentId,
        "shipping": {"address": delivery.shippingAddress, "name": 'Customer', "telephone": delivery.telephone},
        if (delivery.deliveryChoice == DeliveryType.pickup)
          "pickupPoint": _buildPickupPointPayload(delivery.pickupPoint!),
      };
      final result = await checkoutRepository.createOrder(orderData);
      if (result.isSuccess) {
        _createOrderStatus = Status.success;
      } else {
        _createOrderStatus = Status.failure(result.error ?? "");
        SafeLog.event(
          AppLogEvent.checkoutOrderCreationFailed,
          level: SafeLogLevel.warning,
        );
      }
    } catch (_) {
      _createOrderStatus = Status.failure('Order could not be created. Please try again.');
      SafeLog.event(
        AppLogEvent.checkoutOrderCreationFailed,
        level: SafeLogLevel.severe,
      );
    } finally {
      _isCreatingOrder = false;
      _isCheckoutInProgress = false;
      notifyListeners();
    }
  }

  Future<UserCredentials?> fetchUserProfile() async {
    try {
      final result = await checkoutRepository.fetchUserProfile();
      if (result.isSuccess) {
        if (result.value == null) {
          SafeLog.event(
            AppLogEvent.checkoutProfileMissing,
            level: SafeLogLevel.warning,
          );
          return null;
        }
        return result.value;
      } else {
        return null;
      }
    } catch (_) {
      SafeLog.event(
        AppLogEvent.checkoutProfileLoadFailed,
        level: SafeLogLevel.severe,
      );
      return null;
    }
  }

  Map<String, dynamic> _buildShippingAddress() {
    return switch (_deliveryChoice) {
      DeliveryType.pickup => {
        "line1": _pickupAddressLine(selectedInpost?.address ?? ''),
        "city": selectedInpost?.city.trim() ?? '',
        "postal_code": selectedInpost?.postcode.trim() ?? '',
        "country": _countryCode(selectedInpost?.country ?? 'GB'),
      },
      DeliveryType.home => {
        "line1": _shippingAddress?.line1 ?? '',
        "city": shippingAddressComponents[AddressConstants.cityKey] ?? "",
        "state": shippingAddressComponents[AddressConstants.stateKey] ?? "",
        "postal_code": shippingAddressComponents[AddressConstants.postalCodeKey] ?? "",
        "country": _countryCode(
          shippingAddressComponents[AddressConstants.countryKey] ?? AppStrings.unitedKingdomText,
        ),
      },
      DeliveryType.undefined => {},
    };
  }

  Map<String, dynamic> _buildPickupPointPayload(Inpost pickupPoint) {
    return {
      "id": pickupPoint.id,
      "name": pickupPoint.name,
      "addressLine1": _pickupAddressLine(pickupPoint.address),
      "city": pickupPoint.city.trim(),
      "postalCode": pickupPoint.postcode.trim(),
      "country": _countryCode(pickupPoint.country),
      "carrier": pickupPoint.carrier,
    };
  }

  bool _hasCompletePickupPoint(Inpost pickupPoint) {
    return pickupPoint.id.trim().isNotEmpty &&
        pickupPoint.name.trim().isNotEmpty &&
        _pickupAddressLine(pickupPoint.address).isNotEmpty &&
        pickupPoint.city.trim().isNotEmpty &&
        pickupPoint.postcode.trim().isNotEmpty &&
        _countryCode(pickupPoint.country).length == 2;
  }

  String _pickupAddressLine(String address) {
    return address.replaceAll(AddressConstants.inpostAddressSeparator, ', ').trim();
  }

  String _countryCode(String country) {
    final normalised = country.trim().toUpperCase();
    if (normalised.length == 2) {
      return normalised;
    }
    if (normalised == AppStrings.unitedKingdomText.toUpperCase()) {
      return 'GB';
    }
    return normalised;
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

  List<InpostSearchResult> _parseInpostList(dynamic payload) {
    final dynamic listData = payload is Map<String, dynamic>
        ? (payload['pickupPoints'] ?? payload['lockers'] ?? payload['items'])
        : payload;

    if (listData is! List) return [];

    final lockers = <InpostSearchResult>[];
    for (final item in listData) {
      final locker = _parseInpostItem(item);
      if (locker != null) {
        lockers.add(locker);
      }
    }
    return lockers;
  }

  List<InpostShippingMethod> _parseShippingMethodList(dynamic payload) {
    final dynamic rawList = payload is Map<String, dynamic>
        ? (payload['shippingMethods'] ?? payload['data'] ?? payload['items'])
        : payload;
    if (rawList is! List) return [];
    final List<dynamic> jsonList = rawList;

    final shippingMethods = jsonList
        .map((json) => InpostShippingMethod.fromJson(json))
        .where((method) => method.name.startsWith('InPost Locker'))
        .toList();
    return shippingMethods;
  }

  InpostSearchResult? _parseInpostItem(dynamic item) {
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
    final carrier = (map['carrier'] ?? '').toString();
    final address = readFirst(['addressLine1', 'line1', 'street']);
    final postcode = readFirst(['postcode', 'postalCode', 'postCode']);
    final city = readFirst(['city']);
    final country = readFirst(['country']);
    final lat = readFirst(['lat', 'latitude']);
    final long = readFirst(['long', 'lng', 'longitude']);
    if (id.isEmpty || name.isEmpty || address.isEmpty || postcode.isEmpty) {
      return null;
    }

    return InpostSearchResult(
      inpost: Inpost(
        id: id,
        name: name,
        carrier: carrier,
        address: address,
        postcode: postcode,
        city: city,
        country: country,
        lat: lat,
        long: long,
      ),
      distanceMetres: map['distanceMeters'],
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

  Future<bool> showPickupPointSelection() async {
    final result = await navigator.navigateTo(AppRoutes.pickupPointSelector);

    return result == true;
  }

  void goBack(bool pickupPointSelected) {
    navigator.goBack(pickupPointSelected);
  }
}

class _CheckoutAttempt {
  const _CheckoutAttempt({required this.productId, required this.paymentType, required this.delivery});

  final String productId;
  final PaymentType paymentType;
  final _CheckoutDeliveryDetails delivery;
}

class _CheckoutDeliveryDetails {
  _CheckoutDeliveryDetails({
    required this.deliveryChoice,
    required this.pickupPoint,
    required this.shippingMethod,
    required this.telephone,
    required Map<String, dynamic> shippingAddress,
    required this.hasValidHomeAddress,
  }) : shippingAddress = Map.unmodifiable(shippingAddress);

  final DeliveryType deliveryChoice;
  final Inpost? pickupPoint;
  final InpostShippingMethod? shippingMethod;
  final String telephone;
  final Map<String, dynamic> shippingAddress;
  final bool hasValidHomeAddress;
}
