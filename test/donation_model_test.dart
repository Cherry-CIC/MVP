import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';

void main() {
  test('DonationRequest serialises the backend postage size ID', () {
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

    expect(request.toJson()['postageSize'], 'HnGf34ED');
  });
}
