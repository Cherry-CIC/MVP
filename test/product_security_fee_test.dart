import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/security_fee.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/unexpected_api_service.dart';

class _Api extends UnexpectedApiService {}

Product _product(double price, {double? securityFee}) => Product.fromJson({
  'id': 'p1',
  'userId': 'seller',
  'name': 'Nike Jumper',
  'description': 'desc',
  'product_images': <String>[],
  'quality': 'Excellent',
  'size': 'XL',
  'price': price,
  'donation': price,
  'securityFee': securityFee,
  'number': 1,
  'likes': 0,
  'postageSize': 'small',
  'status': 'active',
});

Future<void> _pump(WidgetTester tester, Widget child) async {
  final viewModel = ProductViewModel(
    productRepository: ProductRepository(_Api()),
    navigator: NavigationProvider(),
    currentUserIdProvider: () => 'buyer',
  );
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: Scaffold(body: SizedBox(width: 400, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('calculateSecurityFee', () {
    final cases = <double, double>{
      0: 1.00, // zero raised: minimum applies
      0.50: 1.00,
      4.99: 1.00, // below £10: minimum applies
      5: 1.00,
      9.99: 1.00,
      10: 1.00, // 10% equals the minimum
      10.10: 1.01, // just above £10
      10.05: 1.01, // 100.5p rounds up, matching the backend
      15: 1.50,
      20: 2.00,
      100: 10.00,
      1000: 100.00, // large
    };
    cases.forEach((raised, fee) {
      test('£$raised raised gives £$fee PSF', () {
        expect(calculateSecurityFee(raised), fee);
      });
    });
  });

  group('Product PSF helpers', () {
    test('uses the API securityFee when present', () {
      final product = _product(15, securityFee: 1.5);
      expect(product.purchaseSecurityFee, 1.5);
      expect(product.priceIncludingSecurityFee, 16.5);
    });

    test('falls back to the calculated PSF when securityFee is missing', () {
      final product = _product(4);
      expect(product.purchaseSecurityFee, 1.0);
      expect(product.priceIncludingSecurityFee, 5.0);
    });
  });

  group('ProductCard', () {
    final cases = <double, List<String>>{
      0: ['£0.00', '£1.00'], // [raised, total incl. PSF]
      4.99: ['£4.99', '£5.99'],
      10: ['£10.00', '£11.00'],
      15: ['£15.00', '£16.50'],
      150: ['£150.00', '£165.00'],
    };
    cases.forEach((raised, texts) {
      testWidgets('£$raised raised shows ${texts[0]} raised and ${texts[1]} incl. PSF', (tester) async {
        await _pump(tester, ProductCard(product: _product(raised)));

        expect(find.text(texts[0]), findsOneWidget);
        expect(find.text(texts[1]), findsOneWidget);
      });
    });

    testWidgets('uses the API securityFee for the total', (tester) async {
      await _pump(tester, ProductCard(product: _product(15, securityFee: 1.5)));

      expect(find.text('£15.00'), findsOneWidget);
      expect(find.text('£16.50'), findsOneWidget);
    });
  });

  group('ProductInformation', () {
    testWidgets('shows raised proceeds and total including PSF separately', (tester) async {
      await _pump(tester, ProductInformation(product: _product(15, securityFee: 1.5)));

      expect(find.text('£15.00'), findsOneWidget);
      expect(find.text('£16.50'), findsOneWidget);
    });

    testWidgets('applies the £1 minimum below £10', (tester) async {
      await _pump(tester, ProductInformation(product: _product(5)));

      expect(find.text('£5.00'), findsOneWidget);
      expect(find.text('£6.00'), findsOneWidget);
    });
  });
}
