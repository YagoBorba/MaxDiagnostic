import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/di/injection_container.dart' as di;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? colorScheme.primary : Colors.grey.shade300,
        foregroundColor:
            isEnabled ? colorScheme.onPrimary : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isEnabled ? 4 : 0,
        shadowColor:
            isEnabled ? colorScheme.primary.withAlpha(77) : Colors.transparent,
      ),
      onPressed: () {
        if (isEnabled) {
          onPressed?.call();
        } else {
          if (onBlockedTap != null) {
            onBlockedTap!();
          } else {
            final msg = di.sl<AppConfig>().disabledStartMessage;
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
