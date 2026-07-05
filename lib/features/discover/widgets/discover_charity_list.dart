import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/dummy_charity.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/discover/widgets/items_in_support.dart';

class DiscoverCharityList extends StatelessWidget {
  final List<DummyCharity> charities;
  final List<Product> products;

  const DiscoverCharityList({required this.charities, required this.products, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: charities.length,
      itemBuilder: (context, index) {
        final charity = charities[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              DiscoverCharityCard(
                title: charity.charityName,
                description: charity.description,
                imagePath: charity.charityImage,
                logoPath: charity.charityLogo,
                likes: charity.likes,
              ),
              SizedBox(height: 8),
              ItemsInSupport(products: products),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 24),
    );
  }
}
