import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';

void main() {
  test('DonationRequest sends postage_size as the backend enum value', () {
    final request = DonationRequest(
      name: 'Jumper',
      description: 'Warm wool jumper',
      categoryId: 'category-id',
      charityId: 'charity-id',
      quality: 'Good',
      size: 'M',
      postageSizeId: 'HnGf34ED',
      donation: 12,
      price: 12,
    );

    expect(request.toJson()['postage_size'], 'medium');
  });
}
