import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

    // Start the rotation timer
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
    return Card(
      elevation: 2,
      color: const Color(0xFFEFF6FF), // Light blue background
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDBEAFE)), // Light blue border
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.info, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.stay_informed,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _infoItems[_currentIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D4ED8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}