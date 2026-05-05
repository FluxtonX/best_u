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
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withOpacity(0.05),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Reset Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a new secure password for your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 60),
            const AuthTextField(
              label: 'New Password',
              hintText: 'Create a strong password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            // Password Requirements
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASSWORD REQUIREMENTS',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRequirement('Minimum 8 characters', false),
                  _buildRequirement('One number', false),
                  _buildRequirement('One uppercase letter', false),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const AuthTextField(
              label: 'Confirm New Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outline_rounded,
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
            isMet ? Icons.check_circle_rounded : Icons.close_rounded,
            color: isMet ? Colors.green : AppColors.white.withOpacity(0.3),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isMet ? Colors.green : AppColors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
