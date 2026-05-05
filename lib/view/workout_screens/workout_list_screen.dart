import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/workout_screens/exercise_session_screen.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> exercises = [
      {
        'name': 'Bench Press',
        'sets': '3 x 10',
        'target': 'Chest',
        'previous': '60 kg',
        'target_weight': '65 kg'
      },
      {
        'name': 'Barbell Row',
        'sets': '3 x 12',
        'target': 'Back',
        'previous': '50 kg',
        'target_weight': '55 kg'
      },
      {
        'name': 'Overhead Press',
        'sets': '3 x 8',
        'target': 'Shoulders',
        'previous': '40 kg',
        'target_weight': '42.5 kg'
      },
      {
        'name': 'Pull-ups',
        'sets': '3 x 8',
        'target': 'Back',
        'previous': '',
        'target_weight': ''
      },
      {
        'name': 'Dumbbell Curls',
        'sets': '3 x 12',
        'target': 'Arms',
        'previous': '15 kg',
        'target_weight': '17.5 kg'
      },
      {
        'name': 'Tricep Dips',
        'sets': '3 x 8',
        'target': 'Arms',
        'previous': '',
        'target_weight': ''
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'DAY 2',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Upper Body Strength',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Top Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryStat('6', 'Exercises'),
                        _buildVerticalDivider(),
                        _buildSummaryStat('29', 'Minutes'),
                        _buildVerticalDivider(),
                        _buildSummaryStat('18', 'Total Sets'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Focus Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              "Today's Focus",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Focus on controlled movements and proper form. Rest between sets as needed. Try to match or exceed your previous performance.",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Exercise Breakdown",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exercise List
                  ...exercises.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final Map<String, dynamic> exercise = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.03)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['name'],
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.fitness_center_rounded,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${exercise['sets']}  ${exercise['target']}',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (exercise['previous'] != '') ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'Previous: ${exercise['previous']}',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Target: ${exercise['target_weight']}',
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            color: AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ExerciseSessionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'START WORKOUT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.black, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.05),
    );
  }
}
