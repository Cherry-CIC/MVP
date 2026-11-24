import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'widgets/donation_form.dart';
import '../categories/category_view_model.dart';
import '../charity_page/charity_model.dart';
import '../charity_page/charity_viewmodel.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key, this.initialCharity});

  final Charity? initialCharity;

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  List<XFile> selectedImages = [];
  bool _isSubmitting = false;
  final GlobalKey<DonationFormState> _formKey = GlobalKey<DonationFormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryViewModel>().ensureCategoriesLoaded();
      context.read<CharityViewModel>().ensureCharitiesLoaded();
    });
  }

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

  Future<void> _cancelListing() async {
    if (_formKey.currentState?.hasDraftContent ?? false) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard listing?'),
          content: const Text('You’ll lose the details you’ve added to this listing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Discard listing'),
            ),
          ],
        ),
      );
      if (!mounted || discard != true) return;
    }
    if (ModalRoute.of(context)?.isCurrent == true) {
      await Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: CloseButton(onPressed: _cancelListing),
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
              initialImages: selectedImages,
              enableReordering: true,
              enabled: !_isSubmitting,
            ),
            const PhotoTipsBar(),
            const SizedBox(height: 16),
            DonationForm(
              key: _formKey,
              selectedImages: selectedImages,
              onClearImages: _clearImages,
              onSubmittingChanged: (value) => setState(() => _isSubmitting = value),
              initialCharity: widget.initialCharity,
            ),
          ],
        ),
      ),
    );
  }
}
