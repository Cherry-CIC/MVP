import 'package:flutter/material.dart';

class ProductImageCardDiscover extends StatefulWidget {
  final String imagePath;
  final int likes;

  const ProductImageCardDiscover({
    super.key,
    required this.imagePath,
    required this.likes,
  });

  @override
  State<ProductImageCardDiscover> createState() =>
      _ProductImageCardDiscoverState();
}

class _ProductImageCardDiscoverState extends State<ProductImageCardDiscover> {
  late int likes;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    likes = widget.likes;
  }

  void _toggleLikes() {
    if (isLiked) {
      setState(() {
        isLiked = false;
        likes--;
      });
    } else {
      setState(() {
        isLiked = true;
        likes++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            height: 100,
            width: 100,
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _toggleLikes,
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
