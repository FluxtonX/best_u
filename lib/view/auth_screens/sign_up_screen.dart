import 'dart:ui';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';
import 'package:best_u/view/registration_screen/onboarding_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join Best-U and start your transformation',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.5),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AuthTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hintText: 'your@email.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'Create a strong password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),
                  // Password Requirements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.05),
                      ),
                    ),
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
                  const SizedBox(height: 24),
                  AuthTextField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  const SizedBox(height: 48),
                  AuthButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: () {
                      if (!_isLoading) {
                        _createAccount();
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 15,
                        ),
                      ),
                      AppBounceAnimation(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: AppColors.white.withOpacity(0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withOpacity(0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: AppColors.white.withOpacity(0.1))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          text: 'Apple',
                          icon: const Icon(Icons.apple, color: AppColors.white, size: 24),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SocialButton(
                          text: 'Google',
                          icon: Image.asset(
                            'assets/images/google-logo.png',
                            width: 22,
                            height: 22,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      AppSnackBar.show(context, 'Please fill in all fields',
          type: AppSnackType.warning);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      AppSnackBar.show(context, 'Passwords do not match',
          type: AppSnackType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        AppSnackBar.show(context, 'Account Created Successfully!',
            type: AppSnackType.success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      if (errorMessage.contains('network-request-failed')) {
        errorMessage = "Network Error: Please disable Firebase reCAPTCHA in Console for testing.";
      }
      
      AppSnackBar.show(context, errorMessage, type: AppSnackType.error);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.close_rounded,
            color: isMet ? Colors.green : AppColors.primary.withOpacity(0.5),
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isMet ? Colors.green : AppColors.primary.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
