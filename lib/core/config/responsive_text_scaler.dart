import 'package:flutter/material.dart';

/// Computes a responsive text scale multiplier based on viewport width so
/// typography feels proportional across compact phones, standard phones,
/// and larger tablet or landscape screens while respecting OS accessibility.
class ResponsiveTextScaler {
  const ResponsiveTextScaler._();

  static const double minPhoneWidth = 320.0;
  static const double baselineMinWidth = 360.0;
  static const double baselineMaxWidth = 480.0;
  static const double maxTabletWidth = 1200.0;

  static const double minScaleFactor = 0.92;
  static const double maxScaleFactor = 1.35;
  static const double maxCombinedScale = 2.4;

  /// Returns the viewport-driven scale multiplier for [size].
  ///
  /// - Compact screens (< 360px wide): scales down smoothly to 0.92x.
  /// - Standard phones (360px–480px wide): 1.0x (unchanged).
  /// - Larger screens / tablets (> 480px wide): scales up smoothly to 1.35x.
  static double scaleFactorForSize(Size size) {
    final width = size.width;
    if (width <= 0) return 1.0;

    if (width < baselineMinWidth) {
      final t = ((width - minPhoneWidth) / (baselineMinWidth - minPhoneWidth))
          .clamp(0.0, 1.0);
      return minScaleFactor + t * (1.0 - minScaleFactor);
    }

    if (width <= baselineMaxWidth) {
      return 1.0;
    }

    final t = ((width - baselineMaxWidth) / (maxTabletWidth - baselineMaxWidth))
        .clamp(0.0, 1.0);
    return 1.0 + t * (maxScaleFactor - 1.0);
  }

  /// Combines the OS [baseScaler] with the viewport multiplier for [size],
  /// preserving nonlinear OS font scaling curves (e.g. Android 14+).
  static TextScaler textScalerFor({
    required Size size,
    required TextScaler baseScaler,
  }) {
    final responsiveFactor = scaleFactorForSize(size);
    return _ResponsiveTextScaler(
      baseScaler: baseScaler,
      responsiveFactor: responsiveFactor,
    );
  }

  /// Wraps [child] in a [MediaQuery] with responsive text scaling applied.
  static Widget builder(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: textScalerFor(
          size: mediaQuery.size,
          baseScaler: mediaQuery.textScaler,
        ),
      ),
      child: child,
    );
  }
}

class _ResponsiveTextScaler extends TextScaler {
  const _ResponsiveTextScaler({
    required this.baseScaler,
    required this.responsiveFactor,
  });

  final TextScaler baseScaler;
  final double responsiveFactor;

  @override
  double scale(double fontSize) {
    if (fontSize <= 0) return 0;
    final osScaled = baseScaler.scale(fontSize);
    final combined = osScaled * responsiveFactor;
    final minAllowed = fontSize * ResponsiveTextScaler.minScaleFactor;
    final maxAllowed = fontSize * ResponsiveTextScaler.maxCombinedScale;
    return combined.clamp(minAllowed, maxAllowed);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => (baseScaler.scale(1.0) * responsiveFactor).clamp(
    ResponsiveTextScaler.minScaleFactor,
    ResponsiveTextScaler.maxCombinedScale,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ResponsiveTextScaler &&
        other.baseScaler == baseScaler &&
        other.responsiveFactor == responsiveFactor;
  }

  @override
  int get hashCode => Object.hash(baseScaler, responsiveFactor);
}
