import 'package:cherry_mvp/core/utils/validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Listing title and description validation', () {
    for (final value in [
      'White cotton shirt',
      'route 66 shirt!',
      '66',
      '  route 66 shirt!  ',
      '''Women's "Route 66" T-shirt (size 10/12) & belt: £5.50, 100% cotton.''',
      'Café Noël: très bon état 👕',
      'シャツ 66',
      'Size 12.\nWorn 2-3 times; no marks!',
    ]) {
      test('accepts normal listing text: $value', () {
        expect(validateDonationFormFields(value), isNull);
      });
    }

    for (final value in [null, '', ' ', '\n\t ']) {
      test('rejects empty or whitespace-only text: $value', () {
        expect(validateDonationFormFields(value), 'This cannot be empty');
      });
    }

    for (final value in ['a', '6', '!', ' a ']) {
      test('keeps the two-character minimum: $value', () {
        expect(validateDonationFormFields(value), 'This must be at least 2 characters');
      });
    }
  });
}
