import 'dart:ui';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/registration_screen/subscription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:best_u/view/registration_screen/widgets/custom_text_field.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_button.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_progress_header.dart';
import 'package:best_u/view/registration_screen/widgets/option_card.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;

  // Selection States
  String? _selectedGoal;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveOnboardingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'weight': _weightController.text.trim(),
        'height': _heightController.text.trim(),
        'goal': _selectedGoal,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Navigate to Subscription Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty ||
          _weightController.text.trim().isEmpty ||
          _heightController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill in all personal information')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedGoal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your fitness goal')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _saveOnboardingData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  OnboardingProgressHeader(
                    currentStep: _currentStep,
                    totalSteps: 2,
                  ),
                  const SizedBox(height: 32),
                  // Logo / Title Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
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
                      const SizedBox(height: 4),
                      const Text(
                        '8 Week Transformation Program',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OnboardingButton(
                    text: _currentStep == 2 ? 'Complete Profile' : 'Continue',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : _nextStep,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: Personal Info
  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Let's get started",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tell us about yourself",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Name',
            hintText: 'Enter your name',
            controller: _nameController,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Age',
                  hintText: 'Age',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Weight (kg)',
                  hintText: 'Weight',
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Height (cm)',
            hintText: 'Height',
            controller: _heightController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // STEP 2: Goal Selection
  Widget _buildStep2() {
    final List<Map<String, dynamic>> goals = [
      {
        'title': 'Lose Weight',
        'icon': null,
        'svg': 'assets/icons/lose_weight_icon.svg',
      },
      {
        'title': 'Gain Strength',
        'icon': null,
        'svg': 'assets/icons/gain_strength.svg',
      },
      {
        'title': 'Lose Weight & Gain Strength',
        'icon': null,
        'svg': 'assets/icons/build muscle icon.svg',
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your goal?",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Choose your primary fitness objective",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ...goals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OptionCard(
                  title: goal['title'],
                  icon: goal['icon'],
                  svgPath: goal['svg'],
                  isSelected: _selectedGoal == goal['title'],
                  onTap: () => setState(() => _selectedGoal = goal['title']),
                ),
              )),
        ],
      ),
    );
  }
}
