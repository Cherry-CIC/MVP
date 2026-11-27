import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/products/widgets/charity_details_dialog.dart';
import 'package:flutter/material.dart';

class ProductCharityCard extends StatelessWidget {
  const ProductCharityCard({
    super.key,
    required this.charity,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final Charity charity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = theme.colorScheme;
    final trimmedName = charity.name.trim();
    final displayName = trimmedName.isEmpty ? AppStrings.charityText : trimmedName;
    final semanticsTarget = trimmedName.isEmpty ? 'this charity' : trimmedName;
    final borderColor = theme.brightness == Brightness.dark
        ? colours.outline
        : AppColors.borderGrey;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.productPageDonatingTo,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'About $semanticsTarget',
            child: Material(
              color: colours.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('product-charity-details'),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => CharityDetailsDialog(charity: charity),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.10),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CharityLogo(charity: charity),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colours.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.productPageCharityLearnMore,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colours.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
