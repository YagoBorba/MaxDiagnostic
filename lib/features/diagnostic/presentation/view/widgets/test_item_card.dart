import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';

class TestItemCard extends StatefulWidget {
  final TestUIState test;

  const TestItemCard({super.key, required this.test});

  @override
  State<TestItemCard> createState() => _TestItemCardState();
}

class _TestItemCardState extends State<TestItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandColors =
        Theme.of(context).extension<BrandThemeColors>()!;
    final testColors = _colorsForStatus(brandColors, widget.test.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: testColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: testColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: testColors.iconContainer,
              shape: BoxShape.circle,
            ),
            child: _getIcon(widget.test.status, testColors.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.test.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: testColors.text,
                  ),
                ),
                Text(
                  widget.test.status != TestStatus.pending
                      ? widget.test.resultText ?? 'Aguardando...'
                      : 'Aguardando...',
                  style: TextStyle(
                    fontSize: 14,
                    color: testColors.result,
                    fontStyle: widget.test.status == TestStatus.pending
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getIcon(TestStatus status, Color color) {
    final IconData iconData;
    switch (widget.test.id) {
      case 'download':
        iconData = LucideIcons.arrowDownToLine;
        break;
      case 'upload':
        iconData = LucideIcons.arrowUpFromLine;
        break;
      default:
        iconData = LucideIcons.activity;
    }

    if (status == TestStatus.running || status == TestStatus.collecting) {
      return RotationTransition(
        turns: _animationController,
        child: Icon(LucideIcons.loader2, color: color),
      );
    }

    if (status == TestStatus.error) {
      return Icon(LucideIcons.alertCircle, color: color);
    }

    if (status == TestStatus.complete) {
      return Icon(iconData, color: color);
    }

    return Icon(iconData, color: color);
  }

  TestItemColors _colorsForStatus(
    BrandThemeColors colors,
    TestStatus status,
  ) {
    switch (status) {
      case TestStatus.running:
      case TestStatus.collecting:
        return colors.testRunning;
      case TestStatus.complete:
        return colors.testComplete;
      case TestStatus.error:
        return colors.testError;
      case TestStatus.pending:
        return colors.testPending;
    }
  }
}
