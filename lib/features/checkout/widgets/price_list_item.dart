import 'package:flutter/material.dart';

class PriceListItem extends StatelessWidget {
  final Widget title;
  final double price;
  final TextStyle? style;

  const PriceListItem({
    super.key,
    required this.title,
    required this.price,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: style ??
          Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      child: Row(
        children: [
          Expanded(child: title),
          Text('£${price.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}
