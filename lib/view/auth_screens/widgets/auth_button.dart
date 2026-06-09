import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBounceAnimation(
      onTap: isLoading ? null : onPressed,
      isDisabled: isLoading,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use finite max width to avoid interpolation error with double.infinity
          final maxWidth = constraints.maxWidth;

          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isLoading ? 56 : maxWidth,
              height: 56,
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primary : Colors.black,
                borderRadius: BorderRadius.circular(isLoading ? 28 : 14),
                border: isPrimary
                    ? null
                    : Border.all(
                        color: AppColors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                boxShadow: isPrimary && !isLoading
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? _AuthButtonLoader(isPrimary: isPrimary)
                    : Text(
                        text,
                        key: const ValueKey('btn_text'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isPrimary ? Colors.black : AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthButtonLoader extends StatelessWidget {
  final bool isPrimary;

  const _AuthButtonLoader({required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? Colors.black : AppColors.primary;
    return SizedBox(
      key: const ValueKey('btn_loader'),
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              strokeCap: StrokeCap.round,
              backgroundColor: color.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
