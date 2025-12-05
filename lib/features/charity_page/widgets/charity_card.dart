import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';

class CharityCard extends StatefulWidget {
  const CharityCard({super.key, required this.charity});
  final Charity charity;

  @override
  CharityCardState createState() => CharityCardState();
}

class CharityCardState extends State<CharityCard> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 5,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: widget.charity.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.charity.imageUrl,
                              height: 90,
                              width: 90,
                              fit: BoxFit.contain,
                            )
                          : SizedBox(height: 80, width: 80),
                    ),
                  ),

                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.charity.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(
                        width: screenWidth - 110,
                        child: Text(
                          AppStrings.charityDescription,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          softWrap: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {},
                          child: Text(
                            AppStrings.seeMore,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(),
        ),
      ],
    );
  }
}
