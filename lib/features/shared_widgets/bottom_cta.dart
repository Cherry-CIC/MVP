import 'package:flutter/material.dart';

class BottomCta extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  final String text;
  final bool loading;

  const BottomCta({
    super.key,
    required this.enabled,
    this.onPressed,
    required this.text,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FilledButton(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              Size.fromHeight(56),
            ),
          ),
          onPressed: enabled && !loading ? onPressed : null,
          child: loading
              ? const CircularProgressIndicator()
              : Text(
                  text,
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
