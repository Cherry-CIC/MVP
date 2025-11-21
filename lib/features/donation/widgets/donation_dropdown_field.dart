import 'package:flutter/material.dart';

class DonationDropdownField extends StatefulWidget {
  const DonationDropdownField({
    super.key,
    required this.formFieldsHintText,
    required this.dropdownList,
    required this.onChanged,
    this.charityImages,
    this.selectedValue,
  });

  final String formFieldsHintText;
  final List<String> dropdownList;
  final ValueChanged<String?> onChanged;
  final List<String>? charityImages;
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



  Widget charityRow(String item) {
    final index = widget.dropdownList.indexOf(item);
    final imageUrl = (widget.charityImages != null && index >= 0 && index < widget.charityImages!.length)
        ? widget.charityImages![index]
        : null;

    return SizedBox(
      width: 200, /// Set the desired width to match ui
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            const SizedBox(width: 74),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),


        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedDropdownItem,
        items: widget.dropdownList.map((item) {
          return DropdownMenuItem(
            value: item,
            child: charityRow(item),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => selectedDropdownItem = value);
          widget.onChanged(value);
        },
        selectedItemBuilder: (BuildContext context) {
          return widget.dropdownList.map((item) {
            return charityRow(item);
          }).toList();
        },
        decoration: InputDecoration(
          hintText: widget.formFieldsHintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}