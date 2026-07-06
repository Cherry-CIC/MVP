import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/product.dart'; // make sure this path is correct

class ProductImageCard extends StatefulWidget {
  final Product product;

  const ProductImageCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductImageCard> createState() => _ProductImageCardState();
}

class _ProductImageCardState extends State<ProductImageCard> {
  late int likes;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    likes = widget.product.likes;
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likes += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.product.productImages.isNotEmpty
        ? widget.product.productImages[0]
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagePath.isNotEmpty)
          Image.asset(
            imagePath,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          )
        else
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(child: Icon(Icons.image_not_supported)),
          ),
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: isLiked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    likes.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
