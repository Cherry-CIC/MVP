import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:flutter/material.dart';

class HiddenPasswordField extends StatefulWidget {
  const HiddenPasswordField({super.key});

  @override
  _HiddenPasswordFieldState createState() => _HiddenPasswordFieldState();
}

class _HiddenPasswordFieldState extends State<HiddenPasswordField> {
  final TextEditingController _controller = TextEditingController();
  String _password = '';
  final int _maxLength = 10; //TODO define password length

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
