import 'dart:convert';

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

  test('DonationRequest preserves listing text when encoded as an API payload', () {
    const title = 'route 66 shirt!';
    const description = 'Women’s "Route 66" T-shirt, size 10/12 & 100% cotton.\nCafé print: £5.50 👕';
    final request = DonationRequest(
      name: title,
      description: description,
      categoryId: 'category-id',
      charityId: 'charity-id',
      quality: 'Good',
      size: 'M',
      postageSizeId: 'HnGf34ED',
      donation: 12,
      price: 12,
    );

    final payload = jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>;

    expect(payload['name'], title);
    expect(payload['description'], description);
  });
}
