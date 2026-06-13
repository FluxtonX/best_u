import 'dart:convert';
import 'dart:ui';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/auth_screens/forgot_screen.dart';
import 'package:best_u/view/auth_screens/sign_up_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/auth_screens/widgets/social_button.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      AppSnackBar.show(context, 'Please enter your email address.',
          type: AppSnackType.warning);
      return;
    }

    if (password.isEmpty) {
      AppSnackBar.show(context, 'Please enter your password.',
          type: AppSnackType.warning);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      AppSnackBar.show(context, 'Please enter a valid email address.',
          type: AppSnackType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(email, password);

      if (!mounted) return;

      if (user != null) {
        // Check onboarding status from Firebase profile data.
        final apiService = ApiService();
        final response = await apiService.getProfile();
        
        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          if (data != null && data['onboardingCompleted'] == true) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/registration');
          }
        } else {
          // If profile doesn't exist yet, go to onboarding.
          Navigator.pushReplacementNamed(context, '/registration');
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

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || _isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        // Check onboarding status from Firebase profile data.
        final apiService = ApiService();
        final response = await apiService.getProfile();
        
        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          if (data != null && data['onboardingCompleted'] == true) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/registration');
          }
        } else {
          // If profile doesn't exist yet, go to onboarding.
          Navigator.pushReplacementNamed(context, '/registration');
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
    }
  }

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
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome Back',
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
                      'Sign in to continue your journey',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 50),
                    AuthTextField(
                      controller: emailController,
                      label: 'Email Address',
                      hintText: 'your@email.com',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AuthTextField(
                          controller: passwordController,
                          label: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        const SizedBox(height: 8),
                        AppBounceAnimation(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotScreen()),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    AuthButton(
                      text: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: () {
                        if (!_isLoading) {
                          _signIn();
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
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
                                builder: (context) => const SignUpScreen()),
                          ),
                          child: const Text(
                            'Create Account',
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
                    SocialButton(
                      text: 'Google',
                      isLoading: _isGoogleLoading,
                      icon: Image.asset(
                        'assets/images/google-logo.png',
                        width: 22,
                        height: 22,
                      ),
                      onPressed: () {
                        if (!_isLoading && !_isGoogleLoading) {
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
}
