import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_page.dart';
import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:cherry_mvp/features/search/widgets/category_page/category_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';

class DonationForm extends StatefulWidget {
  final List<XFile>? selectedImages;
  final VoidCallback? onClearImages;

  const DonationForm({super.key, this.selectedImages, this.onClearImages});

  @override
  DonationFormState createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addToCollectionController =
      TextEditingController();
  final TextEditingController _customPriceController = TextEditingController();

  String selectedCategory = '';
  String selectedCategoryId = '';
  String selectedPrice = '';
  String selectedCondition = '';
  String selectedQuality = '';
  String selectedSize = '';

  bool isSwitchedOpenToOtherCharity = false;
  bool isSwitchedOpenToOffer = false;
  bool isSwitchedApplicableBuyerDiscounts = false;

  bool showCustomPriceField = false;

  Charity? selectedCharity;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CharityViewModel>().fetchCharities();
        context.read<CategoryViewModel>().fetchCategories();
      });
    }
  }

  void toggleSwitchOpenToOtherCharity(bool value) {
    setState(() => isSwitchedOpenToOtherCharity = value);
  }

  void toggleSwitchOpenToOffer(bool value) {
    setState(() => isSwitchedOpenToOffer = value);
  }

  void toggleSwitchApplicableBuyerDiscounts(bool value) {
    setState(() => isSwitchedApplicableBuyerDiscounts = value);
  }

  double _parsePrice(String priceString) {
    if (priceString == "Custom Amount") {
      return double.tryParse(_customPriceController.text) ?? 0.0;
    }
    return double.tryParse(priceString.replaceAll('£', '')) ?? 0.0;
  }

  DonationRequest buildDonationRequest() {
    return DonationRequest(
      name: _titleController.text,
      description: _descriptionController.text,
      categoryId: selectedCategoryId,
      charityId: selectedCharity?.id ?? '',
      quality: selectedQuality,
      size: selectedSize,
      donation: _parsePrice(selectedPrice),
      price: _parsePrice(selectedPrice),
      localImages: widget.selectedImages,
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _addToCollectionController.clear();
    _customPriceController.clear();
    setState(() {
      selectedCategory = '';
      selectedCategoryId = '';
      selectedPrice = '';
      selectedCondition = '';
      selectedQuality = '';
      selectedSize = '';
      selectedCharity = null;
      isSwitchedOpenToOtherCharity = false;
      isSwitchedOpenToOffer = false;
      isSwitchedApplicableBuyerDiscounts = false;
      showCustomPriceField = false;
    });
    widget.onClearImages?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DonationViewModel>(
      builder: (context, donationViewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (donationViewModel.status.type == StatusType.success &&
              donationViewModel.lastSubmission != null) {
            _clearForm();
            donationViewModel.resetStatus();
            Navigator.of(context).pop();
            final navigationProvider = Provider.of<NavigationProvider>(
              context,
              listen: false,
            );
            navigationProvider.navigateTo(AppRoutes.donationSuccess);
          } else if (donationViewModel.status.type == StatusType.failure) {
            final errorMessage =
                donationViewModel.submissionMessage ??
                AppStrings.unexpectedErrorOccurred;
            Fluttertoast.showToast(
              msg: errorMessage,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        });

        return Form(
          key: _formKey,
          child: Column(
            children: [
              DonationFormField(
                controller: _titleController,
                hintText: titleHintText,
                title: AppStrings.titleText,
                hintIcon: Icons.add_circle_outline,
              ),
              DonationFormField(
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
                            onPressed: () =>
                                categoryViewModel.fetchCategories(),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    );
                  } else if (categories.isEmpty) {
                    return DonationDropdownField(
                      formFieldsHintText: categoryHintText,
                      dropdownList: categoryDropdownList,
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                      charityImages: const [],
                    );
                  } else {
                    return _SelectionField(
                      label: categoryHintText,
                      value: selectedCategory.isNotEmpty
                          ? selectedCategory
                          : null,
                      onTap: () async {
                        final Category? result = await Navigator.of(context)
                            .push<Category>(
                              MaterialPageRoute(
                                builder: (_) => CategoryPage(
                                  selectionMode: true,
                                  initialCategoryId:
                                      selectedCategoryId.isNotEmpty
                                      ? selectedCategoryId
                                      : null,
                                ),
                              ),
                            );

                        if (result != null) {
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
                      onTap: () async {
                        final Charity? result = await Navigator.of(context)
                            .push<Charity>(
                              MaterialPageRoute(
                                builder: (_) => CharityPage(
                                  selectionMode: true,
                                  initialCharityId: selectedCharity?.id,
                                ),
                              ),
                            );
                        if (result != null) {
                          setState(() {
                            selectedCharity = result;
                          });
                        }
                      },
                    );
                  }
                },
              ),

              DonationDropdownField(
                formFieldsHintText: priceHintText,
                dropdownList: priceDropdownList,
                onChanged: (val) {
                  setState(() {
                    selectedPrice = val!;
                    showCustomPriceField = val == "Custom Amount";
                    if (!showCustomPriceField) {
                      _customPriceController.clear();
                    }
                  });
                },
                charityImages: const [],
                selectedValue: selectedPrice.isNotEmpty ? selectedPrice : null,
              ),

              if (showCustomPriceField)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextFormField(
                    controller: _customPriceController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.enterCustomPrice,
                      hintText: '0.00',
                      prefixText: '£',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (showCustomPriceField &&
                          (value == null || value.isEmpty)) {
                        return AppStrings.pleaseEnterPrice;
                      }
                      if (showCustomPriceField &&
                          double.tryParse(value!) == null) {
                        return AppStrings.pleaseEnterValidPrice;
                      }
                      return null;
                    },
                  ),
                ),

              DonationDropdownField(
                formFieldsHintText: qualityHintText,
                dropdownList: qualityDropdownList,
                onChanged: (val) => setState(() => selectedQuality = val!),
                charityImages: const [],
                selectedValue: selectedQuality.isNotEmpty
                    ? selectedQuality
                    : null,
              ),

              DonationDropdownField(
                formFieldsHintText: sizeHintText,
                dropdownList: sizeDropdownList,
                onChanged: (val) => setState(() => selectedSize = val!),
                charityImages: const [],
                selectedValue: selectedSize.isNotEmpty ? selectedSize : null,
              ),

              DonationFormField(
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
                isSwitchedApplicableBuyerDiscounts:
                    isSwitchedApplicableBuyerDiscounts,
                toggleSwitchApplicableBuyerDiscounts:
                    toggleSwitchApplicableBuyerDiscounts,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.thoughtsOnUpload,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

              // Padding(
              //   padding: const EdgeInsets.all(16),
              //   child: donationViewModel.status.type == StatusType.loading
              //       ? const Center(child: CircularProgressIndicator())
              //       : SizedBox(
              //           height: 56,
              //           width: double.infinity,
              //           child: FilledButton(
              //             onPressed: () {
              //               if (_formKey.currentState!.validate()) {
              //                 // Validate required dropdowns
              //                 if (selectedPrice.isEmpty ||
              //                     selectedQuality.isEmpty ||
              //                     selectedSize.isEmpty) {
              //                   Fluttertoast.showToast(
              //                     msg: AppStrings.pleaseSelectAllDropdowns,
              //                   );
              //                   return;
              //                 }
              //                 if (selectedCharity == null) {
              //                   Fluttertoast.showToast(
              //                     msg: AppStrings.pleaseSelectCharity,
              //                   );
              //                   return;
              //                 }
              //                 if (widget.selectedImages == null ||
              //                     widget.selectedImages!.isEmpty) {
              //                   Fluttertoast.showToast(
              //                     msg: AppStrings.pleaseAddPhoto,
              //                   );
              //                   return;
              //                 }
              //                 final request = buildDonationRequest();
              //                 donationViewModel.submitDonation(request);
              //               }
              //             },
              //             child: const Text(AppStrings.submitDonation),
              //           ),
              //         ),
              // ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFFF0050)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text(
                          AppStrings.back,
                          style: TextStyle(
                            color: Color(0xFFFF0050),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Validate required dropdowns
                            if (selectedPrice.isEmpty ||
                                selectedQuality.isEmpty ||
                                selectedSize.isEmpty) {
                              Fluttertoast.showToast(
                                msg: AppStrings.pleaseSelectAllDropdowns,
                              );
                              return;
                            }
                            if (selectedCharity == null) {
                              Fluttertoast.showToast(
                                msg: AppStrings.pleaseSelectCharity,
                              );
                              return;
                            }
                            if (widget.selectedImages == null ||
                                widget.selectedImages!.isEmpty) {
                              Fluttertoast.showToast(
                                msg: AppStrings.pleaseAddPhoto,
                              );
                              return;
                            }
                            final request = buildDonationRequest();
                            donationViewModel.submitDonation(request);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0050),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text(
                          AppStrings.nextButton,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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
  final VoidCallback onTap;

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
                color: isPlaceholder
                    ? theme.hintColor
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
