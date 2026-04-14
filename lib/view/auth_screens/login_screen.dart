import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/forgot_screen.dart';
import 'package:best_u/view/auth_screens/sign_up_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
            const SizedBox(height: 60),
            Text(
              'Welcome Back',
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue your journey',
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 60),
            const AuthTextField(
              label: 'Email Address',
              hintText: 'your@email.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const AuthTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotScreen()),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AuthButton(
              text: 'Sign In',
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.outfit(
                    color: AppColors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  ),
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
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
              text: 'Sign in with Apple',
              icon: const Icon(Icons.apple, color: AppColors.white, size: 24),
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            SocialButton(
              text: 'Sign in with Google',
              icon: Image.asset(
                'assets/images/google-logo.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
