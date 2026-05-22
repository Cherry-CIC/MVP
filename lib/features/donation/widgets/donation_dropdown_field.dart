import 'package:flutter/material.dart';

class DonationDropdownField extends StatefulWidget {
  const DonationDropdownField({
    super.key,
    required this.formFieldsHintText,
    required this.dropdownList,
    required this.onChanged,
    this.selectedValue,
  });

  final String formFieldsHintText;
  final List<String> dropdownList;
  final ValueChanged<String?> onChanged;
  final String? selectedValue;

  @override
  DonationDropdownFieldState createState() => DonationDropdownFieldState();
}

class DonationDropdownFieldState extends State<DonationDropdownField> {
  String? selectedDropdownItem;

  @override
  void initState() {
    super.initState();
    selectedDropdownItem = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownMenuFormField<String>(
        width: double.infinity,
        label: Text(widget.formFieldsHintText),
        hintText: widget.formFieldsHintText,
        initialSelection: selectedDropdownItem,
        dropdownMenuEntries: widget.dropdownList.map((item) {
          return DropdownMenuEntry(value: item, label: item);
        }).toList(),
        onSelected: (value) {
          setState(() => selectedDropdownItem = value);
          widget.onChanged(value);
        },
        decorationBuilder: (context, controller) {
          return InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          );
        },
      ),
    );
  }
}
