import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maxt_diagnostic/core/theme/brand_theme_colors.dart';

class RotatingInfoCard extends StatefulWidget {
  const RotatingInfoCard({super.key});

  @override
  State<RotatingInfoCard> createState() => _RotatingInfoCardState();
}

class _RotatingInfoCardState extends State<RotatingInfoCard>
    with SingleTickerProviderStateMixin {
  static const _infoItems = [
    'Use a frequência 5 GHz para mais velocidade e menos interferência.',
    'Sabia que a Max oferece planos de fibra com até 1 Giga de velocidade?',
    'Reiniciar seu roteador pode resolver problemas de lentidão.',
    'Clientes Max têm suporte técnico especializado 24h por dia.',
  ];

  int _currentIndex = 0;
  Timer? _timer;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _changeInfo();
    });
  }

  void _changeInfo() {
    if (_animationController.isAnimating) return;
    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _infoItems.length;
        });
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = theme.extension<BrandThemeColors>()!;

    return Card(
      color: brandColors.primaryTintedBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: brandColors.primaryBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(LucideIcons.info, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.stay_informed,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: brandColors.primaryHeadline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 70),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  _infoItems[_currentIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: brandColors.primaryBody,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
