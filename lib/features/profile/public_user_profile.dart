import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/product_safety_actions.dart';
import 'package:cherry_mvp/features/profile/models/seller_listing.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_repository.dart';
import 'package:cherry_mvp/features/profile/public_user_profile_view_model.dart';
import 'package:cherry_mvp/features/profile/widgets/seller_listing_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _PublicProfileSafetyAction { reportUser, blockUser }

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
      appBar: AppBar(
        title: const Text(AppStrings.publicProfileTitle),
        actions: _buildAppBarActions(context),
      ),
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

  List<Widget> _buildAppBarActions(BuildContext context) {
    final currentUserId = context.read<FirebaseAuth>().currentUser?.uid.trim();
    final isOwnProfile = currentUserId != null && currentUserId.isNotEmpty && currentUserId == widget.userId.trim();
    if (isOwnProfile) {
      return const [];
    }

    return [
      PopupMenuButton<_PublicProfileSafetyAction>(
        tooltip: AppStrings.productPageMoreActions,
        onSelected: (action) => _handleSafetyAction(context, action),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _PublicProfileSafetyAction.reportUser,
            child: _PublicProfileSafetyMenuItem(
              icon: Icons.person_off_outlined,
              label: AppStrings.productPageReportSeller,
            ),
          ),
          PopupMenuItem(
            value: _PublicProfileSafetyAction.blockUser,
            child: _PublicProfileSafetyMenuItem(
              icon: Icons.block,
              label: AppStrings.productPageBlockSeller,
            ),
          ),
        ],
      ),
    ];
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

  Future<void> _handleSafetyAction(
    BuildContext context,
    _PublicProfileSafetyAction action,
  ) async {
    switch (action) {
      case _PublicProfileSafetyAction.reportUser:
        await _submitReport(context);
        break;
      case _PublicProfileSafetyAction.blockUser:
        await _blockUser(context);
        break;
    }
  }

  Future<void> _submitReport(BuildContext context) async {
    final draft = await showReportProductSheet(
      context,
      title: AppStrings.productPageReportSellerTitle,
    );
    if (draft == null || !context.mounted) {
      return;
    }

    final result = await context.read<ProductViewModel>().reportSeller(
      widget.userId,
      reason: draft.reason,
      message: draft.message,
    );
    if (!context.mounted) {
      return;
    }

    _showSafetyResult(
      context,
      result,
      successMessage: AppStrings.productPageReportSubmitted,
      fallbackError: AppStrings.productPageReportFailed,
    );
  }

  Future<void> _blockUser(BuildContext context) async {
    final confirmed = await showBlockSellerDialog(context);
    if (!confirmed || !context.mounted) {
      return;
    }

    final result = await context.read<ProductViewModel>().blockSeller(widget.userId);
    if (!context.mounted) {
      return;
    }

    _showSafetyResult(
      context,
      result,
      successMessage: AppStrings.productPageBlockSellerSuccess,
      fallbackError: AppStrings.productPageBlockSellerFailed,
    );
    if (result.isSuccess) {
      await _viewModel.loadProfile();
    }
  }

  void _showSafetyResult(
    BuildContext context,
    Result<void> result, {
    required String successMessage,
    required String fallbackError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? successMessage : result.error ?? fallbackError),
      ),
    );
  }
}

class _PublicProfileSafetyMenuItem extends StatelessWidget {
  const _PublicProfileSafetyMenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 12),
      Text(label),
    ],
  );
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
