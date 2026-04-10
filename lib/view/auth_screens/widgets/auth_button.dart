import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
          side: isPrimary ? null : BorderSide(color: AppColors.white.withOpacity(0.1)),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
