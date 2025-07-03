import 'package:cherry_mvp/core/reusablewidgets/appbar/app_bar.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'widgets/donation_form.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCommonAppBar(AppStrings.donationsText),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: const [
              PhotoUpload(),
              PhotoTipsBar(),
              SizedBox(height: 20),
              DonationForm(),
            ],
          ),
        ),
      ),
    );
  }
}
