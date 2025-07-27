import 'package:flutter/material.dart';

class DonationDropdownField<T> extends StatelessWidget {
  final String title;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;

  const DonationDropdownField({
    super.key,
    required this.title,
    required this.items,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: DropdownButtonFormField<T>(
        decoration: InputDecoration(hintText: title),
        value: value,
        items: items,
        onChanged: onChanged,
        validator: (value) => value == null ? 'Select an option' : null,
      ),
    );
  }
}
