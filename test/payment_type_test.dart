import 'package:cherry_mvp/features/checkout/payment_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  // Also run with --platform chrome to verify the real kIsWeb exclusion,
  // including browsers reporting an iOS or Android target platform.
  for (final platform in TargetPlatform.values) {
    test('payment platform eligibility on ${platform.name} (web: $kIsWeb)', () {
      debugDefaultTargetPlatformOverride = platform;

      expect(PaymentType.card.isPlatformEligible, isTrue);
      expect(
        PaymentType.apple.isPlatformEligible,
        !kIsWeb && platform == TargetPlatform.iOS,
      );
      expect(
        PaymentType.google.isPlatformEligible,
        !kIsWeb && platform == TargetPlatform.android,
      );
    });
  }
}
