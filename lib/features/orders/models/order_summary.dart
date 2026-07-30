class OrderSummary {
  static const String fallbackCurrency = 'GBP';
  static const String fallbackProductName = 'Item unavailable';

  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final String size;
  final String charityLogoUrl;
  final int? itemPriceMinor;
  final int? totalAmountMinor;
  final String currency;
  final String deliveryState;
  final String deliveryLabel;

  const OrderSummary({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.charityLogoUrl,
    required this.itemPriceMinor,
    required this.totalAmountMinor,
    required this.currency,
    required this.deliveryState,
    required this.deliveryLabel,
  });

  static OrderSummary? tryFromOrderJson(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(value);
    final id = _readRequiredString(json['id']);
    if (id == null) {
      return null;
    }

    final productId = _readString(json['productId']);
    final productName = _readString(json['productName']);

    return OrderSummary(
      id: id,
      productId: productId,
      productName: productName.isEmpty ? fallbackProductName : productName,
      imageUrl: '',
      size: '',
      charityLogoUrl: '',
      itemPriceMinor: _readNonNegativeInteger(json['productAmount']),
      totalAmountMinor: _readNonNegativeInteger(json['totalAmount']),
      currency: normaliseCurrency(json['currency']),
      deliveryState: _readFirstString([
        json['deliveryState'],
        json['status'],
      ]),
      deliveryLabel: _readString(json['deliveryLabel']),
    );
  }

  static String normaliseCurrency(dynamic value) {
    final currency = _readString(value).toUpperCase();
    return RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : fallbackCurrency;
  }

  OrderSummary copyWith({
    String? productName,
    String? imageUrl,
    String? size,
    String? charityLogoUrl,
  }) {
    return OrderSummary(
      id: id,
      productId: productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      charityLogoUrl: charityLogoUrl ?? this.charityLogoUrl,
      itemPriceMinor: itemPriceMinor,
      totalAmountMinor: totalAmountMinor,
      currency: currency,
      deliveryState: deliveryState,
      deliveryLabel: deliveryLabel,
    );
  }

  static String? _readRequiredString(dynamic value) {
    final string = _readString(value);
    return string.isEmpty ? null : string;
  }

  static String _readFirstString(Iterable<dynamic> values) {
    for (final value in values) {
      final string = _readString(value);
      if (string.isNotEmpty) {
        return string;
      }
    }
    return '';
  }

  static String _readString(dynamic value) {
    return value is String ? value.trim() : '';
  }

  static int? _readNonNegativeInteger(dynamic value) {
    int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num && value.isFinite && value == value.roundToDouble()) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    }

    return parsed != null && parsed >= 0 ? parsed : null;
  }
}
