import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:flutter/material.dart';

import 'package:cherry_mvp/features/donation/widgets/donation_options.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';
import 'package:cherry_mvp/features/donation/donation_viewmodel.dart';
import 'package:flutter/services.dart';

class DonationForm extends StatefulWidget {
  final DonationViewModel viewModel;
  const DonationForm({super.key, required this.viewModel});

  @override
  DonationFormState createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addToCollectionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) => Form(
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
              title: categoryHintText,
              items: [
                for (var category in widget.viewModel.categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  ),
              ],
              value: widget.viewModel.category,
              onChanged: (value) => widget.viewModel.category = value!,
            ),
            ListTile(
              title: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  hintText: priceHintText,
                  prefixIcon: Icon(Icons.currency_pound),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            DonationDropdownField(
              title: conditionHintText,
              items: [
                for (var condition in widget.viewModel.conditions)
                  DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  ),
              ],
              value: widget.viewModel.condition,
              onChanged: (value) => widget.viewModel.condition = value,
            ),
            DonationFormField(
              controller: _addToCollectionController,
              hintText: addToCollectionHintText,
              title: addToCollectionText,
              suffixIcon: Icons.add,
            ),
            DonationOptions(
              isOpenToOtherCharity:
                  widget.viewModel.isSwitchedOpenToOtherCharity,
              isOpenToOffer: widget.viewModel.isSwitchedOpenToOffer,
              isApplicableBuyerDiscounts:
                  widget.viewModel.isSwitchedApplicableBuyerDiscounts,
              onOpenToOtherCharityChanged: (value) =>
                  widget.viewModel.isSwitchedOpenToOtherCharity = value,
              onOpenToOfferChanged: (value) =>
                  widget.viewModel.isSwitchedOpenToOffer = value,
              onApplicableBuyerDiscountsChanged: (value) =>
                  widget.viewModel.isSwitchedApplicableBuyerDiscounts = value,
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: widget.viewModel.busy
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            return;
                          }
                        },
                        child: Text("Submit Donation"),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
