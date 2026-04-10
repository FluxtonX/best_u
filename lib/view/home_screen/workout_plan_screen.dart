import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              Text(
                'Workout Plan',
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '8 Week Program',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your transformation journey',
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              // Overall Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OVERALL PROGRESS',
                          style: GoogleFonts.outfit(
                            color: AppColors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '21%',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.21,
                        backgroundColor: AppColors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '5 of 24 workouts completed',
                          style: GoogleFonts.outfit(
                            color: AppColors.white.withOpacity(0.4),
                            fontSize: 12,
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
                days: [
                  _buildDayItem('Day 1', 'Base', true),
                  _buildDayItem('Day 2', 'Base', true),
                  _buildDayItem('Day 3', 'Base', true),
                ],
              ),
              _buildWeekItem(
                weekNumber: 2,
                status: '2/3 workouts',
                isCurrent: true,
                days: [
                  _buildDayItem('Day 1', 'Base', true),
                  _buildDayItem('Day 2', 'Base', true),
                  _buildDayItem('Day 3', 'Base', false, isCurrent: true),
                ],
              ),
              _buildWeekItem(weekNumber: 3, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(weekNumber: 4, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(weekNumber: 5, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(weekNumber: 6, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(weekNumber: 7, status: '0/3 workouts', isLocked: true),
              _buildWeekItem(weekNumber: 8, status: '0/3 workouts', isLocked: true),
              const SizedBox(height: 20),
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
    List<Widget>? days,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppColors.primary.withOpacity(0.3) : AppColors.white.withOpacity(0.05),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrent,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : (isCurrent ? AppColors.primary.withOpacity(0.1) : AppColors.white.withOpacity(0.05)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : (isLocked ? Icons.lock_outline_rounded : Icons.calendar_today_rounded),
              color: isCompleted ? Colors.green : (isCurrent ? AppColors.primary : AppColors.white.withOpacity(0.3)),
              size: 20,
            ),
          ),
          title: Text(
            'Week $weekNumber',
            style: GoogleFonts.outfit(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            status,
            style: GoogleFonts.outfit(
              color: AppColors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
          trailing: isCurrent 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CURRENT',
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.white.withOpacity(0.3)),
          children: days != null ? [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: days),
            )
          ] : [],
        ),
      ),
    );
  }

  Widget _buildDayItem(String day, String type, bool isCompleted, {bool isCurrent = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withOpacity(0.05) : AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary.withOpacity(0.2) : AppColors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(0.1) : (isCurrent ? AppColors.primary.withOpacity(0.1) : AppColors.white.withOpacity(0.05)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : (isCurrent ? Icons.play_arrow_rounded : Icons.calendar_today_rounded),
              color: isCompleted ? Colors.green : (isCurrent ? AppColors.primary : AppColors.white.withOpacity(0.3)),
              size: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: GoogleFonts.outfit(
                    color: AppColors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
        ],
      ),
    );
  }
}
