import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isHalfWidth;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isHalfWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
