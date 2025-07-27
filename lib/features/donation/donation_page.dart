import 'package:cherry_mvp/features/donation/donation_viewmodel.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'widgets/donation_form.dart';

class DonationPage extends StatelessWidget {
  final DonationViewModel viewModel;
  const DonationPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(),
        title: Text(AppStrings.donationsText),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PhotoUpload(viewModel: viewModel),
            const PhotoTipsBar(),
            const SizedBox(height: 16),
            DonationForm(
              viewModel: viewModel,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
