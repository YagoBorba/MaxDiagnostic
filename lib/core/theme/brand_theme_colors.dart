import 'package:flutter/material.dart';

@immutable
class BrandThemeColors extends ThemeExtension<BrandThemeColors> {
  const BrandThemeColors({
    required this.primaryTintedBackground,
    required this.primaryBorder,
    required this.primaryHeadline,
    required this.primaryBody,
  });

  final Color primaryTintedBackground;
  final Color primaryBorder;
  final Color primaryHeadline;
  final Color primaryBody;

  @override
  BrandThemeColors copyWith({
    Color? primaryTintedBackground,
    Color? primaryBorder,
    Color? primaryHeadline,
    Color? primaryBody,
  }) {
    return BrandThemeColors(
      primaryTintedBackground:
          primaryTintedBackground ?? this.primaryTintedBackground,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      primaryHeadline: primaryHeadline ?? this.primaryHeadline,
      primaryBody: primaryBody ?? this.primaryBody,
    );
  }

  @override
  BrandThemeColors lerp(
    covariant ThemeExtension<BrandThemeColors>? other,
    double t,
  ) {
    if (other is! BrandThemeColors) {
      return this;
    }

    return BrandThemeColors(
      primaryTintedBackground:
          Color.lerp(primaryTintedBackground, other.primaryTintedBackground, t)!,
      primaryBorder: Color.lerp(primaryBorder, other.primaryBorder, t)!,
      primaryHeadline: Color.lerp(primaryHeadline, other.primaryHeadline, t)!,
      primaryBody: Color.lerp(primaryBody, other.primaryBody, t)!,
    );
  }
}
