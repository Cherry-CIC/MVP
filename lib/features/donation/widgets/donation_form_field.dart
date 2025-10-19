import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class DonationFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? title;
  final IconData? hintIcon;
  final IconData? suffixIcon;
  final int? minLines;
  final String? Function(String?)? validator;

  const DonationFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.hintIcon,
    this.title,
    this.suffixIcon,
    this.minLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        spacing: 4,
        children: [
          if ((title ?? "").isNotEmpty)
            Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: TextFormField(
              maxLines: null,
              controller: controller,
              minLines: minLines,
              validator: validator ?? validateDonationFormFields,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: hintIcon != null
                    ? Icon(
                        hintIcon,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : null,
                suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
