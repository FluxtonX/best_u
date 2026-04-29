import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/workout_screens/exercise_session_screen.dart';
import 'package:best_u/view/workout_screens/widgets/primary_workout_button.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upper Body',
          style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 5, // Placeholder
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exercise name here',
                              style: TextStyle(fontFamily: 'Outfit', 
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '3 sets • 12 reps',
                              style: TextStyle(fontFamily: 'Outfit', 
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.play_circle_fill_rounded, color: AppColors.primary.withOpacity(0.5)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryWorkoutButton(
              title: 'Start Exercise',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExerciseSessionScreen()),
                );
              },
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
