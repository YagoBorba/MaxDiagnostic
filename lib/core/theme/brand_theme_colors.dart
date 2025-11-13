import 'package:flutter/material.dart';

@immutable
class BrandThemeColors extends ThemeExtension<BrandThemeColors> {
  const BrandThemeColors({
    required this.primaryTintedBackground,
    required this.primaryBorder,
    required this.primaryHeadline,
    required this.primaryBody,
    required this.adviceCritical,
    required this.adviceWarning,
    required this.adviceGood,
    required this.adviceInfo,
    required this.testRunning,
    required this.testComplete,
    required this.testError,
    required this.testPending,
    required this.signalExcellent,
    required this.signalNormal,
    required this.signalPoor,
  });

  final Color primaryTintedBackground;
  final Color primaryBorder;
  final Color primaryHeadline;
  final Color primaryBody;
  final AdviceColors adviceCritical;
  final AdviceColors adviceWarning;
  final AdviceColors adviceGood;
  final AdviceColors adviceInfo;
  final TestItemColors testRunning;
  final TestItemColors testComplete;
  final TestItemColors testError;
  final TestItemColors testPending;
  final Color signalExcellent;
  final Color signalNormal;
  final Color signalPoor;

  @override
  BrandThemeColors copyWith({
    Color? primaryTintedBackground,
    Color? primaryBorder,
    Color? primaryHeadline,
    Color? primaryBody,
    AdviceColors? adviceCritical,
    AdviceColors? adviceWarning,
    AdviceColors? adviceGood,
    AdviceColors? adviceInfo,
    TestItemColors? testRunning,
    TestItemColors? testComplete,
    TestItemColors? testError,
    TestItemColors? testPending,
    Color? signalExcellent,
    Color? signalNormal,
    Color? signalPoor,
  }) {
    return BrandThemeColors(
      primaryTintedBackground:
          primaryTintedBackground ?? this.primaryTintedBackground,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      primaryHeadline: primaryHeadline ?? this.primaryHeadline,
      primaryBody: primaryBody ?? this.primaryBody,
      adviceCritical: adviceCritical ?? this.adviceCritical,
      adviceWarning: adviceWarning ?? this.adviceWarning,
      adviceGood: adviceGood ?? this.adviceGood,
      adviceInfo: adviceInfo ?? this.adviceInfo,
      testRunning: testRunning ?? this.testRunning,
      testComplete: testComplete ?? this.testComplete,
      testError: testError ?? this.testError,
      testPending: testPending ?? this.testPending,
      signalExcellent: signalExcellent ?? this.signalExcellent,
      signalNormal: signalNormal ?? this.signalNormal,
      signalPoor: signalPoor ?? this.signalPoor,
    );
  }

  @override
  BrandThemeColors lerp(
    ThemeExtension<BrandThemeColors>? other,
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
      adviceCritical: adviceCritical.lerp(other.adviceCritical, t),
      adviceWarning: adviceWarning.lerp(other.adviceWarning, t),
      adviceGood: adviceGood.lerp(other.adviceGood, t),
      adviceInfo: adviceInfo.lerp(other.adviceInfo, t),
      testRunning: testRunning.lerp(other.testRunning, t),
      testComplete: testComplete.lerp(other.testComplete, t),
      testError: testError.lerp(other.testError, t),
      testPending: testPending.lerp(other.testPending, t),
      signalExcellent:
          Color.lerp(signalExcellent, other.signalExcellent, t)!,
      signalNormal: Color.lerp(signalNormal, other.signalNormal, t)!,
      signalPoor: Color.lerp(signalPoor, other.signalPoor, t)!,
    );
  }
}

@immutable
class AdviceColors {
  const AdviceColors({
    required this.background,
    required this.icon,
    required this.title,
    required this.text,
  });

  final Color background;
  final Color icon;
  final Color title;
  final Color text;

  AdviceColors copyWith({
    Color? background,
    Color? icon,
    Color? title,
    Color? text,
  }) {
    return AdviceColors(
      background: background ?? this.background,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      text: text ?? this.text,
    );
  }

  AdviceColors lerp(AdviceColors other, double t) {
    return AdviceColors(
      background: Color.lerp(background, other.background, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      title: Color.lerp(title, other.title, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}

@immutable
class TestItemColors {
  const TestItemColors({
    required this.background,
    required this.border,
    required this.iconContainer,
    required this.icon,
    required this.text,
    required this.result,
  });

  final Color background;
  final Color border;
  final Color iconContainer;
  final Color icon;
  final Color text;
  final Color result;

  TestItemColors copyWith({
    Color? background,
    Color? border,
    Color? iconContainer,
    Color? icon,
    Color? text,
    Color? result,
  }) {
    return TestItemColors(
      background: background ?? this.background,
      border: border ?? this.border,
      iconContainer: iconContainer ?? this.iconContainer,
      icon: icon ?? this.icon,
      text: text ?? this.text,
      result: result ?? this.result,
    );
  }

  TestItemColors lerp(TestItemColors other, double t) {
    return TestItemColors(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconContainer: Color.lerp(iconContainer, other.iconContainer, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      text: Color.lerp(text, other.text, t)!,
      result: Color.lerp(result, other.result, t)!,
    );
  }
}
