import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;
    int percentage = (progress * 100).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
