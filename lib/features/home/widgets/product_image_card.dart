import 'package:flutter/material.dart';

class ProductImageCard extends StatefulWidget {
  final String imagePath;
  final int likes;

  const ProductImageCard({
    Key? key,
    required this.imagePath,
    required this.likes,
  }) : super(key: key);

  @override
  State<ProductImageCard> createState() => _ProductImageCardState();
}

class _ProductImageCardState extends State<ProductImageCard> {
  int likes = 0;
  bool isLiked = false;

  void _incrementLikes() {
    setState(() {
      isLiked = true;
      likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(
            widget.imagePath,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _incrementLikes,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isLiked ? Colors.red : Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
