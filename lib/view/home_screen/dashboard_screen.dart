import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.outfit(
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Good morning,\nRahmat',
                        style: GoogleFonts.outfit(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to crush your workout?',
                        style: GoogleFonts.outfit(
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.white.withOpacity(0.05)),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Week Info Card
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'CURRENT WEEK',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Week 2/8',
                              style: GoogleFonts.outfit(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Missing line/progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.25,
                        minHeight: 6,
                        backgroundColor: AppColors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '6 weeks remaining',
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

              // Today's Workout
              Text(
                "Today's Workout",
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF141414),
                      Color(0xFF141414),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A2FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAY 2',
                              style: GoogleFonts.outfit(
                                color: AppColors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upper Body Strength',
                              style: GoogleFonts.outfit(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fitness_center_rounded,
                              color: AppColors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '6 exercises • 45 min',
                          style: GoogleFonts.outfit(
                              color: AppColors.white, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A2FF),
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'START WORKOUT',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // This Week Stats
              Text(
                "This Week",
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Changed to Column for vertical list
              _buildStatItem(
                title: 'Week Progress',
                value: '3/3 days',
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                title: 'Weekly Streak',
                value: '5 weeks',
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                title: 'Weight Progress',
                value: '-2.5 kg',
                icon: Icons.monitor_weight_outlined,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 40),

              // Quote Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.darkGrey,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"The only bad workout is the one that\ndidn\'t happen."',
                      style: GoogleFonts.outfit(
                        color: AppColors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '— Stay focused!',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
