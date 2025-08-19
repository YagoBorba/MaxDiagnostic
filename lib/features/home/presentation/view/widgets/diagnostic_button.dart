import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

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
  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF4D89FF).withAlpha(77),
      ),
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        AppLocalizations.of(context)!.start_diagnostic_button,
  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}
