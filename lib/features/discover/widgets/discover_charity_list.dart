import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/core/models/charity_category.dart';

class DiscoverCharityList extends StatelessWidget {
  final List<Charity> charities;

  const DiscoverCharityList({required this.charities, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(18.0),
      itemCount: charities.length,
      itemBuilder: (context, index) {
        final charity = charities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DiscoverCharityCard(
            title: charity.charityName,
            description: charity.description,
            imagePath: charity.charityImage,
            logoPath: charity.charityLogo,
            likes: charity.likes,
          ),
        );
      },
    );
  }
}
