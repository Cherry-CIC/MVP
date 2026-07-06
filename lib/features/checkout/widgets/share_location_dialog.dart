import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';

class ShareLocationDialog extends StatelessWidget {
  final String postcode;
  final String country;
  const ShareLocationDialog({super.key, required this.postcode, required this.country});

  @override
  Widget build(BuildContext context) {
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
            child: Text(AppStrings.cancel),
          ),
        ),
        FilledButton(
          onPressed: () => context.read<CheckoutViewModel>().onConfirmLocation(postcode, country),
          child: Text("Ok"),
        ),
      ],
    );
  }
}
