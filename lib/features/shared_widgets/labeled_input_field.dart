import 'package:flutter/material.dart';

enum KeyboardType { text, phoneNo, emailAddress }

class LabeledInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final bool isLastField;
  final KeyboardType keyboardType;

  const LabeledInputField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.isLastField = false,
    this.keyboardType = KeyboardType.text,
  });

  @override
  Widget build(BuildContext context) {
    final inputType = switch (keyboardType) {
      KeyboardType.text => TextInputType.text,
      KeyboardType.phoneNo => TextInputType.phone,
      KeyboardType.emailAddress => TextInputType.emailAddress,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: inputType,
          textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
