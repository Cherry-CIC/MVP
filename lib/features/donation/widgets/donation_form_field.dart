import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class DonationFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String title;
  final IconData? hintIcon;
  final IconData? suffixIcon;
  final int? minLines;

  const DonationFormField({
    super.key,
    required this.controller,
    required this.title,
    required this.hintText,
    this.hintIcon,
    this.suffixIcon,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      titleTextStyle: Theme.of(context).textTheme.labelLarge,
      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
      subtitle: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        validator: validateDonationFormFields,
        decoration: InputDecoration(
          hint: hintIcon != null
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                      Icon(
                        hintIcon,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Expanded(
                          child: Text(hintText,
                              maxLines: minLines,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary))),
                    ])
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Theme.of(context).colorScheme.secondary)
              : null,
        ),
      ),
    );
  }
}
