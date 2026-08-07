import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileListingsSection extends StatelessWidget {
  final VoidCallback onCreateListing;

  const ProfileListingsSection({
    super.key,
    required this.onCreateListing,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileListingsViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      AppStrings.profileUserListings,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContent(context, viewModel),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProfileListingsViewModel viewModel,
  ) {
    final status = viewModel.status;

    if (status.type == StatusType.uninitialized || status.type == StatusType.loading) {
      return const _ListingsLoadingState();
    }

    if (status.type == StatusType.failure) {
      return _ListingsErrorState(
        errorMessage: status.message,
        onRetry: viewModel.retryInitialLoad,
      );
    }

    if (viewModel.listings.isEmpty) {
      return _ListingsEmptyState(onCreateListing: onCreateListing);
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: 16,
              children: [
                for (final listing in viewModel.listings)
                  SizedBox(
                    key: ValueKey(listing.id),
                    width: cardWidth,
                    child: SellerListingCard(listing: listing),
                  ),
              ],
            );
          },
        ),
        if (viewModel.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          )
        else if (viewModel.hasLoadMoreError)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Text(
                  AppStrings.profileListingsLoadMoreFailed,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: viewModel.retryLoadMore,
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          )
        else if (viewModel.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: viewModel.loadMoreListings,
              child: const Text(AppStrings.profileListingsLoadMore),
            ),
          ),
      ],
    );
  }
}

class _ListingsLoadingState extends StatelessWidget {
  const _ListingsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.profileListingsLoading,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < 2; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.45,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListingsErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ListingsErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.profileListingsLoadFailed,
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null && errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingsEmptyState extends StatelessWidget {
  final VoidCallback onCreateListing;

  const _ListingsEmptyState({required this.onCreateListing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.profileListingsEmpty,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreateListing,
              child: const Text(AppStrings.profileListingsCreate),
            ),
          ],
        ),
      ),
    );
  }
}
