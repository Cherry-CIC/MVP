import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/charity_category.dart';
import 'package:cherry_mvp/core/services/network/api_service.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/donation/models/donation_charity_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';

class DonationForm extends StatefulWidget {
  const DonationForm({super.key});

  @override
  DonationFormState createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addToCollectionController =
      TextEditingController();

  String selectedCategory = '';
  String selectedPrice = '';
  String selectedCondition = '';

  bool isSwitchedOpenToOtherCharity = false;
  bool isSwitchedOpenToOffer = false;
  bool isSwitchedApplicableBuyerDiscounts = false;
  List<CharityCategories> charityCategories = [];

  bool isCharitiesLoading = true;
  CharityCategories? selectedCharity;
  late Future<List<CharityCategories>> _charitiesTypes;
  final DioApiService _apiService = DioApiService();

  @override
  void initState() {
    super.initState();
    _charitiesTypes = backendCharities();
  }

  Future<List<CharityCategories>> backendCharities() async {
    if (kDebugMode) {
      print('🔄 Loading charities...');
    }
    final result = await _apiService.getCharityCategories();

    if (result.isSuccess && result.value != null) {
      if (kDebugMode) {
        print('✅ Successfully loaded ${result.value!.length} charities');
      }
      return result.value!;

    } else {
      if (kDebugMode) {
        print('❌ Failed to load charities: ${result.error}');
      }
      throw Exception(result.error ?? 'Failed to load charities');

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

  DonationRequest buildDonationRequest() {
    return DonationRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      category: selectedCategory,
      price: selectedPrice,
      condition: selectedCondition,
      collection: _addToCollectionController.text,
      openToOtherCharity: isSwitchedOpenToOtherCharity,
      openToOffer: isSwitchedOpenToOffer,
      applicableBuyerDiscounts: isSwitchedApplicableBuyerDiscounts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DonationViewModel>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          DonationFormField(
            controller: _titleController,
            hintText: titleHintText,
            title: titleText,
            hintIcon: Icons.add_circle,
          ),
          DonationFormField(
            controller: _descriptionController,
            hintText: descriptionHintText,
            title: descriptionText,
            hintIcon: Icons.add_circle,
            minLines: 3,
          ),
          DonationDropdownField(
            formFieldsHintText: categoryHintText,
            dropdownList: categoryDropdownList,
            onChanged: (val) => setState(() => selectedCategory = val!), charityImages: [],
          ),
          FutureBuilder<List<CharityCategories>>(
            future: _charitiesTypes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.failedToLoadCategories,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _charitiesTypes = backendCharities();
                          });
                        },
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(AppStrings.noCharitiesAvailable),
                );
              } else {
                final charityCategories = snapshot.data!;
                return DonationDropdownField(
                  formFieldsHintText: charityText,

                  charityImages: charityCategories.map((c) => c.imageUrl).toList(),
                  dropdownList: charityCategories.map((c) => c.name).toList(),
                  onChanged: (val) {
                    final selected = charityCategories.firstWhere((c) => c.name == val);
                    setState(() {
                      selectedCharity = selected;


                    });
                  },
                  selectedValue: selectedCharity?.name,

                );
              }
            },
          ),


      DonationDropdownField(
            formFieldsHintText: priceHintText,
            dropdownList: priceDropdownList,
            onChanged: (val) => setState(() => selectedPrice = val!),
          ),
          DonationDropdownField(
            formFieldsHintText: conditionHintText,
            dropdownList: conditionDropdownList,
            onChanged: (val) => setState(() => selectedCondition = val!),
          ),
          DonationFormField(
            controller: _addToCollectionController,
            hintText: addToCollectionHintText,
            title: addToCollectionText,
            suffixIcon: Icons.add,
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
            padding: EdgeInsets.all(16),
            child: viewModel.status.type == StatusType.loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (selectedCategory.isEmpty ||
                              selectedPrice.isEmpty ||
                              selectedCondition.isEmpty) {
                            Fluttertoast.showToast(
                                msg: 'Please select all dropdowns');
                            return;
                          }
                          final request = buildDonationRequest();
                          viewModel.submitDonation(request);
                        }
                      },
                      child: Text("Submit Donation"),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
