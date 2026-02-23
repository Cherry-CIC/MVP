import 'dart:io';
import 'dart:ui';

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PhotoUpload extends StatefulWidget {
  final Function(List<XFile>)? onImagesChanged;
  final List<XFile>? initialImages;

  const PhotoUpload({super.key, this.onImagesChanged, this.initialImages});

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  static const double _maxImageHeight = 1024;
  static const int _compressedImageQuality = 85;

  List<XFile> selectedImages = [];
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  bool _shouldRetryWithoutTransforms(PlatformException error) {
    final message = (error.message ?? '').toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    return error.code == 'invalid_image' &&
        (message.contains('cannot load representation') ||
            message.contains('public.jpeg') ||
            details.contains('nsitemprovidererrordomain') ||
            details.contains('public.jpeg'));
  }

  Future<List<XFile>> _pickGalleryImages(ImagePicker picker) async {
    try {
      return await picker.pickMultiImage(
        maxHeight: _maxImageHeight,
        imageQuality: _compressedImageQuality,
        requestFullMetadata: false,
      );
    } on PlatformException catch (error) {
      if (!_shouldRetryWithoutTransforms(error)) {
        rethrow;
      }

      return picker.pickMultiImage(requestFullMetadata: false);
    }
  }

  Future<XFile?> _pickCameraImage(ImagePicker picker) async {
    try {
      return await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: _maxImageHeight,
        imageQuality: _compressedImageQuality,
        requestFullMetadata: false,
      );
    } on PlatformException catch (error) {
      if (!_shouldRetryWithoutTransforms(error)) {
        rethrow;
      }

      return picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );
    }
  }

  String _platformImageErrorMessage(PlatformException error) {
    if (_shouldRetryWithoutTransforms(error)) {
      return 'Some selected photos could not be loaded. '
          'Please try different photos or add them one at a time.';
    }

    return '${AppStrings.errorPickingImage}: ${error.message ?? error.code}';
  }

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
        final List<XFile> picked = await _pickGalleryImages(picker);

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
        final XFile? picked = await _pickCameraImage(picker);

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
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_platformImageErrorMessage(error))),
        );
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

  void _openImageViewer(int initialIndex) {
    if (selectedImages.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewerPage(
          images: selectedImages,
          initialIndex: initialIndex,
        ),
      ),
    );
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
              return GestureDetector(
                onTap: () => _openImageViewer(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: FileImage(File(selectedImages[index].path)),
                      fit: BoxFit.cover,
                    ),
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
      color: AppColors.pinkBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _pickProductImage,
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0xFFFF0050),
            strokeWidth: 1,
            gap: 4,
            dash: 4,
            radius: 20,
          ),
          child: Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.takePhoto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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

class _PhotoViewerPage extends StatefulWidget {
  final List<XFile> images;
  final int initialIndex;

  const _PhotoViewerPage({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  static const double _dismissDragThreshold = 160;
  static const double _dismissVelocityThreshold = 900;

  late final PageController _pageController;
  late int _currentIndex;
  double _verticalDragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _resetDragOffset() {
    if (_verticalDragOffset == 0) return;
    setState(() {
      _verticalDragOffset = 0;
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final nextOffset = (_verticalDragOffset + details.delta.dy).clamp(
      0.0,
      double.infinity,
    );

    setState(() {
      _verticalDragOffset = nextOffset;
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _verticalDragOffset >= _dismissDragThreshold ||
        velocity >= _dismissVelocityThreshold;

    if (shouldDismiss) {
      Navigator.of(context).maybePop();
      return;
    }

    _resetDragOffset();
  }

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_verticalDragOffset / _dismissDragThreshold).clamp(
      0.0,
      1.0,
    );
    final backgroundOpacity = 1 - (dragProgress * 0.35);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(backgroundOpacity),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        onVerticalDragCancel: _resetDragOffset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _verticalDragOffset, 0),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(
                    File(widget.images[index].path),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dash = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = _dashPath(path, dash, gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, double dashArray, double gap) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashArray < metric.length)
            ? dashArray
            : metric.length - distance;
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += dashArray + gap;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        gap != oldDelegate.gap ||
        dash != oldDelegate.dash ||
        radius != oldDelegate.radius;
  }
}
