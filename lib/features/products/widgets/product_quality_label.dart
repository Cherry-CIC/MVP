import 'package:flutter/material.dart';

/// Higher quality uses lighter green; all colours contrast with #FAFAFA.
class ProductQualityLabel extends StatelessWidget {
  const ProductQualityLabel(
    this.quality, {
    super.key,
    this.style,
    this.overflow,
  });

  final String quality;
  final TextStyle? style;
  final TextOverflow? overflow;

  static const colours = <String, Color>{
    'NEW': Color(0xFF4F7D24),
    'EXCELLENT': Color(0xFF38732C),
    'GOOD': Color(0xFF285E32),
    'FAIR': Color(0xFF204A30),
    'WORN': Color(0xFF19372A),
    'TEXTILES': Color(0xFF10251C),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = colours[quality.trim().toUpperCase()];
    return Text(
      quality,
      overflow: overflow,
      style: (style ?? const TextStyle()).copyWith(
        color: colour ?? theme.colorScheme.onSurface,
        // Preserve the same light-to-dark scale without losing dark labels
        // against a dark page. Unknown values retain normal theme styling.
        backgroundColor: colour != null && theme.brightness == Brightness.dark
            ? const Color(0xFFFAFAFA)
            : null,
      ),
    );
  }
}
