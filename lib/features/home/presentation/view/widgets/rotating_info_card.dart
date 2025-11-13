import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final primaryColor = theme.colorScheme.primary;
    final tintedBackground = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.08),
      theme.colorScheme.surface,
    );
    final borderColor = primaryColor.withValues(alpha: 0.2);
    final headlineColor = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.2),
      primaryColor,
    );
    final bodyColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.1),
      primaryColor,
    );

    return Card(
      elevation: 2,
      color: tintedBackground,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(LucideIcons.info, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.stay_informed,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: headlineColor,
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
                    color: bodyColor,
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
