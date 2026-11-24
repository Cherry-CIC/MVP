import 'dart:async';
import 'dart:math' as math;

import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_profile_args.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const hasUserLiked = false;

class DiscoverCharityCard extends StatefulWidget {
  const DiscoverCharityCard({
    super.key,
    this.charityId,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.logoPath,
    this.logoUsesDarkBackground = false,
    required this.likes,
    this.isLiked,
    this.onLikePressed,
  });

  final String? charityId;
  final String title;
  final String description;
  final String imagePath;
  final String? logoPath;
  final bool logoUsesDarkBackground;
  final int likes;
  final bool? isLiked;
  final VoidCallback? onLikePressed;

  @override
  DiscoverCharityCardState createState() => DiscoverCharityCardState();
}

class DiscoverCharityCardState extends State<DiscoverCharityCard> {
  bool isLiked = hasUserLiked;
  int? _localLikes;

  void toggleLiked() {
    setState(() {
      isLiked = !isLiked;
      final currentLikes = _localLikes ?? widget.likes;
      _localLikes = isLiked ? currentLikes + 1 : math.max(0, currentLikes - 1);
    });
  }

  void _handleLikeTap() {
    if (widget.onLikePressed != null) {
      widget.onLikePressed!();
      return;
    }

    final productViewModel = context.read<ProductViewModel?>();
    if (productViewModel != null) {
      final resolvedId = productViewModel.resolveCharityId(
        widget.charityId,
        charityName: widget.title,
      );
      if (productViewModel.isCharityLikeUpdatePending(
        resolvedId,
        charityName: widget.title,
      )) {
        return;
      }
      unawaited(_toggleCharityLike(productViewModel));
      return;
    }

    toggleLiked();
  }

  Future<void> _toggleCharityLike(ProductViewModel productViewModel) async {
    final resolvedId = productViewModel.resolveCharityId(
      widget.charityId,
      charityName: widget.title,
    );
    final currentLikes = productViewModel.getCharityLikesCount(
      resolvedId,
      charityName: widget.title,
      fallback: widget.likes,
    );
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final result = await productViewModel.toggleCharityLike(
      Charity(
        id: resolvedId,
        name: widget.title,
        imageUrl: widget.logoPath ?? widget.imagePath,
        description: widget.description,
        likes: currentLikes,
        createdAt: epoch,
        updatedAt: epoch,
      ),
    );
    if (!result.isSuccess && mounted) {
      final message = result.error ?? 'Unable to update this liked charity.';
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openCharityProfile(BuildContext context, {String? charityId}) {
    NavigationProvider.openCharityProfileFromContext(
      context,
      CharityProfileArgs(
        charityId: charityId,
        charityName: widget.title,
        charityImageUrl: widget.logoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productViewModel = context.watch<ProductViewModel?>();
    final resolvedId =
        productViewModel?.resolveCharityId(
          widget.charityId,
          charityName: widget.title,
        ) ??
        (widget.charityId?.trim().isNotEmpty == true
            ? widget.charityId!.trim()
            : DiscoverRepository.normalizeCharityName(widget.title));
    final effectiveIsLiked =
        widget.isLiked ??
        (productViewModel != null
            ? productViewModel.isCharityLiked(
                resolvedId,
                charityName: widget.title,
              )
            : isLiked);
    final displayLikes = productViewModel != null
        ? productViewModel.getCharityLikesCount(
            resolvedId,
            charityName: widget.title,
            fallback: widget.likes,
          )
        : (_localLikes ?? widget.likes);
    final isLikePending =
        widget.onLikePressed == null &&
        productViewModel != null &&
        productViewModel.isCharityLikeUpdatePending(
          resolvedId,
          charityName: widget.title,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Semantics(
              button: true,
              label: 'Cover image for ${widget.title}',
              child: GestureDetector(
                key: ValueKey('discover-charity-image-${widget.title}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _openCharityProfile(
                  context,
                  charityId: widget.charityId,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 160),
                    child: Image.asset(
                      widget.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel: 'Cover image for ${widget.title}',
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: _CharityLogoBadge(
                charityId: widget.charityId,
                title: widget.title,
                logoPath: widget.logoPath,
                useDarkBackground: widget.logoUsesDarkBackground,
              ),
            ),
            Positioned(
              bottom: 9,
              right: 9,
              child: Semantics(
                key: ValueKey('charity-like-$resolvedId'),
                button: true,
                enabled: !isLikePending,
                label: effectiveIsLiked
                    ? AppStrings.unlikeCharity
                    : AppStrings.likeCharity,
                child: GestureDetector(
                  key: ValueKey('discover-charity-like-${widget.title}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: isLikePending ? null : _handleLikeTap,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 35,
                      minHeight: 25,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        effectiveIsLiked
                            ? Icon(Icons.favorite, size: 16)
                            : Icon(Icons.favorite_border, size: 16),
                        SizedBox(width: 4),
                        Text('$displayLikes'),
                      ],
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CharityLogoBadge extends StatelessWidget {
  const _CharityLogoBadge({
    this.charityId,
    required this.title,
    required this.logoPath,
    required this.useDarkBackground,
  });

  final String? charityId;
  final String title;
  final String? logoPath;
  final bool useDarkBackground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: logoPath == null ? 'Temporary logo for $title' : '$title logo',
      child: GestureDetector(
        key: ValueKey('discover-charity-logo-$title'),
        behavior: HitTestBehavior.opaque,
        onTap: () => NavigationProvider.openCharityProfileFromContext(
          context,
          CharityProfileArgs(
            charityId: charityId,
            charityName: title,
            charityImageUrl: logoPath,
          ),
        ),
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
