import 'package:flutter/material.dart';

class Outlined extends StatelessWidget {
  final Widget child;

  const Outlined({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
