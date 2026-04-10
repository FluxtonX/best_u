import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/onboarding_screens/widgets/custom_text_field.dart';
import 'package:best_u/view/onboarding_screens/widgets/onboarding_button.dart';
import 'package:best_u/view/onboarding_screens/widgets/onboarding_logo.dart';
import 'package:best_u/view/onboarding_screens/widgets/onboarding_progress_header.dart';
import 'package:best_u/view/onboarding_screens/widgets/option_card.dart';
import 'package:best_u/view/subscription_screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      );
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
                onPressed: _nextStep,
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
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself",
            style: GoogleFonts.outfit(
              color: AppColors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          const CustomTextField(
            label: 'Name',
            hintText: 'Enter your name',
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Age',
                  hintText: 'Age',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Weight (kg)',
                  hintText: 'Weight',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const CustomTextField(
            label: 'Height (cm)',
            hintText: 'Height',
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
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose your primary fitness objective",
            style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Help us tailor your program",
            style: GoogleFonts.outfit(
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
