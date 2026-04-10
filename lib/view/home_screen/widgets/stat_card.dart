import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
