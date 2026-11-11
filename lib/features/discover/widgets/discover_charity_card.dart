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
              bottom: 0,
              right: 0,
              child: Semantics(
                button: true,
                toggled: isLiked,
                label: isLiked
                    ? 'Unlike ${widget.title}, ${widget.likes} likes'
                    : 'Like ${widget.title}, ${widget.likes} likes',
                excludeSemantics: true,
                onTap: toggleLiked,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggleLiked,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: kMinInteractiveDimension,
                      minHeight: kMinInteractiveDimension,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isLiked ? const Icon(Icons.favorite, size: 16) : const Icon(Icons.favorite_border, size: 16),
                            const SizedBox(width: 4),
                            Text('${widget.likes}'),
                          ],
                        ),
                      ),
                    ),
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
      excludeSemantics: true,
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
