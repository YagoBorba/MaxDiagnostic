import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/features/diagnostic/presentation/cubit/diagnostic_cubit.dart';

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
    final theme = _getTheme(widget.test.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.iconContainerColor,
              shape: BoxShape.circle,
            ),
            child: _getIcon(widget.test.status, theme.iconColor),
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
                    color: theme.textColor,
                  ),
                ),
                if (widget.test.status != TestStatus.pending)
                  Text(
                    widget.test.resultText ?? 'Aguardando...',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.resultColor,
                    ),
                  )
                else
                  const Text(
                    'Aguardando...',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
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

  _TestTheme _getTheme(TestStatus status) {
    switch (status) {
      case TestStatus.running:
      case TestStatus.collecting:
        return _TestTheme(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFF4D89FF),
          iconContainerColor: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF4D89FF),
          textColor: const Color(0xFF2563EB),
          resultColor: const Color(0xFF2563EB),
        );
      case TestStatus.complete:
        return _TestTheme(
          backgroundColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFF10B981),
          iconContainerColor: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF10B981),
          textColor: const Color(0xFF059669),
          resultColor: const Color(0xFF047857),
        );
      case TestStatus.error:
        return _TestTheme(
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFEF4444),
          iconContainerColor: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFEF4444),
          textColor: const Color(0xFFDC2626),
          resultColor: const Color(0xFFB91C1C),
        );
      case TestStatus.pending:
        return _TestTheme(
          backgroundColor: Colors.white,
          borderColor: const Color(0xFFE5E7EB),
          iconContainerColor: const Color(0xFFF1F5F9),
          iconColor: const Color(0xFF94A3B8),
          textColor: const Color(0xFF64748B),
          resultColor: Colors.grey,
        );
    }
  }
}

class _TestTheme {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconContainerColor;
  final Color iconColor;
  final Color textColor;
  final Color resultColor;

  _TestTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconContainerColor,
    required this.iconColor,
    required this.textColor,
    required this.resultColor,
  });
}
