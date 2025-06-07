import 'package:flutter/material.dart';  
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/features/donation/widgets/donation_options.dart'; 
import 'package:cherry_mvp/features/donation/widgets/form_fields.dart'; 
import 'package:cherry_mvp/features/donation/widgets/dropdown_fields.dart'; 
import 'package:cherry_mvp/features/donation/donation_model.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_navigation_button.dart'; 


class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});  

  @override
  DonationScreenState createState() => DonationScreenState();
}

 

class DonationScreenState extends State<DonationScreen> {   
  bool isSwitchedOpenToOtherCharity = false;
  bool isSwitchedOpenToOffer = false;
  bool isSwitchedApplicableBuyerDiscounts = false;

  void toggleSwitchOpenToOtherCharity(bool value) {
    setState(() {
      isSwitchedOpenToOtherCharity = value; 
    });
  } 

  void toggleSwitchOpenToOffer(bool value) {
    setState(() {
      isSwitchedOpenToOffer = value; 
    });
  }

  void toggleSwitchApplicableBuyerDiscounts(bool value) {
    setState(() {
      isSwitchedApplicableBuyerDiscounts = value; 
    });
  } 

  
  
  final TextEditingController _titleController = TextEditingController(); 

  final TextEditingController _descriptionController = TextEditingController(); 

  final TextEditingController _addToCollectionController = TextEditingController(); 

  
  void onPressedBackButton() {
    //
  } 

  void onPressedNextButton() {
    //
  } 


  @override 
  Widget build(BuildContext context) {   
    final _formKey = GlobalKey<FormState>();

    return Scaffold( 
      backgroundColor: AppColors.white,  
      body: SingleChildScrollView( 
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FormFields(formFieldsController: _titleController, formFieldsHintText: TitleHintText, formFieldsTitle: TitleText, icon: Icons.add_circle, iconSuffix: null),

                FormFields(formFieldsController: _descriptionController, formFieldsHintText: DescriptionHintText, formFieldsTitle: DescriptionText, icon: Icons.add_circle, iconSuffix: null),

                DropdownFields(formFieldsHintText: CategoryHintText, dropdownList: CategoryDropdownList), 

                DropdownFields(formFieldsHintText: PriceHintText, dropdownList: PriceDropdownList),  

                DropdownFields(formFieldsHintText: ConditionHintText, dropdownList: ConditionDropdownList), 

                FormFields(formFieldsController: _addToCollectionController, formFieldsHintText: AddToCollectionHintText, formFieldsTitle: AddToCollectionText, icon: null, iconSuffix: Icons.add), 

                DonationOptions(isSwitchedOpenToOtherCharity: isSwitchedOpenToOtherCharity, toggleSwitchOpenToOtherCharity: toggleSwitchOpenToOtherCharity, isSwitchedOpenToOffer: isSwitchedOpenToOffer, toggleSwitchOpenToOffer: toggleSwitchOpenToOffer, isSwitchedApplicableBuyerDiscounts: isSwitchedApplicableBuyerDiscounts, toggleSwitchApplicableBuyerDiscounts: toggleSwitchApplicableBuyerDiscounts),

                
                DonationNavigationButton(onPressedBackButton: onPressedBackButton, onPressedNextButton: onPressedNextButton),
              ]
            )
          )
        ) 
      )
    ); 
  } 
}
