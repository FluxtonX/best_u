import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

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
                'Progress',
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your transformation',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              
              // Summary Row
              const Row(
                children: [
                  SummaryCard(
                    title: 'Total Workouts',
                    value: '14',
                    icon: Icons.fitness_center_rounded,
                  ),
                  SizedBox(width: 12),
                  SummaryCard(
                    title: 'Weight Lost',
                    value: '2.5 kg',
                    icon: Icons.trending_down_rounded,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  SummaryCard(
                    title: 'Personal Bests',
                    value: '12',
                    icon: Icons.emoji_events_rounded,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Weight Progress Chart (Simplified Visual)
              _buildChartSection(
                title: 'Weight Progress',
                subtitle: '-2.5 kg',
                child: Container(
                  height: 150,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: CustomPaint(
                    painter: LineChartPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Strength Levels Chart (Simplified Visual)
              _buildChartSection(
                title: 'Strength Levels (kg)',
                child: Container(
                  height: 150,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(40, 'Bench'),
                      _buildBar(60, 'Squat'),
                      _buildBar(30, 'Dead'),
                      _buildBar(55, 'Press'),
                      _buildBar(45, 'Rows'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Personal Best Records
              Text(
                "Personal Best Records",
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecordItem('Bench Press', '65 kg', 'Apr 8, 2024'),
              _buildRecordItem('Barbell Row', '55 kg', 'Apr 5, 2024'),
              _buildRecordItem('Overhead Press', '42.5 kg', 'Apr 2, 2024'),
              _buildRecordItem('Pull-ups', '8 reps', 'Mar 30, 2024'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: heightFactor,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.white.withOpacity(0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(String exercise, String value, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise,
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.white.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.9,
      size.width, size.height * 0.7,
    );

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(0, size.height * 0.2), 4, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 4, pointPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.7), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
