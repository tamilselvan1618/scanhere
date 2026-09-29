import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable glowing gradient button with icon, label, and loading state.
class CustomGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? gradientColors;
  final double height;
  final double borderRadius;

  const CustomGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.gradientColors,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          AppTheme.accentGradientStart,
          AppTheme.accentGradientMid,
          AppTheme.accentGradientEnd,
        ];

    final isEnabled = onPressed != null && !isLoading;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey.shade400.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
