import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width filled action button matching the Figma design:
/// 14px corner radius, white bold label, optional leading icon, ~54px tall.
/// Used for primary actions like "Сохранить", "Активировать", "Сменить пароль".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.leading,
    this.color = AppColors.primaryBlue,
    this.colorText,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Material icon shown before the label. If [leading] is set, it wins.
  final IconData? icon;

  /// Arbitrary leading widget (e.g. `SvgPicture.asset(...)`) — takes priority
  /// over [icon].
  final Widget? leading;
  final Color color;
  final Color? colorText;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: TextStyle(color: colorText)),
                ],
              ),
      ),
    );
  }
}
