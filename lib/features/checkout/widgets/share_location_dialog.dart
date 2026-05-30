import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/l10n/app_localizations.dart';

class ShareLocationDialog extends StatelessWidget {
  final String postcode;
  const ShareLocationDialog({required this.postcode, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            AppStrings.wantToShareLocation,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
        ],
      ),
      actions: [
        SizedBox(
          height: 43,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
        ),
        FilledButton(
          onPressed: () => context.read<CheckoutViewModel>().onConfirmLocation(postcode),
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }
}
