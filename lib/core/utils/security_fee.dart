import 'package:cherry_mvp/core/models/product.dart';

const double _securityFeeRate = 0.1;
const int _minimumSecurityFeePence = 100;

int _toPence(double gbp) => (gbp * 100).round();

/// Purchase Security Fee in GBP for [raisedProceeds]: the greater of 10% of
/// the raised proceeds or £1.00. Mirrors the backend's
/// `calculateSecurityFeePence`; the backend remains authoritative for payment.
double calculateSecurityFee(double raisedProceeds) {
  final feePence = (_toPence(raisedProceeds) * _securityFeeRate).round();
  return (feePence < _minimumSecurityFeePence ? _minimumSecurityFeePence : feePence) / 100;
}

extension ProductSecurityFee on Product {
  /// PSF from the API when present, otherwise calculated from [price].
  double get purchaseSecurityFee => securityFee ?? calculateSecurityFee(price);

  /// Raised proceeds plus PSF, summed in whole pence.
  double get priceIncludingSecurityFee => (_toPence(price) + _toPence(purchaseSecurityFee)) / 100;
}
