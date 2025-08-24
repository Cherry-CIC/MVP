import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';


class CardDetailsBottomSheet extends StatefulWidget {
  const CardDetailsBottomSheet({super.key});

  @override
  State<CardDetailsBottomSheet> createState() => _CardDetailsBottomSheetState();
}

class _CardDetailsBottomSheetState extends State<CardDetailsBottomSheet> {
  bool _saveCardDetails = false;

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      shape: const BeveledRectangleBorder(),
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            width: double.infinity,
            child: Text(
              AppStrings.cardDetailsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.cardDetailsCardNumber,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: AppStrings.cardDetailsCardNumberHint,
                    suffixIcon: const Icon(Icons.credit_card),
                  ),
                  inputFormatters: [
                    MaskTextInputFormatter(
                      mask: '#### #### #### ####',
                      filter: {
                        '#': RegExp(r'[0-9]'),
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: AppStrings.cardDetailsExpiryHint,
                        ),
                        inputFormatters: [
                          MaskTextInputFormatter(
                            mask: '##/##',
                            filter: {
                              '#': RegExp(r'[0-9]'),
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: AppStrings.cardDetailsCvcHint,
                        ),
                        inputFormatters: [
                          MaskTextInputFormatter(
                            mask: '###',
                            filter: {
                              '#': RegExp(r'[0-9]'),
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CheckboxListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(AppStrings.cardDetailsSaveCard),
                  value: _saveCardDetails,
                  onChanged: (value) =>
                      setState(() => _saveCardDetails = value ?? false),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.cardDetailsCountryOrRegion,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                DropdownButtonFormField(
                  items: const [],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 4),
                CheckboxListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    AppStrings.cardDetailsAgreeToSave,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cardDetailsSaveAndUse),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.surface,
                backgroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cardDetailsSave),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
