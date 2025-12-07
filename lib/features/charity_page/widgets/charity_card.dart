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

    return Column(
      children: [
       Padding(
         padding: const EdgeInsets.symmetric(horizontal: 15),
         child: Row(
           crossAxisAlignment: CrossAxisAlignment.center,
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
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     widget.charity.name,
                     style: Theme.of(context).textTheme.titleSmall,
                   ),
                   Text(
                     AppStrings.charityDescription,
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                       color: Theme.of(context).colorScheme.onSurfaceVariant,
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
             ),
           ],
         ),
       ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Divider(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
