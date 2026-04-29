import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/reset_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class ForgotScreen extends StatelessWidget {
  const ForgotScreen({super.key});

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
          children: [
            const SizedBox(height: 60),
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                color: AppColors.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Forgot Your Password?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your email address and we will\nsend a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                color: AppColors.white.withOpacity(0.5),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 60),
            const AuthTextField(
              label: 'Email Address',
              hintText: 'your@email.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 40),
            AuthButton(
              text: 'Send Reset Link',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResetScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember your password? ',
                  style: TextStyle(fontFamily: 'Outfit', 
                    color: AppColors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: TextStyle(fontFamily: 'Outfit', 
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
