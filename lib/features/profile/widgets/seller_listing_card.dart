import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:flutter/material.dart';

class SellerListingCard extends StatelessWidget {
  final SellerListing listing;
  final VoidCallback? onTap;
  final bool isLoading;

  const SellerListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = listing.name.isEmpty ? AppStrings.profileListingUntitled : listing.name;
    final priceLabel = listing.price == null
        ? AppStrings.profileListingPriceUnavailable
        : '£${listing.price!.toStringAsFixed(2)}';
    final isTappable = onTap != null;

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ListingImage(imageUrls: listing.imageUrls),
                  if (isLoading)
                    ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.scrim.withValues(alpha: 0.4),
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          priceLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: listing.price == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      button: isTappable,
      enabled: isTappable ? !isLoading : null,
      label: '$displayName. $priceLabel.',
      hint: isTappable ? AppStrings.profileListingViewDetailsHint : null,
      onTap: isTappable && !isLoading ? onTap : null,
      child: ExcludeSemantics(
        child: isTappable
            ? Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isLoading ? null : onTap,
                  child: card,
                ),
              )
            : card,
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final List<String> imageUrls;

  const _ListingImage({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const _ListingImagePlaceholder();
    }

    return ImageProviderHelper.buildImage(
      imagePath: imageUrls.first,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorWidget: const _ListingImagePlaceholder(),
      loadingWidget: const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ListingImagePlaceholder extends StatelessWidget {
  const _ListingImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
