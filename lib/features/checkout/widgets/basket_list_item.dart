import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:flutter/material.dart';

class BasketListItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onRemove;

  const BasketListItem({super.key, required this.product, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(16),
      child: Row(
        spacing: 16,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: product.productImages.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.productImages.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  product.size,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 14.5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppStrings.currencySymbol}${product.price.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 18),
                      ),
                    ),
                    Material(
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      elevation: 4,
                      child: InkWell(
                        key: ValueKey('basket-charity-logo-${product.id}'),
                        onTap: (CharityProfileArgs.safeIdentifier(product.charityId) != null ||
                                (product.charity?.name.trim().isNotEmpty ?? false))
                            ? () => NavigationProvider.openCharityProfileFromContext(
                                  context,
                                  CharityProfileArgs(
                                    charity: product.charity,
                                    charityId: product.charityId,
                                    charityName: product.charity?.name,
                                    charityImageUrl: product.charityImage,
                                  ),
                                )
                            : null,
                        child: SizedBox(
                          height: 40,
                          width: 40,
                          child: product.charityImage.isNotEmpty
                              ? ImageProviderHelper.buildImage(
                                  imagePath: product.charityImage,
                                  fit: BoxFit.contain,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
