import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class ResetScreen extends StatelessWidget {
  const ResetScreen({super.key});

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
            const SizedBox(height: 40),
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Reset Password',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                color: AppColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a new secure password for your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                color: AppColors.white.withOpacity(0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 60),
            const AuthTextField(
              label: 'New Password',
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
                  style: TextStyle(fontFamily: 'Outfit', 
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
              label: 'Confirm New Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 48),
            AuthButton(
              text: 'Reset Password',
              onPressed: () {
                // Return to login after reset
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
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
            style: TextStyle(fontFamily: 'Outfit', 
              color: isMet ? Colors.green : AppColors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
