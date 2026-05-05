import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class WorkoutPlanScreen extends StatelessWidget {
  const WorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                '8 Week Program',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your transformation journey',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Overall Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OVERALL PROGRESS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          '21%',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.21,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '5 of 24 workouts completed',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Weeks List
              _buildWeekItem(
                weekNumber: 1,
                status: '3/3 workouts',
                isCompleted: true,
              ),
              _buildWeekItem(
                weekNumber: 2,
                status: '2/3 workouts',
                isCurrent: true,
                isExpanded: true,
                days: [
                  _buildDayItem(context, 'Day 1', 'Base', true),
                  _buildDayItem(context, 'Day 2', 'Base', true),
                  _buildDayItem(context, 'Day 3', 'Base', false,
                      isCurrent: true),
                ],
              ),
              _buildWeekItem(
                  weekNumber: 3, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(
                  weekNumber: 4, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(
                  weekNumber: 5, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(
                  weekNumber: 6, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(
                  weekNumber: 7, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(
                  weekNumber: 8, status: '0/3 workouts', isLocked: true),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekItem({
    required int weekNumber,
    required String status,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isLocked = false,
    bool isExpanded = false,
    List<Widget>? days,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted
                ? Icons.check_rounded
                : (isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.calendar_today_rounded),
            color: isCompleted
                ? Colors.green
                : (isCurrent
                    ? AppColors.primary
                    : AppColors.white.withOpacity(0.3)),
            size: 18,
          ),
        ),
        title: Text(
          'Week $weekNumber',
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              status,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CURRENT',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
          color: Colors.white.withOpacity(0.2),
          size: 20,
        ),
        children: days != null
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(children: days),
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildDayItem(
      BuildContext context, String day, String type, bool isCompleted,
      {bool isCurrent = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WorkoutListScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white.withOpacity(0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: isCompleted ? Colors.green : AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
