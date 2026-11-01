import 'dart:io';
import 'dart:math' as math;

import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Local donation photos in their eventual listing order.
class PhotoReorderStrip extends StatefulWidget {
  const PhotoReorderStrip({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.enabled,
    required this.onSelected,
    required this.onReorder,
  });

  final List<XFile> images;
  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelected;
  final ReorderCallback onReorder;

  @override
  State<PhotoReorderStrip> createState() => _PhotoReorderStripState();
}

class _PhotoReorderStripState extends State<PhotoReorderStrip> {
  final ScrollController _scrollController = ScrollController();

  double _thumbnailSize() => 104.0 + math.max(0.0, MediaQuery.textScalerOf(context).scale(12) - 12) * 6;

  @override
  void initState() {
    super.initState();
    _keepSelectionVisible();
  }

  @override
  void didUpdateWidget(PhotoReorderStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _keepSelectionVisible();
  }

  void _keepSelectionVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final start = widget.selectedIndex * (_thumbnailSize() + 12);
      final end = start + _thumbnailSize();
      final offset = start < position.pixels
          ? start
          : end > position.pixels + position.viewportDimension
          ? end - position.viewportDimension
          : position.pixels;
      final target = offset.clamp(position.minScrollExtent, position.maxScrollExtent);
      if (target != position.pixels) {
        _scrollController.animateTo(target, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final selectedBorder = Theme.of(context).brightness == Brightness.dark ? colours.primary : AppColors.primaryAction;
    // Leave room for the cover label when the user increases text size.
    final size = _thumbnailSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: size + 8,
          child: ReorderableListView.builder(
            primary: false,
            scrollController: _scrollController,
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemExtent: size + 12,
            itemCount: widget.images.length,
            onReorderItem: (from, to) {
              if (widget.enabled) widget.onReorder(from, to);
            },
            proxyDecorator: (child, index, animation) => Material(
              color: colours.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
            itemBuilder: (context, index) {
              final selected = widget.selectedIndex == index;
              final label = AppStrings.photoPosition(index + 1, widget.images.length);
              return Padding(
                key: ValueKey(widget.images[index].path),
                padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  enabled: widget.enabled && widget.images.length > 1,
                  child: Semantics(
                    label: index == 0 ? '$label, ${AppStrings.coverPhoto}' : label,
                    hint: AppStrings.previewPhotoHint,
                    button: true,
                    selected: selected,
                    onTap: () => widget.onSelected(index),
                    excludeSemantics: true,
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected ? selectedBorder : colours.outline,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => widget.onSelected(index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(widget.images[index].path),
                              fit: BoxFit.cover,
                              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.white)),
                                ),
                              ),
                            ),
                            if (index == 0)
                              Positioned(
                                bottom: 5,
                                left: 5,
                                right: 5,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAction,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    child: Text(
                                      AppStrings.coverPhoto,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.reorderPhotosHint,
            style: TextStyle(color: colours.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(AppStrings.photoPosition(widget.selectedIndex + 1, widget.images.length)),
          ),
        ],
      ],
    );
  }
}
