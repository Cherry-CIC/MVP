import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A temporary route that leaves the product page and its scroll position intact.
class ProductPhotoViewer extends StatefulWidget {
  ProductPhotoViewer({super.key, required this.images, required this.initialIndex})
    : assert(images.isNotEmpty),
      assert(initialIndex >= 0 && initialIndex < images.length);

  final List<ImageProvider> images;
  final int initialIndex;

  @override
  State<ProductPhotoViewer> createState() => _ProductPhotoViewerState();
}

class _ProductPhotoViewerState extends State<ProductPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || ModalRoute.of(context)?.isCurrent != true) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _showPhoto(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      label: AppStrings.photoLabel(_currentIndex + 1, widget.images.length),
                      excludeSemantics: true,
                      child: Text(
                        AppStrings.photoPosition(_currentIndex + 1, widget.images.length),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.closePhotoViewer,
                    onPressed: _close,
                    color: AppColors.white,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: Dismissible(
                  key: const ValueKey('product-photo-viewer-dismiss'),
                  direction: DismissDirection.vertical,
                  // Dismiss the route without collapsing the photo's layout.
                  resizeDuration: null,
                  dismissThresholds: const {
                    DismissDirection.up: 0.2,
                    DismissDirection.down: 0.2,
                  },
                  onDismissed: (_) => _close(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) => Image(
                      image: widget.images[index],
                      fit: BoxFit.contain,
                      semanticLabel: AppStrings.photoLabel(index + 1, widget.images.length),
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                semanticsLabel: AppStrings.photoLoading,
                              ),
                            ),
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            AppStrings.photoUnavailable,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (widget.images.length > 1)
                      IconButton(
                        tooltip: AppStrings.previousPhoto,
                        onPressed: _currentIndex > 0 ? () => _showPhoto(_currentIndex - 1) : null,
                        color: AppColors.white,
                        disabledColor: AppColors.grey,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    const Expanded(
                      child: Text(
                        AppStrings.photoViewerDismissHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ),
                    if (widget.images.length > 1)
                      IconButton(
                        tooltip: AppStrings.nextPhoto,
                        onPressed: _currentIndex < widget.images.length - 1
                            ? () => _showPhoto(_currentIndex + 1)
                            : null,
                        color: AppColors.white,
                        disabledColor: AppColors.grey,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.chevron_right),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
