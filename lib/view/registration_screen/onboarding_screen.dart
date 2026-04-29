import 'package:best_u/constant/app_theme_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:best_u/view/registration_screen/widgets/custom_text_field.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_button.dart';
import 'package:best_u/view/registration_screen/widgets/onboarding_logo.dart';
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
  String? _selectedExperience;

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
        'experienceLevel': _selectedExperience,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Navigate to Home or Subscription (as per original flow, but user asked for Home)
      Navigator.pushReplacementNamed(context, '/home');
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
          const SnackBar(content: Text('Please fill in all personal information')),
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
    } else if (_currentStep == 3) {
      if (_selectedExperience == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your experience level')),
        );
        return;
      }
    }

    if (_currentStep < 3) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              OnboardingProgressHeader(currentStep: _currentStep),
              const SizedBox(height: 40),
              const OnboardingLogo(),
              const SizedBox(height: 48),
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
              OnboardingButton(
                text: 'Continue',
                isLoading: _isLoading,
                onPressed: _isLoading ? () {} : _nextStep,
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          Text(
            "Let's get started",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
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
        'svg': 'assets/icons/lose_weight_icon.svg'
      },
      {
        'title': 'Gain Strength',
        'icon': null,
        'svg': 'assets/icons/gain_strength.svg'
      },
      {
        'title': 'Build Muscle',
        'icon': null,
        'svg': 'assets/icons/build muscle icon.svg'
      },
      {
        'title': 'Improve Endurance',
        'icon': null,
        'svg': 'assets/icons/build muscle icon.svg'
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your goal?",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose your primary fitness objective",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
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

  // STEP 3: Experience Selection
  Widget _buildStep3() {
    final List<Map<String, dynamic>> levels = [
      {
        'title': 'Beginner',
        'description': 'New to fitness',
        'icon': null,
      },
      {
        'title': 'Intermediate',
        'description': '6+ months experience',
        'icon': null,
      },
      {
        'title': 'Advanced',
        'description': '2+ years experience',
        'icon': null,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Experience level",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Help us tailor your program",
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ...levels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OptionCard(
                  title: level['title'],
                  description: level['description'],
                  icon: level['icon'],
                  isSelected: _selectedExperience == level['title'],
                  onTap: () =>
                      setState(() => _selectedExperience = level['title']),
                ),
              )),
        ],
      ),
    );
  }
}
