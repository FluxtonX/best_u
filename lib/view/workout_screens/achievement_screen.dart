import 'dart:math';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

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
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: const Color(0xFF00C853),
                            size: 80,
                          ),
                          const Text(
                            "🎺",
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Achievement Text
                  Text(
                    "NEW\nPERSONAL\nBEST!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00C853),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    "You crushed it! Keep going!",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Complete Button (transparent/subtle style often seen in these designs)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "COMPLETE EXERCISE",
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
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
}

class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay();

  @override
  Widget build(BuildContext context) {
    final random = Random();
    return Stack(
      children: List.generate(40, (index) {
        final color = [
          const Color(0xFF00C853),
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
