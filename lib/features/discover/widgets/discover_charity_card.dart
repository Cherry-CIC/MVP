import 'package:flutter/material.dart';

const hasUserLiked = false;

class DiscoverCharityCard extends StatefulWidget {
  const DiscoverCharityCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.logoPath,
    required this.likes,
  });

  final String title;
  final String description;
  final String imagePath;
  final String logoPath;
  final int likes;

  @override
  DiscoverCharityCardState createState() => DiscoverCharityCardState();
}

class DiscoverCharityCardState extends State<DiscoverCharityCard> {
  bool isLiked = hasUserLiked;

  void toggleLiked() {
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.asset(widget.imagePath),
            Positioned(
              width: 50,
              height: 40,
              bottom: 5,
              left: 5,
              child: Image.asset(widget.logoPath),
            ),
            Positioned(
              width: 35,
              height: 25,
              bottom: 9,
              right: 9,
              child: GestureDetector(
                  onTap: toggleLiked,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSurface,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        isLiked
                            ? Icon(Icons.favorite, size: 16)
                            : Icon(Icons.favorite_border, size: 16),
                        SizedBox(width: 4),
                        Text('${widget.likes}'),
                      ],
                    ),
                  )),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        Text(
          widget.description,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
