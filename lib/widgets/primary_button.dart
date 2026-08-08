import 'package:flutter/material.dart';

/// Large, rounded call-to-action button used across the app.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label),
            ],
          );

    if (isOutlined) {
      return OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
    }

    return FilledButton(
      style: color != null
          ? FilledButton.styleFrom(backgroundColor: color)
          : null,
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
