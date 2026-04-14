import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/workout_screens/achievement_screen.dart';
import 'package:best_u/view/workout_screens/workout_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  final TextEditingController _weightController = TextEditingController(text: '0');
  final TextEditingController _repsController = TextEditingController(text: '0');

  int _currentExerciseIndex = 0;

  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Bench Press',
      'sets': '3 × 10',
      'previous': '60 kg',
      'target': '65 kg',
      'progress': 0.16,
    },
    {
      'name': 'Barbell Row',
      'sets': '3 × 12',
      'previous': '50 kg',
      'target': '55 kg',
      'progress': 0.33,
    },
  ];

  void _onCompleteExercise() {
    // Show Achievement Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AchievementScreen()),
    ).then((_) {
      // After returning from achievement, move to next exercise or complete
      setState(() {
        if (_currentExerciseIndex < _exercises.length - 1) {
          _currentExerciseIndex++;
          _weightController.text = '0';
          _repsController.text = '0';
        } else {
          // Finished all exercises
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WorkoutCompleteScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercises[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Text(
                        'Exercise ${_currentExerciseIndex + 1} of 6',
                        style: GoogleFonts.outfit(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer for balance
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: exercise['progress'],
                        minHeight: 3,
                        backgroundColor: const Color(0xFF1F1F1F),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise Demonstration Card
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111820),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "💪",
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Exercise demonstration",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title and Sets/Reps
                    Text(
                      exercise['name'],
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${exercise['sets']} ",
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: "sets × reps",
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Previous and Target Stats
                    Row(
                      children: [
                        _buildStatBox("PREVIOUS", exercise['previous']),
                        const SizedBox(width: 16),
                        _buildStatBox("TARGET", exercise['target'], isTarget: true),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Log Section Header
                    Text(
                      "Log Your Result",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weight and Reps Inputs
                    Row(
                      children: [
                        _buildInputBox("Weight (kg)", _weightController),
                        const SizedBox(width: 16),
                        _buildInputBox("Reps Completed", _repsController),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Complete Exercise Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onCompleteExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "COMPLETE EXERCISE",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool isTarget = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTarget ? AppColors.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: isTarget ? AppColors.primary : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
