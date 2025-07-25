import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/checkout/widgets/shipping_address_widget.dart';
import 'package:flutter/material.dart';

class CheckoutViewModel extends ChangeNotifier {
  final List<Product> _basketItems = [];

  List<Product> get basketItems => List.unmodifiable(_basketItems);

  double get itemTotal => _basketItems.fold(0, (sum, item) => sum + item.price);

  double get securityFee => itemTotal * 0.1;

  double get postage => 2.99;

  double get total => itemTotal + securityFee + postage;

  // Shipping Address properties
  PlaceDetails? _shippingAddress;
  PlaceDetails? get shippingAddress => _shippingAddress;
  
  bool get hasShippingAddress => _shippingAddress != null;
  
  // Payment properties  
  bool _hasPaymentMethod = false;
  bool get hasPaymentMethod => _hasPaymentMethod;
  
  // Checkout readiness
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
  void setShippingAddress(PlaceDetails address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void clearShippingAddress() {
    _shippingAddress = null;
    notifyListeners();
  }

  // Payment method methods
  void setPaymentMethod(bool hasPayment) {
    _hasPaymentMethod = hasPayment;
    notifyListeners();
  }

  // Get formatted shipping address for display
  String get formattedShippingAddress {
    return _shippingAddress?.formattedAddress ?? '';
  }

  // Get shipping address components for backend/order processing
  Map<String, String> get shippingAddressComponents {
    if (_shippingAddress == null) return {};
    
    return {
      'street': '${_shippingAddress!.streetNumber} ${_shippingAddress!.route}'.trim(),
      'city': _shippingAddress!.locality,
      'state': _shippingAddress!.administrativeAreaLevel1,
      'postalCode': _shippingAddress!.postalCode,
      'country': _shippingAddress!.country,
    };
  }

  // Reset checkout state (useful for new orders)
  void resetCheckout() {
    _shippingAddress = null;
    _hasPaymentMethod = false;
    notifyListeners();
  }

  // Validate shipping address before checkout
  bool validateShippingAddress() {
    if (_shippingAddress == null) return false;
    
    final components = shippingAddressComponents;
    return components['street']?.isNotEmpty == true &&
           components['city']?.isNotEmpty == true &&
           components['postalCode']?.isNotEmpty == true;
  }

  // Process checkout (you can expand this with your backend logic)
  Future<bool> processCheckout() async {
    if (!canCheckout) return false;
    if (!validateShippingAddress()) return false;
    
    try {
      // Your checkout logic here
      // Example structure for API call:
      final orderData = {
        'items': basketItems.map((item) => {
          'id': item.id,
          'name': item.name,
          'price': item.price,
          // Add other product fields as needed
        }).toList(),
        'shipping_address': {
          'formatted_address': formattedShippingAddress,
          'street': shippingAddressComponents['street'],
          'city': shippingAddressComponents['city'],
          'state': shippingAddressComponents['state'],
          'postal_code': shippingAddressComponents['postalCode'],
          'country': shippingAddressComponents['country'],
          'latitude': _shippingAddress?.latitude,
          'longitude': _shippingAddress?.longitude,
        },
        'totals': {
          'item_total': itemTotal,
          'security_fee': securityFee,
          'postage': postage,
          'total': total,
        }
      };
      
      debugPrint('Processing order: $orderData');
      
      return true;
    } catch (e) {
      debugPrint('Checkout error: $e');
      return false;
    }
  }
}