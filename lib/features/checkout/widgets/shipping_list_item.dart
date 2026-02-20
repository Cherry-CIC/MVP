import 'package:cherry_mvp/features/checkout/widgets/outlined.dart';
import 'package:flutter/material.dart';

class ShippingListItem<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;

  const ShippingListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Outlined(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Radio.adaptive(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => onChanged?.call(value),
      ),
    );
  }
}
