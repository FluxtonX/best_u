import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:google_fonts/google_fonts.dart';

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (svgPath != null || icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.black : AppColors.primary,
                          BlendMode.srcIn,
                        ),
                        width: 24,
                        height: 24,
                      )
                    : Icon(
                        icon,
                        color: isSelected ? Colors.black : AppColors.primary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 20),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
