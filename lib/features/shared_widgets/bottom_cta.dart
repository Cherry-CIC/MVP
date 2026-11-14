import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class BottomCta extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  final String text;
  final TextStyle? textStyle;
  final bool loading;

  const BottomCta({
    super.key,
    required this.enabled,
    this.onPressed,
    required this.text,
    this.textStyle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          Size.fromHeight(56),
        ),
      ),
      onPressed: enabled && !loading ? onPressed : null,
      child: loading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                // The loading button is disabled, so the spinner sits on the
                // disabled onSurface tint, not the primary action color.
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : Text(
              text,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
    );

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // While loading the visible label is replaced by a spinner, so give
        // screen readers the label plus the busy state instead.
        child: loading
            ? Semantics(
                button: true,
                enabled: false,
                label: AppStrings.loadingButton(text),
                excludeSemantics: true,
                child: button,
              )
            : button,
      ),
    );
  }
}
