import 'package:flutter/foundation.dart';

enum PaymentType {
  card,
  google,
  apple;

  /// Platform eligibility for the existing native wallet integration only.
  /// Does not check wallet readiness, merchant configuration or payment success.
  bool get isPlatformEligible {
    if (this == PaymentType.card) return true;
    if (kIsWeb) return false;

    return switch (this) {
      PaymentType.card => true,
      PaymentType.google => defaultTargetPlatform == TargetPlatform.android,
      PaymentType.apple => defaultTargetPlatform == TargetPlatform.iOS,
    };
  }
}
