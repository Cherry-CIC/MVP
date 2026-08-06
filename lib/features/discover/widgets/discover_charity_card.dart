import 'package:flutter/material.dart';

const hasUserLiked = false;

class DiscoverCharityCard extends StatefulWidget {
  const DiscoverCharityCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.logoPath,
    this.logoUsesDarkBackground = false,
    required this.likes,
  });

  final String title;
  final String description;
  final String imagePath;
  final String? logoPath;
  final bool logoUsesDarkBackground;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Cover image for ${widget.title}',
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: _CharityLogoBadge(
                title: widget.title,
                logoPath: widget.logoPath,
                useDarkBackground: widget.logoUsesDarkBackground,
              ),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      isLiked ? Icon(Icons.favorite, size: 16) : Icon(Icons.favorite_border, size: 16),
                      SizedBox(width: 4),
                      Text('${widget.likes}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        Text(
          widget.description,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CharityLogoBadge extends StatelessWidget {
  const _CharityLogoBadge({
    required this.title,
    required this.logoPath,
    required this.useDarkBackground,
  });

  final String title;
  final String? logoPath;
  final bool useDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: logoPath == null ? 'Temporary logo for $title' : '$title logo',
      child: Container(
        width: 72,
        height: 48,
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: useDarkBackground ? Colors.black : Theme.of(context).colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: logoPath == null
            ? _TemporaryLogoMark(title: title)
            : Image.asset(
                logoPath!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _TemporaryLogoMark(title: title),
              ),
      ),
    );
  }
}

class _TemporaryLogoMark extends StatelessWidget {
  const _TemporaryLogoMark({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final initials = title.split(' ').where((word) => word.isNotEmpty).take(2).map((word) => word[0]).join();

    return Text(
      initials,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
