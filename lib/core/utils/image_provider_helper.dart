import 'package:flutter/material.dart';

class ImageProviderHelper {
  /// Returns the appropriate ImageProvider based on whether the path is a URL or asset
  static ImageProvider getImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }

  /// Creates a reusable Image widget that can handle both network and asset images
  static Widget buildImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
    BorderRadius? borderRadius,
  }) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Icon(
                  Icons.broken_image,
                  size: width ?? height ?? 24,
                  color: Colors.grey,
                );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return loadingWidget ??
                SizedBox(
                  width: width,
                  height: height,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
          },
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Icon(
                  Icons.broken_image,
                  size: width ?? height ?? 24,
                  color: Colors.grey,
                );
          },
        ),
      );
    }
  }
}