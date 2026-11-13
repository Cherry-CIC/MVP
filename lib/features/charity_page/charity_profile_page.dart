import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_repository.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_view_model.dart';
import 'package:cherry_mvp/features/products/deleted_listings.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/products/widgets/charity_details_dialog.dart';
import 'package:cherry_mvp/features/products/widgets/product_safety_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Displays a charity's profile, mission description, and active listings.
class CharityProfilePage extends StatefulWidget {
  const CharityProfilePage({
    super.key,
    required this.args,
    this.repository,
    this.onReportCharity,
    this.onBlockCharity,
  });

  final CharityProfileArgs args;
  final ICharityProfileRepository? repository;
  final Future<Result<void>> Function(
    String charityId, {
    required String reason,
    String? message,
  })? onReportCharity;
  final Future<Result<void>> Function(String charityId)? onBlockCharity;

  @override
  State<CharityProfilePage> createState() => _CharityProfilePageState();
}

class _CharityProfilePageState extends State<CharityProfilePage> {
  late CharityProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  void _createViewModel() {
    final repo =
        widget.repository ?? _maybeRead<ICharityProfileRepository>() ?? CharityProfileRepository(context.read<ApiService>());
    _viewModel = CharityProfileViewModel(
      args: widget.args,
      repository: repo,
      deletedListings: _maybeRead<DeletedListings>(),
    );
    _viewModel.loadInitial();
  }

  @override
  void didUpdateWidget(covariant CharityProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.charityId != widget.args.charityId ||
        oldWidget.args.charityName != widget.args.charityName ||
        oldWidget.repository != widget.repository) {
      _viewModel.dispose();
      _createViewModel();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  T? _maybeRead<T>() {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          key: const ValueKey('charity-profile-back-button'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Image.asset(AppImages.backIcon, width: 24, height: 24),
        ),
        title: const Text(AppStrings.charityProfileTitle),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => RefreshIndicator(
            onRefresh: _viewModel.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final headerCharity = _viewModel.headerCharity;
    final hasResolvedId =
        CharityProfileArgs.safeIdentifier(_viewModel.charity?.id ?? widget.args.charityId) != null;

    if (_viewModel.status == CharityProfileStatus.unavailable && headerCharity == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              _viewModel.errorMessage ?? AppStrings.charityProfileUnavailable,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ];
    }

    return [
      _buildHeader(context, headerCharity, showMenu: hasResolvedId),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(
            Icons.location_on,
            size: 18,
            color: AppColors.onSurfaceVariant(context),
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.charityProfileLocation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant(context),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        _viewModel.displayDescription,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
      const SizedBox(height: 18),
      ..._buildListingsSection(context),
    ];
  }

  Widget _buildHeader(
    BuildContext context,
    Charity? headerCharity, {
    required bool showMenu,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderGrey),
          ),
          child: ClipOval(
            child: headerCharity == null
                ? const Center(
                    child: Icon(Icons.volunteer_activism, color: Colors.grey),
                  )
                : CharityLogo(charity: headerCharity),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            _viewModel.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showMenu)
          CharitySafetyActionsButton(
            key: const ValueKey('charity-profile-safety-menu'),
            iconColor: AppColors.red,
            onSelected: (action) => _handleSafetyAction(context, action),
          ),
      ],
    );
  }

  List<Widget> _buildListingsSection(BuildContext context) {
    final theme = Theme.of(context);
    switch (_viewModel.status) {
      case CharityProfileStatus.initial:
      case CharityProfileStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case CharityProfileStatus.unavailable:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _viewModel.errorMessage ?? AppStrings.charityProfileUnavailable,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ];
      case CharityProfileStatus.error:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Text(
                  _viewModel.errorMessage ?? AppStrings.charityProfileLoadError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _viewModel.loadInitial,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ];
      case CharityProfileStatus.blocked:
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.charityProfileBlockedMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ];
      case CharityProfileStatus.loaded:
        if (_viewModel.products.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  AppStrings.charityProfileEmptyListings,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant(context),
                  ),
                ),
              ),
            ),
          ];
        }
        return [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final product in _viewModel.products)
                    SizedBox(
                      key: ValueKey('charity-listing-${product.id}'),
                      width: cardWidth,
                      child: ProductCard(
                        product: product,
                        enableCharityTap: false,
                        onTap: () => _openProduct(context, product),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_viewModel.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
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

  void _openProduct(BuildContext context, Product product) {
    _maybeRead<ProductViewModel>()?.setProduct(product);
    final navigator = _maybeRead<NavigationProvider>();
    if (navigator != null && navigator.navigatorKey.currentState != null) {
      navigator.navigateTo(AppRoutes.product, arguments: product);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.product, arguments: product);
    }
  }

  Future<void> _handleSafetyAction(
    BuildContext context,
    CharitySafetyMenuAction action,
  ) async {
    final charityId = CharityProfileArgs.safeIdentifier(
      _viewModel.charity?.id ?? widget.args.charityId,
    );
    if (charityId == null) return;

    switch (action) {
      case CharitySafetyMenuAction.reportCharity:
        await _reportCharity(context, charityId);
        break;
      case CharitySafetyMenuAction.blockCharity:
        await _blockCharity(context, charityId);
        break;
    }
  }

  Future<void> _reportCharity(BuildContext context, String charityId) async {
    // Explicit confirmation screen prevents accidental report submissions.
    final confirmed = await showReportCharityConfirmationDialog(context);
    if (!confirmed || !context.mounted) return;

    final draft = await showReportProductSheet(
      context,
      title: AppStrings.reportCharityMenuLabel,
      reasons: charityReportReasons,
    );
    if (draft == null || !context.mounted) return;

    final result = widget.onReportCharity != null
        ? await widget.onReportCharity!(
            charityId,
            reason: draft.reason,
            message: draft.message,
          )
        : await _submitCharityReportViaViewModel(
            charityId,
            reason: draft.reason,
            message: draft.message,
          );

    if (!context.mounted) return;
    _showFeedback(
      context,
      result,
      successMessage: AppStrings.charityReportedFeedback,
      fallbackError: AppStrings.productPageReportFailed,
    );
  }

  Future<void> _blockCharity(BuildContext context, String charityId) async {
    final confirmed = await showBlockCharityDialog(context);
    if (!confirmed || !context.mounted) return;

    final result = widget.onBlockCharity != null
        ? await widget.onBlockCharity!(charityId)
        : await _blockCharityViaViewModel(charityId);

    if (!context.mounted) return;
    if (result.isSuccess) {
      _viewModel.markBlocked();
    }
    _showFeedback(
      context,
      result,
      successMessage: AppStrings.charityBlockedFeedback,
      fallbackError: 'Unable to block this charity.',
    );
  }

  Future<Result<void>> _submitCharityReportViaViewModel(
    String charityId, {
    required String reason,
    String? message,
  }) async {
    final vm = _maybeRead<ProductViewModel>();
    if (vm == null) {
      return Result.failure(AppStrings.productPageReportFailed);
    }
    return vm.reportCharity(
      charityId,
      reason: reason,
      message: message,
    );
  }

  Future<Result<void>> _blockCharityViaViewModel(String charityId) async {
    final vm = _maybeRead<ProductViewModel>();
    if (vm == null) {
      return Result.failure('Unable to block this charity.');
    }
    return vm.blockCharity(charityId);
  }

  void _showFeedback(
    BuildContext context,
    Result<void> result, {
    required String successMessage,
    required String fallbackError,
  }) {
    final message = result.isSuccess
        ? successMessage
        : (result.error ?? fallbackError);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
