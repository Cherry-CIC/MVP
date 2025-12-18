import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/donation_form.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  List<XFile> selectedImages = [];
  final GlobalKey<DonationFormState> _formKey = GlobalKey<DonationFormState>();

  void _handleImagesChanged(List<XFile> images) {
    setState(() {
      selectedImages = images;
    });
  }

  void _clearImages() {
    setState(() {
      selectedImages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const CloseButton(),
        title: const Text(
          AppStrings.donationsText,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PhotoUpload(
              onImagesChanged: _handleImagesChanged,
            ),
            const PhotoTipsBar(),
            const SizedBox(height: 16),
            DonationForm(
              key: _formKey,
              selectedImages: selectedImages,
              onClearImages: _clearImages,
            ),
          ],
        ),
      ),
    );
  }
}
