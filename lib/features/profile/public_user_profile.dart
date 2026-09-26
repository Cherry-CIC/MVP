import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PublicUserProfile extends StatefulWidget {
  final String userId;

  const PublicUserProfile({super.key, required this.userId});

  @override
  State<PublicUserProfile> createState() => _PublicUserProfileState();
}

class _PublicUserProfileState extends State<PublicUserProfile> {
  late PublicUserProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  void _createViewModel() {
    _viewModel = PublicUserProfileViewModel(
      userId: widget.userId,
      repository: context.read<IPublicUserProfileRepository>(),
    )..loadProfile();
  }

  @override
  void didUpdateWidget(covariant PublicUserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _viewModel.dispose();
      _createViewModel();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.publicProfileTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _viewModel.loadProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    switch (_viewModel.status) {
      case PublicProfileStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(semanticsLabel: AppStrings.publicProfileLoading)),
          ),
        ];
      case PublicProfileStatus.unavailable:
        return const [
          _ProfileMessage(
            icon: Icons.person_off_outlined,
            message: AppStrings.publicProfileUnavailable,
          ),
        ];
      case PublicProfileStatus.error:
        return [
          _ProfileMessage(
            icon: Icons.error_outline,
            message: AppStrings.publicProfileLoadFailed,
            onRetry: _viewModel.loadProfile,
          ),
        ];
      case PublicProfileStatus.ready:
        final user = _viewModel.user!;
        return [
          Center(
            child: ExcludeSemantics(
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 72,
                  child: user.profileImageUrl == null
                      ? const _AvatarPlaceholder()
                      : Image.network(
                          user.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(user.username, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(AppStrings.publicProfileListingsTitle, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          if (_viewModel.products.isEmpty)
            const _ProfileMessage(
              icon: Icons.inventory_2_outlined,
              message: AppStrings.publicProfileListingsEmpty,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final largeText = MediaQuery.textScalerOf(context).scale(14) > 22;
                final columns = constraints.maxWidth < 300 || largeText ? 1 : 2;
                final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 16,
                  children: [
                    for (final product in _viewModel.products)
                      SizedBox(
                        key: ValueKey('public-listing-${product.id}'),
                        width: cardWidth,
                        child: SellerListingCard(
                          listing: SellerListing(
                            id: product.id,
                            name: product.name,
                            imageUrls: product.productImages,
                            price: product.price,
                          ),
                          onTap: () => context.read<ProductViewModel>().goToProductPage(product),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_viewModel.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(semanticsLabel: AppStrings.publicProfileListingsLoadingMore),
              ),
            )
          else if (_viewModel.loadMoreFailed)
            _ProfileMessage(
              icon: Icons.error_outline,
              message: AppStrings.publicProfileListingsLoadMoreFailed,
              onRetry: _viewModel.loadMore,
            )
          else if (_viewModel.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: _viewModel.loadMore,
                child: const Text(AppStrings.profileListingsLoadMore),
              ),
            ),
        ];
    }
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Icon(Icons.person_outline, size: 40),
  );
}

class _ProfileMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _ProfileMessage({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        ExcludeSemantics(child: Icon(icon)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
      ],
    ),
  );
}
