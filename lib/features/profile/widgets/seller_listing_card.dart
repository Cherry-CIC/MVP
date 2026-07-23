import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:flutter/material.dart';

class SellerListingCard extends StatelessWidget {
  final SellerListing listing;

  const SellerListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = listing.name.isEmpty ? AppStrings.profileListingUntitled : listing.name;
    final priceLabel = listing.price == null
        ? AppStrings.profileListingPriceUnavailable
        : '£${listing.price!.toStringAsFixed(2)}';

    return Semantics(
      container: true,
      label: '$displayName. $priceLabel.',
      child: ExcludeSemantics(
        child: Column(
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
                  child: _ListingImage(imageUrls: listing.imageUrls),
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
        ),
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
