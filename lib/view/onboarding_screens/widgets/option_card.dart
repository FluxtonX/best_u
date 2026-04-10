import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final String? svgPath;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.svgPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : AppColors.darkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (svgPath != null || icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        colorFilter: ColorFilter.mode(
                          isSelected ? AppColors.white : AppColors.white.withOpacity(0.5),
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      )
                    : Icon(
                        icon,
                        color: isSelected ? AppColors.white : AppColors.white.withOpacity(0.5),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: GoogleFonts.outfit(
                        color: AppColors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
