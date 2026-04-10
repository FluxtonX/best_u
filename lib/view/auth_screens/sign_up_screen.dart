import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';
import 'package:best_u/view/onboarding_screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Create Account',
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join Best-U and start your transformation',
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            const AuthTextField(
              label: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 24),
            const AuthTextField(
              label: 'Email Address',
              hintText: 'your@email.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            const AuthTextField(
              label: 'Password',
              hintText: 'Create a strong password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            // Password Requirements
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASSWORD REQUIREMENTS',
                  style: GoogleFonts.outfit(
                    color: AppColors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRequirement('Minimum 8 characters', false),
                _buildRequirement('One number', false),
                _buildRequirement('One uppercase letter', false),
              ],
            ),
            const SizedBox(height: 24),
            const AuthTextField(
              label: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 48),
            AuthButton(
              text: 'Create Account',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OnboardingScreen()));
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: GoogleFonts.outfit(
                    color: AppColors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                    child: Divider(color: AppColors.white.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: GoogleFonts.outfit(
                      color: AppColors.white.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                    child: Divider(color: AppColors.white.withOpacity(0.05))),
              ],
            ),
            const SizedBox(height: 32),
            SocialButton(
              text: 'Continue with Apple',
              icon: const Icon(Icons.apple, color: AppColors.white, size: 24),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            SocialButton(
              text: 'Continue with Google',
              icon: const Icon(Icons.g_mobiledata,
                  color: AppColors.white, size: 28),
              onPressed: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check : Icons.close,
            color: isMet ? Colors.green : AppColors.white.withOpacity(0.3),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: isMet ? Colors.green : AppColors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
