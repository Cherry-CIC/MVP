import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<ImageProvider> images;
  final ValueChanged<int>? onImageTap;

  const ImageCarousel({super.key, required this.images, this.onImageTap});

  @override
  State<ImageCarousel> createState() => ImageCarouselState();
}

class ImageCarouselState extends State<ImageCarousel> {
  var _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            final image = widget.images[index];
            final photo = Image(
              image: image,
              fit: BoxFit.cover,
            );
            if (widget.onImageTap == null) return photo;

            return Semantics(
              button: true,
              label: AppStrings.openPhoto(index + 1, widget.images.length),
              child: InkWell(
                onTap: () => widget.onImageTap!(index),
                child: photo,
              ),
            );
          },
          onPageChanged: (index) => setState(() => _currentPage = index),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: List.generate(widget.images.length, (index) {
              return Container(
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index ? Colors.white : Colors.white54,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
