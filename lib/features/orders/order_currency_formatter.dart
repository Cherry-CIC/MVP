import 'package:cherry_mvp/features/orders/models/order_summary.dart';

class OrderCurrencyFormatter {
  const OrderCurrencyFormatter._();

  static String? formatItemPrice(OrderSummary order) {
    final minorUnits = order.itemPriceMinor;
    if (minorUnits == null) {
      return null;
    }

    return formatMinorUnits(
      minorUnits: minorUnits,
      currency: order.currency,
    );
  }

  static String formatMinorUnits({
    required int minorUnits,
    required String currency,
  }) {
    final amount = (minorUnits / 100).toStringAsFixed(2);
    if (currency == 'GBP') {
      return '£$amount';
    }
    return '$currency $amount';
  }
}
