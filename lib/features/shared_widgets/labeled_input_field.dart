import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';

enum KeyboardType { text, phoneNo, emailAddress }

class LabeledInputField extends StatefulWidget {
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
  State<LabeledInputField> createState() => _LabeledInputFieldState();
}

class _LabeledInputFieldState extends State<LabeledInputField> {
  bool _passwordVisible = false;

  @override
  void didUpdateWidget(covariant LabeledInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText || oldWidget.controller != widget.controller) {
      _passwordVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputType = switch (widget.keyboardType) {
      KeyboardType.text => TextInputType.text,
      KeyboardType.phoneNo => TextInputType.phone,
      KeyboardType.emailAddress => TextInputType.emailAddress,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText && !_passwordVisible,
          // Keep password keyboard protections active when the text is visible.
          autocorrect: !widget.obscureText,
          enableSuggestions: !widget.obscureText,
          smartDashesType: widget.obscureText ? SmartDashesType.disabled : null,
          smartQuotesType: widget.obscureText ? SmartQuotesType.disabled : null,
          validator: widget.validator,
          keyboardType: inputType,
          textInputAction: widget.isLastField ? TextInputAction.done : TextInputAction.next,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _passwordVisible
                        ? AppStrings.hidePassword(widget.label)
                        : AppStrings.showPassword(widget.label),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                    icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
