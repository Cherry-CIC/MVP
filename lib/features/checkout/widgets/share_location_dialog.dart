import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShareLocationDialog extends StatelessWidget {
  final String postcode;
  const ShareLocationDialog({required this.postcode, super.key});

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
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppStrings.cancel),
          ),
        ),
        FilledButton(
          onPressed: () {
            Provider.of<CheckoutViewModel>(context, listen: false)
                .fetchNearestInPosts(postcode);
            Navigator.pop(context);
          },
          child: Text("Ok"),
        )
      ],
    );
  }
}
