import 'dart:io';

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/widgets/image_carousel.dart';
import 'package:cherry_mvp/features/donation/donation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoUpload extends StatefulWidget {
  final DonationViewModel viewModel;

  const PhotoUpload({
    super.key,
    required this.viewModel,
  });

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  final _carouselController = PageController();

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text(AppStrings.takePhotoInstruction),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _pickProductImage(context),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  height: viewModel.images.isNotEmpty
                      ? MediaQuery.of(context).size.width - 32
                      : 160,
                  width: double.infinity,
                  child: viewModel.images.isNotEmpty
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ImageCarousel(
                                  controller: _carouselController,
                                  images: viewModel.images
                                      .map((e) => FileImage(File(e.path)))
                                      .toList(),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: Material(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20),
                                      ),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: InkWell(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                        onTap: () => _pickProductImage(context),
                                        child: Icon(Icons.photo_library),
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(width: 1),
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: Material(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(20),
                                        bottomRight: Radius.circular(20),
                                      ),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child: InkWell(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                        onTap: () => viewModel.removeImage(
                                            viewModel.images[_carouselController
                                                    .page
                                                    ?.round() ??
                                                0]),
                                        child: Icon(Icons.delete),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.takePhoto,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: double.infinity,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        widget.viewModel.addImage(picked);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(widget.viewModel.images.length < 2) return;
          _carouselController.animateToPage(
            widget.viewModel.images.length - 1,
            duration: Durations.short3,
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _pickProductImage(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.cameraPhoto),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.galleryPhoto),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await _pickImage(context, source);
  }
}
