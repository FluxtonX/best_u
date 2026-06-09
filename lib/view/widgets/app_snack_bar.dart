import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';

enum AppSnackType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = _getTheme(type);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.borderColor.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.borderColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(theme.icon, color: theme.borderColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _SnackTheme _getTheme(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return _SnackTheme(
          borderColor: AppColors.primary,
          icon: Icons.check_circle_rounded,
        );
      case AppSnackType.error:
        return _SnackTheme(
          borderColor: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      case AppSnackType.warning:
        return _SnackTheme(
          borderColor: const Color(0xFFF59E0B),
          icon: Icons.warning_rounded,
        );
      case AppSnackType.info:
        return _SnackTheme(
          borderColor: AppColors.primary,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackTheme {
  final Color borderColor;
  final IconData icon;
  const _SnackTheme({required this.borderColor, required this.icon});
}
