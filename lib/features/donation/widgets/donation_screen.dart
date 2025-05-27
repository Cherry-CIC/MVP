import 'package:flutter/material.dart';  
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/features/donation/widgets/donation_options.dart'; 


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

                DonationOptions(isSwitchedOpenToOtherCharity: isSwitchedOpenToOtherCharity, toggleSwitchOpenToOtherCharity: toggleSwitchOpenToOtherCharity, isSwitchedOpenToOffer: isSwitchedOpenToOffer, toggleSwitchOpenToOffer: toggleSwitchOpenToOffer, isSwitchedApplicableBuyerDiscounts: isSwitchedApplicableBuyerDiscounts, toggleSwitchApplicableBuyerDiscounts: toggleSwitchApplicableBuyerDiscounts),
              ]
            )
          )
        ) 
      )
    ); 
  } 
}
