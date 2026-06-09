import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/home_screen/main_home_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  final int exercisesCompleted;
  final int durationMinutes;
  final int personalBests;
  final Map<String, String> improvements;

  const WorkoutCompleteScreen({
    super.key,
    this.exercisesCompleted = 0,
    this.durationMinutes = 42,
    this.personalBests = 0,
    this.improvements = const {},
  });

  @override
  Widget build(BuildContext context) {
    final visibleImprovements = improvements.isNotEmpty
        ? improvements
        : const <String, String>{
            'Bench Press': '+5 kg',
            'Barbell Row': '+5 kg',
            'Pull-ups': '+1 rep',
            'Overhead Press': '+2.5 kg',
          };
    final improvementCount = improvements.isNotEmpty
        ? improvements.length
        : visibleImprovements.length;
    final completedCount = exercisesCompleted > 0
        ? exercisesCompleted
        : visibleImprovements.length + 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 18),
                    const Text(
                      'Workout Complete!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Outstanding effort today!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 38),
                    _buildSummaryTile(
                      icon: Icons.fitness_center_rounded,
                      label: 'Exercises Completed',
                      value: '$completedCount',
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Personal Bests',
                      value: '$personalBests',
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryTile(
                      icon: Icons.schedule_rounded,
                      label: 'Workout Duration',
                      value: '$durationMinutes min',
                    ),
                    const SizedBox(height: 16),
                    _buildProgressCard(
                      completedCount: completedCount,
                      improvementCount: improvementCount,
                      improvements: visibleImprovements,
                    ),
                    const SizedBox(height: 14),
                    _buildQuoteCard(),
                    const SizedBox(height: 12),
                    _buildSavedMessage(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: AppBounceAnimation(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'FINISH WORKOUT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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

  Widget _buildSuccessIcon() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF0D4024),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16D86E).withValues(alpha: 0.1),
            blurRadius: 22,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_outline_rounded,
        color: Color(0xFF16D86E),
        size: 34,
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int completedCount,
    required int improvementCount,
    required Map<String, String> improvements,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D23), Color(0xFF102719)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF16D86E).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF16D86E),
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Amazing Progress!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
              children: [
                const TextSpan(text: 'You improved on '),
                TextSpan(
                  text: '$improvementCount out of $completedCount',
                  style: const TextStyle(
                    color: Color(0xFF16D86E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' exercises'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...improvements.entries.map((entry) => _buildImprovementRow(entry)),
        ],
      ),
    );
  }

  Widget _buildImprovementRow(MapEntry<String, String> entry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            entry.value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF16D86E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2910), Color(0xFF1A1510)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 46),
          SizedBox(height: 14),
          Text(
            '"Success is the sum of small\nefforts repeated day in and\nday out."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Keep crushing it!',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.save_outlined, color: Color(0xFF16D86E), size: 34),
          SizedBox(height: 10),
          Text(
            'Progress Saved!',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF16D86E),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your results have been recorded',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
