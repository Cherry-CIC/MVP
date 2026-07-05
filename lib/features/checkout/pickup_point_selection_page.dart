import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/inpost.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';
import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_empty_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_error_widget.dart';
import 'package:cherry_mvp/features/checkout/widgets/pickup_points_loading_widget.dart';

class PickupPointSelectionPage extends StatefulWidget {
  const PickupPointSelectionPage({super.key});

  @override
  State<PickupPointSelectionPage> createState() => _PickupPointSelectionPageState();
}

class _PickupPointSelectionPageState extends State<PickupPointSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController(text: 'GB');

  bool _hasSearched = false;

  @override
  void dispose() {
    postcodeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, _) {
        final isLoading = _hasSearched && viewModel.status.type == StatusType.loading;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => viewModel.goBack(false)),
            title: const Text(AppStrings.checkoutChoosePickupPoint),
            centerTitle: true,
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildSearchForm(context, viewModel, isLoading),
                  ),
                ),
                if (_hasSearched) _buildSearchResults(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchForm(
    BuildContext context,
    CheckoutViewModel viewModel,
    bool isLoading,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final useStackedFields = width < 420;
    final postcodeField = _buildPostcodeField(viewModel);
    final countryField = _buildCountryField();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          useStackedFields
              ? Column(
                  children: [
                    postcodeField,
                    const SizedBox(height: 12),
                    countryField,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: postcodeField),
                    const SizedBox(width: 12),
                    SizedBox(width: 120, child: countryField),
                  ],
                ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: isLoading ? null : () => _searchPickupPoints(viewModel),
              icon: const Icon(Icons.search),
              label: const Text(AppStrings.checkoutFindNearestPickupPoints),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostcodeField(CheckoutViewModel viewModel) {
    return TextFormField(
      controller: postcodeController,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.streetAddress,
      inputFormatters: [
        LengthLimitingTextInputFormatter(8),
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
      ],
      decoration: InputDecoration(
        labelText: AppStrings.postCode,
        hintText: AddressConstants.postCodeHintText,
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
      validator: _validatePostcode,
      onFieldSubmitted: (_) => _searchPickupPoints(viewModel),
    );
  }

  Widget _buildCountryField() {
    return TextFormField(
      controller: countryController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: AppStrings.countryText,
        prefixIcon: Icon(Icons.flag_outlined),
      ),
    );
  }

  Widget _buildSearchResults(CheckoutViewModel viewModel) {
    if (viewModel.status.type == StatusType.loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: PickupPointsLoadingWidget(),
      );
    }

    if (viewModel.status.type == StatusType.failure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: PickupPointErrorWidget(
          errorMessage: viewModel.status.message,
          onRetry: () => _searchPickupPoints(viewModel),
        ),
      );
    }

    final pickupPoints = viewModel.nearestInposts;
    if (pickupPoints.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: PickupPointsEmptyWidget(),
      );
    }

    final children = <Widget>[
      Text(
        AppStrings.checkoutNearestPickupPoints,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
    ];

    for (final pickupPoint in pickupPoints) {
      children.add(
        _PickupPointCard(
          pickupPoint: pickupPoint,
          onTap: () {
            viewModel.setSelectedInpost(pickupPoint.inpost);
            viewModel.goBack(true);
          },
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      sliver: SliverList.list(children: children),
    );
  }

  Future<void> _searchPickupPoints(CheckoutViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    viewModel.setSelectedInpost(null);
    viewModel.setSelectedInpostShippingMethod(null);
    setState(() => _hasSearched = true);

    await viewModel.fetchNearestInposts(
      _normalisePostcode(postcodeController.text),
      countryController.text.trim().toUpperCase(),
    );
  }

  String? _validatePostcode(String? value) {
    final postcode = _normalisePostcode(value ?? '');
    if (postcode.isEmpty) {
      return AppStrings.checkoutPickupPostcodeRequired;
    }

    final postcodePattern = RegExp(
      r'^[A-Z]{1,2}[0-9][A-Z0-9]? ?[0-9][A-Z]{2}$',
      caseSensitive: false,
    );
    if (!postcodePattern.hasMatch(postcode)) {
      return AppStrings.checkoutPickupPostcodeInvalid;
    }

    return null;
  }

  String _normalisePostcode(String postcode) {
    return postcode.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }
}

class _PickupPointCard extends StatelessWidget {
  const _PickupPointCard({
    required this.pickupPoint,
    required this.onTap,
  });

  final InpostSearchResult pickupPoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inpost = pickupPoint.inpost;
    final formattedAddress = pickupPoint.concatenatedAddress;

    final distanceMetres = pickupPoint.distanceMetres;
    final displayDistance = pickupPoint.displayDistance;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store_mall_directory_outlined, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inpost.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      formattedAddress,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    if (distanceMetres != 0)
                      Text(
                        'Distance: $displayDistance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
