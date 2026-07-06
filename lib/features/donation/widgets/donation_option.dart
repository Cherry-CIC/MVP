import 'package:flutter/material.dart';

class DonationOption extends StatelessWidget {
  final String labelText;
  final bool value;
  final void Function(bool) onChanged;

  const DonationOption({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: StadiumBorder(),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  labelText,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                inactiveTrackColor:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
