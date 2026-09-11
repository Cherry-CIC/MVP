import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';

class DonationForm extends StatefulWidget {
  final List<XFile>? selectedImages;

  const DonationForm({super.key, this.selectedImages});

  @override
  DonationFormState createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addToCollectionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String selectedCategory = '';
  String selectedCategoryId = '';
  String selectedCondition = '';
  String selectedQuality = '';
  String selectedSize = '';
  PostageSizeInfo? selectedPostageSize;
  bool isSwitchedOpenToOtherCharity = false;
  bool isSwitchedOpenToOffer = false;
  bool isSwitchedApplicableBuyerDiscounts = false;

  Charity? selectedCharity;
  bool _hasInitialized = false;
  bool _handlingSubmission = false;
  int _draftGeneration = 0;

  bool get _canEdit => mounted && !_handlingSubmission && !context.read<DonationViewModel>().isSubmitting;
  final _hideUnimplementedFeatures = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CharityViewModel>().fetchCharities();
        context.read<CategoryViewModel>().fetchCategories();
      });
    }
  }

  void toggleSwitchOpenToOtherCharity(bool value) {
    if (!_canEdit) return;
    setState(() => isSwitchedOpenToOtherCharity = value);
  }

  void toggleSwitchOpenToOffer(bool value) {
    if (!_canEdit) return;
    setState(() => isSwitchedOpenToOffer = value);
  }

  void toggleSwitchApplicableBuyerDiscounts(bool value) {
    if (!_canEdit) return;
    setState(() => isSwitchedApplicableBuyerDiscounts = value);
  }

  double _parseEnteredPrice() {
    final rawInput = _priceController.text.trim();
    if (rawInput.isEmpty) {
      return 0.0;
    }
    return double.tryParse(rawInput.replaceAll('£', '')) ?? 0.0;
  }

  DonationRequest _buildDonationRequest() {
    if (selectedPostageSize == null) {
      throw ArgumentError('Postage size must be selected');
    }
    return DonationRequest(
      name: _titleController.text,
      description: _descriptionController.text,
      categoryId: selectedCategoryId,
      charityId: selectedCharity?.id ?? '',
      quality: selectedQuality,
      size: selectedSize,
      postageSizeId: selectedPostageSize!.id,
      donation: _parseEnteredPrice(),
      price: _parseEnteredPrice(),
      localImages: widget.selectedImages,
    );
  }

  Future<void> _submitDonation() async {
    if (!_canEdit) return;
    if (_formKey.currentState!.validate()) {
      final priceText = _priceController.text.trim();

      // Validate required dropdowns
      if (priceText.isEmpty || selectedQuality.isEmpty || selectedSize.isEmpty) {
        Fluttertoast.showToast(
          msg: AppStrings.pleaseSelectAllDropdowns,
        );
        return;
      }
      if (selectedCategoryId.trim().isEmpty) {
        Fluttertoast.showToast(
          msg: AppStrings.pleaseSelectCategory,
        );
        return;
      }
      if (selectedCharity == null) {
        Fluttertoast.showToast(
          msg: AppStrings.pleaseSelectCharity,
        );
        return;
      }
      if (selectedPostageSize == null) {
        Fluttertoast.showToast(
          msg: AppStrings.pleaseChoosePostageSize,
        );
        return;
      }
      if (widget.selectedImages == null || widget.selectedImages!.isEmpty) {
        Fluttertoast.showToast(msg: AppStrings.pleaseAddPhoto);
        return;
      }
      final donationViewModel = context.read<DonationViewModel>();
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      final navigator = Navigator.of(context);
      final request = _buildDonationRequest();
      FocusScope.of(context).unfocus();
      setState(() {
        _handlingSubmission = true;
        _draftGeneration++;
      });
      final result = await donationViewModel.submitDonation(
        request,
        donorDiscountActive: FeatureFlags.showDonorDiscounts ? isSwitchedApplicableBuyerDiscounts : null,
      );
      if (!mounted) return;
      // A forced route change makes this completion obsolete, even during exit animation.
      if (!route.isActive) return;
      if (result != null && result.isSuccess) {
        if (!route.isCurrent) {
          // A newer route stays visible. Only discard this completed draft.
          navigator.removeRoute(route);
          return;
        }
        // Replace this exact form, whether it came from a dialog or a named route.
        // Keep the form locked until replacement disposes its draft and photos.
        navigator.pushReplacementNamed(AppRoutes.donationSuccess);
        return;
      }
      setState(() => _handlingSubmission = false);
      if (route.isCurrent && result != null) {
        Fluttertoast.showToast(
          msg: result.error ?? AppStrings.unexpectedErrorOccurred,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addToCollectionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DonationViewModel>(
      builder: (context, donationViewModel, child) {
        final busy = _handlingSubmission || donationViewModel.isSubmitting;

        return Form(
          key: _formKey,
          canPop: !busy,
          child: Column(
            children: [
              DonationFormField(
                enabled: !busy,
                controller: _titleController,
                hintText: titleHintText,
                title: AppStrings.titleText,
                hintIcon: Icons.add_circle_outline,
              ),
              DonationFormField(
                enabled: !busy,
                controller: _descriptionController,
                hintText: descriptionHintText,
                title: AppStrings.descriptionText,
                hintIcon: Icons.add_circle_outline,
                minLines: 2,
              ),

              Consumer<CategoryViewModel>(
                builder: (context, categoryViewModel, child) {
                  final status = categoryViewModel.status;
                  final categories = categoryViewModel.categories;

                  if (status.type == StatusType.loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Loading categories...'),
                          ],
                        ),
                      ),
                    );
                  } else if (status.type == StatusType.failure) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Error loading categories',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => categoryViewModel.fetchCategories(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    );
                  } else if (categories.isEmpty) {
                    return DonationDropdownField(
                      enabled: !busy,
                      formFieldsHintText: categoryHintText,
                      dropdownList: categoryDropdownList,
                      onChanged: (val) {
                        if (_canEdit) setState(() => selectedCategory = val!);
                      },
                    );
                  } else {
                    return _SelectionField(
                      label: categoryHintText,
                      value: selectedCategory.isNotEmpty ? selectedCategory : null,
                      onTap: busy
                          ? null
                          : () async {
                              if (!_canEdit) return;
                              final generation = _draftGeneration;
                              final Category? result = await donationViewModel.navigateToCategoryPage(
                                selectedCategoryId,
                              );

                              if (_canEdit && generation == _draftGeneration && result != null) {
                                setState(() {
                                  selectedCategory = result.name;
                                  selectedCategoryId = result.id;
                                });
                              }
                            },
                    );
                  }
                },
              ),

              Consumer<CharityViewModel>(
                builder: (context, charityViewModel, child) {
                  final status = charityViewModel.status;
                  final charities = charityViewModel.charities;

                  if (status.type == StatusType.loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(AppStrings.loadCharities),
                          ],
                        ),
                      ),
                    );
                  } else if (status.type == StatusType.failure) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.charityError,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => charityViewModel.fetchCharities(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    );
                  } else if (charities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(AppStrings.noCharitiesAvailable),
                    );
                  } else {
                    return _SelectionField(
                      label: AppStrings.charityText,
                      value: selectedCharity?.name,
                      onTap: busy
                          ? null
                          : () async {
                              if (!_canEdit) return;
                              final generation = _draftGeneration;
                              final Charity? result = await donationViewModel.navigateToCharityPage(
                                selectedCharity?.id,
                              );

                              if (_canEdit && generation == _draftGeneration && result != null) {
                                setState(() => selectedCharity = result);
                              }
                            },
                    );
                  }
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextFormField(
                  enabled: !busy,
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: AppStrings.priceText,
                    hintText: '0.00',
                    prefixText: '£',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty) {
                      return 'Please enter a price';
                    }
                    final parsed = double.tryParse(input);
                    if (parsed == null) {
                      return 'Please enter a valid price';
                    }
                    if (parsed <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                  onTapUpOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              DonationDropdownField(
                enabled: !busy,
                formFieldsHintText: qualityHintText,
                dropdownList: qualityDropdownList,
                onChanged: (val) {
                  if (_canEdit) setState(() => selectedQuality = val!);
                },
                selectedValue: selectedQuality.isNotEmpty ? selectedQuality : null,
              ),

              DonationDropdownField(
                enabled: !busy,
                formFieldsHintText: sizeHintText,
                dropdownList: sizeDropdownList,
                onChanged: (val) {
                  if (_canEdit) setState(() => selectedSize = val!);
                },
                selectedValue: selectedSize.isNotEmpty ? selectedSize : null,
              ),

              _SelectionField(
                label: postageSizeHintText,
                value: selectedPostageSize?.size.label,
                onTap: busy
                    ? null
                    : () async {
                        if (!_canEdit) return;
                        final generation = _draftGeneration;
                        final PostageSizeInfo? result = await donationViewModel.navigateToPostageSizePage(
                          selectedPostageSize,
                        );

                        if (_canEdit && generation == _draftGeneration && result != null) {
                          setState(() => selectedPostageSize = result);
                        }
                      },
              ),
              if (!_hideUnimplementedFeatures) ...[
                DonationFormField(
                  enabled: !busy,
                  controller: _addToCollectionController,
                  hintText: addToCollectionHintText,
                  title: addToCollectionText,
                  suffixIcon: Icons.add,
                  validator: validateOptionalDonationFormFields,
                ),
                DonationOptions(
                  isSwitchedOpenToOtherCharity: isSwitchedOpenToOtherCharity,
                  toggleSwitchOpenToOtherCharity: toggleSwitchOpenToOtherCharity,
                  isSwitchedOpenToOffer: isSwitchedOpenToOffer,
                  toggleSwitchOpenToOffer: toggleSwitchOpenToOffer,
                  isSwitchedApplicableBuyerDiscounts: isSwitchedApplicableBuyerDiscounts,
                  toggleSwitchApplicableBuyerDiscounts: toggleSwitchApplicableBuyerDiscounts,
                ),
              ],
              if (FeatureFlags.showDeferredControls)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.thoughtsOnUpload,
                          softWrap: true,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.grey),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                        ),
                        child: Text(
                          AppStrings.giveFeedback,
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: busy
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitDonation,
                          child: const Text(AppStrings.submitDonation),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value ?? AppStrings.selectOptionText;
    final isPlaceholder = value == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            enabled: onTap != null,
            suffixIcon: const Icon(Icons.chevron_right),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              display,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPlaceholder ? theme.hintColor : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
