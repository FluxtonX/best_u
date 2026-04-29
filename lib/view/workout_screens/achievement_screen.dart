import 'dart:math';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AchievementScreen extends StatelessWidget {
  final String exerciseName;
  final String oldRecord;
  final String newRecord;

  const AchievementScreen({
    super.key,
    this.exerciseName = "Bench Press",
    this.oldRecord = "60 kg",
    this.newRecord = "65 kg",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010101),
      body: Stack(
        children: [
          // Confetti Effect
          const _ConfettiOverlay(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Trophy icon
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/personal_best_icon.svg',
                        width: 80,
                        height: 80,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Achievement Text
                  Text(
                    "NEW\nPERSONAL\nBEST!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit', 
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    exerciseName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit', 
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Record Comparison
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRecordColumn("PREVIOUS", oldRecord, Colors.white.withOpacity(0.4)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary.withOpacity(0.5),
                          size: 24,
                        ),
                      ),
                      _buildRecordColumn("NEW BEST", newRecord, AppColors.primary),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "CONTINUE WORKOUT",
                        style: TextStyle(
                          fontFamily: 'Outfit', 
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Share logic would go here
                    },
                    child: Text(
                      "SHARE ACHIEVEMENT",
                      style: TextStyle(
                        fontFamily: 'Outfit', 
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit', 
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit', 
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay();

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return Stack(
      children: List.generate(40, (index) {
        final color = [
          AppColors.primary,
          const Color(0xFF0EA5E9),
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ][random.nextInt(5)];
        
        return Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          child: Transform.rotate(
            angle: random.nextDouble() * 2 * pi,
            child: Container(
              width: random.nextDouble() * 8 + 4,
              height: random.nextDouble() * 8 + 4,
              decoration: BoxDecoration(
                color: color.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
