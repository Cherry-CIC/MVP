import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class HiddenPasswordField extends StatefulWidget {
  const HiddenPasswordField({super.key});

  @override
  State<HiddenPasswordField> createState() => _HiddenPasswordFieldState();
}

class _HiddenPasswordFieldState extends State<HiddenPasswordField> {
  final TextEditingController _controller = TextEditingController();
  String _password = '';
  // Password length should be defined in config or constants
  // Using a reasonable default for now
  final int _maxLength = 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_maxLength, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: index < _password.length
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }),
        ),
        Opacity(
          opacity: 0, //hide this text field and only bullets will be visible
          child: TextField(
            controller: _controller,
            obscureText: true,
            obscuringCharacter: '●',
            maxLength: _maxLength,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

