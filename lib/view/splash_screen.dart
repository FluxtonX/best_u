import 'dart:async';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Diffuse Glow Background
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),

                // Logo Icon Box
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/gain_strength.svg',
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title "Best-U"
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Best-',
                        style: TextStyle(color: AppColors.white),
                      ),
                      TextSpan(
                        text: 'U',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline "✦ Transform Your Body ✦"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TRANSFORM YOUR BODY',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 4),

                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(false),
                    const SizedBox(width: 10),
                    _buildDot(true),
                    const SizedBox(width: 10),
                    _buildDot(false),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer Text
                Text(
                  '8 Week Transformation Program',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
    );
  }
}
