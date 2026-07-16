import 'dart:ui';
import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:best_u/view/auth_screens/terms_screen.dart';
import 'package:best_u/view/auth_screens/privacy_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 28,
              ),
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
                      keyboardType: TextInputType.visiblePassword,
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
                      keyboardType: TextInputType.visiblePassword,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          visualDensity:
                              const VisualDensity(horizontal: -4, vertical: -4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: AppColors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.white.withOpacity(0.7),
                                fontSize: 13,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TermsScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PrivacyScreen(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
                              builder: (context) => const LoginScreen(),
                            ),
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
                          child: Divider(color: AppColors.white.withOpacity(0.1)),
                        ),
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
                          child: Divider(color: AppColors.white.withOpacity(0.1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SocialButton(
                      text: 'Google',
                      icon: Image.asset(
                        'assets/images/google-logo.png',
                        width: 22,
                        height: 22,
                      ),
                      onPressed: () {
                        if (!_isLoading) {
                          _signInWithGoogle();
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty) {
      AppSnackBar.show(
        context,
        'Please enter your email address.',
        type: AppSnackType.warning,
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      AppSnackBar.show(
        context,
        'Please enter a valid email address.',
        type: AppSnackType.warning,
      );
      return;
    }

    if (password.isEmpty) {
      AppSnackBar.show(
        context,
        'Please enter a password.',
        type: AppSnackType.warning,
      );
      return;
    }

    if (password.length < 6) {
      AppSnackBar.show(
        context,
        'Password must be at least 6 characters long.',
        type: AppSnackType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.show(
        context,
        'Passwords do not match.',
        type: AppSnackType.error,
      );
      return;
    }

    if (!_agreedToTerms) {
      AppSnackBar.show(
        context,
        'Please agree to the Terms of Service and Privacy Policy.',
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUp(email, password);

      if (!mounted) return;

      if (user != null) {
        AppSnackBar.show(
          context,
          'Account Created Successfully!',
          type: AppSnackType.success,
        );
        Navigator.pushNamedAndRemoveUntil(context, '/registration', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        // Check onboarding status from Firebase profile data.
        final apiService = ApiService();
        final response = await apiService.getProfile();

        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body)['data'];
          if (data != null && data['onboardingCompleted'] == true) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/registration', (route) => false);
          }
        } else {
          // If profile doesn't exist yet, go to onboarding.
          Navigator.pushNamedAndRemoveUntil(context, '/registration', (route) => false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), type: AppSnackType.error);
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
