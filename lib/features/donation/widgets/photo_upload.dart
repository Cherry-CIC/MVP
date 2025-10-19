import 'dart:io';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoUpload extends StatefulWidget {
  final Function(List<XFile>)? onImagesChanged;
  final List<XFile>? initialImages;

  const PhotoUpload({super.key, this.onImagesChanged, this.initialImages});

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  List<XFile> selectedImages = [];
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with any pre-selected images
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      selectedImages = List.from(widget.initialImages!);
      _currentImageIndex = selectedImages.length - 1;
    }
  }

  @override
  void didUpdateWidget(PhotoUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected images if initialImages changed
    if (widget.initialImages != oldWidget.initialImages) {
      if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
        setState(() {
          selectedImages = List.from(widget.initialImages!);
          _currentImageIndex = selectedImages.isNotEmpty
              ? selectedImages.length - 1
              : 0;
        });
      } else if (widget.initialImages == null ||
          widget.initialImages!.isEmpty) {
        setState(() {
          selectedImages.clear();
          _currentImageIndex = 0;
        });
      }
    }
  }

  Future<void> pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        // Allow multiple selection from gallery
        final List<XFile> picked = await picker.pickMultiImage(
          maxWidth: double.infinity,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (picked.isNotEmpty) {
          // Filter out duplicates based on file path
          final List<XFile> newImages = [];
          for (final pickedImage in picked) {
            final isDuplicate = selectedImages.any(
              (existing) => existing.path == pickedImage.path,
            );
            if (!isDuplicate) {
              newImages.add(pickedImage);
            }
          }

          if (newImages.isNotEmpty) {
            setState(() {
              selectedImages.addAll(newImages);
              _currentImageIndex = selectedImages.length - 1;
            });
            widget.onImagesChanged?.call(selectedImages);

            // Animate to the last added image
            if (selectedImages.length > 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    _currentImageIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          }
        }
      } else {
        // Single image from camera
        final XFile? picked = await picker.pickImage(
          source: source,
          maxWidth: double.infinity,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (picked != null) {
          // Check for duplicates
          final isDuplicate = selectedImages.any(
            (existing) => existing.path == picked.path,
          );

          if (!isDuplicate) {
            setState(() {
              selectedImages.add(picked);
              _currentImageIndex = selectedImages.length - 1;
            });
            widget.onImagesChanged?.call(selectedImages);

            // Animate to the newly added image
            if (selectedImages.length > 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    _currentImageIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPickingImage}: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      if (_currentImageIndex >= selectedImages.length &&
          selectedImages.isNotEmpty) {
        _currentImageIndex = selectedImages.length - 1;
      } else if (selectedImages.isEmpty) {
        _currentImageIndex = 0;
      }
    });
    widget.onImagesChanged?.call(selectedImages);

    // Animate to valid page if needed
    if (selectedImages.isNotEmpty &&
        _currentImageIndex < selectedImages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _pickProductImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text(AppStrings.cameraPhoto),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(AppStrings.galleryPhotoMultiple),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await pickImages(source);
  }

  Widget _buildImageCarousel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      height: MediaQuery.of(context).size.width - 32,
      width: double.infinity,
      child: Stack(
        children: [
          // Image carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(File(selectedImages[index].path)),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _removeImage(_currentImageIndex),
              ),
            ),
          ),

          // Add more button
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                onPressed: _pickProductImage,
              ),
            ),
          ),

          // Image counter
          if (selectedImages.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${selectedImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Page indicators
          if (selectedImages.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  selectedImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _pickProductImage,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
            color: AppColors.pinkBackground,
          ),
          height: 160,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.takePhoto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.tapToAddPhotos,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(AppStrings.takePhotoInstruction),
          selectedImages.isNotEmpty
              ? _buildImageCarousel()
              : _buildEmptyState(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
