import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_tips_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'donation_view_model.dart';
import 'widgets/donation_form.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  List<XFile> selectedImages = [];
  final _popEntry = _SubmissionPopEntry();
  DonationViewModel? _viewModel;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<DonationViewModel>();
    if (_viewModel != viewModel) {
      _viewModel?.removeListener(_updatePopPermission);
      _viewModel = viewModel;
      _viewModel!.addListener(_updatePopPermission);
      _updatePopPermission();
    }
    final route = ModalRoute.of(context);
    if (_route != route) {
      _route?.unregisterPopEntry(_popEntry);
      _route = route;
      _route?.registerPopEntry(_popEntry);
    }
  }

  void _updatePopPermission() {
    // Block Back immediately, including before the submission's first rebuild.
    _popEntry.canPopNotifier.value = !_viewModel!.isSubmitting;
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_updatePopPermission);
    _route?.unregisterPopEntry(_popEntry);
    _popEntry.canPopNotifier.dispose();
    super.dispose();
  }

  void _handleImagesChanged(List<XFile> images) {
    if (!mounted || context.read<DonationViewModel>().isSubmitting) return;
    setState(() {
      selectedImages = List.of(images);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<DonationViewModel>().isSubmitting;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: isSubmitting
              ? null
              : () {
                  if (!context.read<DonationViewModel>().isSubmitting) {
                    Navigator.of(context).maybePop();
                  }
                },
        ),
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
              enabled: !isSubmitting,
            ),
            const PhotoTipsBar(),
            const SizedBox(height: 16),
            DonationForm(
              selectedImages: selectedImages,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionPopEntry extends PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(true);
}
