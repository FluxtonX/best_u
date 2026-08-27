import 'dart:convert';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:best_u/view/registration_screen/before_photo_step.dart';
import 'package:best_u/view/registration_screen/verification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:best_u/view/registration_screen/widgets/custom_text_field.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_button.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_progress_header.dart';
import 'package:best_u/view/registration_screen/widgets/option_card.dart';
import 'package:flutter/material.dart';

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
  String _selectedLevel = 'beginner';

  // Step 3 is the Before Photo — it manages its own upload internally

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final res = await ApiService().getProfile();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data != null && mounted) {
          setState(() {
            if (data['name'] != null &&
                (data['name'] as String).isNotEmpty &&
                data['name'] != 'User') {
              _nameController.text = data['name'];
            }
            if (data['age'] != null && data['age'] != 0) {
              _ageController.text = data['age'].toString();
            }
            if (data['weight'] != null && data['weight'] != 0) {
              _weightController.text = data['weight'].toString();
            }
            if (data['bmi'] != null) {
              _heightController.text = data['bmi'].toString();
            }
            if (data['goal'] != null) {
              _selectedGoal = data['goal'];
            }
            if (data['strengthLevel'] != null) {
              _selectedLevel = data['strengthLevel'];
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.updateProfile({'onboardingCompleted': true});
      await apiService.checkout('price_best_u_default');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VerificationScreen(isFromOnboarding: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VerificationScreen(isFromOnboarding: true),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOnboardingData({bool thenGoToPhotoStep = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      // Step 1: Save onboarding profile without prematurely completing
      final response = await apiService.onboarding({
        'name': _nameController.text.trim(),
        'currentWeight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'targetWeight':
            (double.tryParse(_weightController.text.trim()) ?? 0.0) -
                5, // Placeholder
        'fitnessLevel': _selectedLevel == 'advanced' ? 'Advanced' : 'Beginner',
        'strengthLevel': _selectedLevel,
        'goals': [_selectedGoal ?? 'Weight Loss'],
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'bmi': double.tryParse(_heightController.text.trim()),
      }, markCompleted: !thenGoToPhotoStep);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw 'Failed to save onboarding data. Status: ${response.statusCode}';
      }

      // Step 2: Save the strength level
      await apiService.setStrengthLevel(_selectedLevel);

      if (!mounted) return;

      if (thenGoToPhotoStep) {
        // Go to the Before Photo step (step 3)
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep = 3;
          _isLoading = false;
        });
      } else {
        await _completeOnboarding();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error saving data: $e',
          type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty ||
          _weightController.text.trim().isEmpty) {
        AppSnackBar.show(context, 'Please fill in all personal information',
            type: AppSnackType.warning);
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedGoal == null) {
        AppSnackBar.show(context, 'Please select your fitness goal',
            type: AppSnackType.warning);
        return;
      }
      // Save onboarding data after step 2, then go to photo step
      _saveOnboardingData(thenGoToPhotoStep: true);
      return;
    }

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
                      totalSteps: 3,
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
                          _buildStep3(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hide the main button on step 3 — BeforePhotoStep manages its own buttons
                    if (_currentStep < 3)
                      OnboardingButton(
                        text: _currentStep == 2 ? 'Continue' : 'Continue',
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
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Name',
            hintText: 'Enter your name',
            controller: _nameController,
            keyboardType: TextInputType.name,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'BMI (If known)',
            hintText: 'BMI',
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        'svg': 'assets/icons/lose_weight.svg',
      },
      {
        'title': 'Gain Strength',
        'icon': null,
        'svg': 'assets/icons/gain_strength.svg',
      },
      {
        'title': 'Combo',
        'icon': null,
        'svg': 'assets/icons/lose_weight&gain_strength.svg',
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
              color: AppColors.white.withValues(alpha: 0.5),
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
          const SizedBox(height: 20),
          // Strength Level selector (part of step 2)
          Text(
            'Experience Level',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _levelCard(
                  emoji: '🏃',
                  label: 'Beginner',
                  value: 'beginner',
                  desc: 'Weights + bodyweight',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _levelCard(
                  emoji: '💪',
                  label: 'Advanced',
                  value: 'advanced',
                  desc: 'Weights only',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelCard({
    required String emoji,
    required String label,
    required String value,
    required String desc,
  }) {
    final selected = _selectedLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withValues(alpha: 0.1) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.07),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: selected ? AppColors.primary : AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withValues(alpha: 0.35),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Before Photo
  Widget _buildStep3() {
    return BeforePhotoStep(
      onSkip: _completeOnboarding,
      onComplete: _completeOnboarding,
    );
  }
}
