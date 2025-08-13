// lib/features/home/presentation/view/widgets/diagnostic_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DiagnosticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;

  const DiagnosticButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4D89FF),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF4D89FF).withOpacity(0.3),
      ),
      // Em Flutter, passar null para onPressed desabilita o botão automaticamente.
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        AppLocalizations.of(context)!.start_diagnostic_button,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
