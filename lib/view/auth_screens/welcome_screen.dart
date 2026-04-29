import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/sign_up_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';
import 'package:flutter/material.dart';
// // import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Logo Section
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/welcom-logo.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        children: const [
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
                  ],
                ),
                const SizedBox(height: 48),
                // Headline Section
                Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        children: const [
                          TextSpan(text: 'Become the '),
                          TextSpan(
                            text: 'Best\nVersion',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(text: ' of You'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Follow an 8-week blueprint to lose\nweight and increase strength.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.6),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Transform in 8 weeks',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.bolt, color: Colors.green, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                // Buttons Section
                Column(
                  children: [
                    AuthButton(
                      text: 'Create Account',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: 'Sign In',
                      isPrimary: false,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.white.withOpacity(0.08),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.white.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SocialButton(
                      text: 'Continue with Apple',
                      icon: const Icon(Icons.apple,
                          color: AppColors.white, size: 24),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    SocialButton(
                      text: 'Continue with Google',
                      icon: Image.asset(
                        'assets/images/google-logo.png',
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
