import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightUpdateModal extends StatelessWidget {
  const WeightUpdateModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const WeightUpdateModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Spacer for centering title
                Text(
                  'Update Weight',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Keep your weight updated to track\nprogress accurately.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Input Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Current Weight (kg)',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white.withOpacity(0.1)),
              ),
              child: TextField(
                style: GoogleFonts.outfit(color: AppColors.white, fontSize: 18),
                controller: TextEditingController(text: '65'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Update Weight',
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
