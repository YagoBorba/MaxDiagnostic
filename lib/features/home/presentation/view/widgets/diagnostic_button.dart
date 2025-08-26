import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/config/app_config.dart';

class DiagnosticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final VoidCallback? onBlockedTap;

  const DiagnosticButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
    this.onBlockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? const Color(0xFF4D89FF) : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isEnabled ? 4 : 0,
        shadowColor: const Color(0xFF4D89FF).withAlpha(77),
      ),
      onPressed: () {
        if (isEnabled) {
          onPressed?.call();
        } else {
          if (onBlockedTap != null) {
            onBlockedTap!();
          } else {
            final msg = context.read<AppConfig>().disabledStartMessage;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      },
      child: Text(
        AppLocalizations.of(context)!.start_diagnostic_button,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}
