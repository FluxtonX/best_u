import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'track your transformation',
                style: GoogleFonts.outfit(
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                color: AppColors.white.withOpacity(0.1),
                thickness: 1,
              ),
              const SizedBox(height: 32),

              // Summary Section (Vertical KPI Cards)
              Column(
                children: [
                  _buildSummaryCard(
                    title: 'Total Workouts',
                    value: '14',
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: 'Weight Lost',
                    value: '2.5 kg',
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    title: 'Personal Bests',
                    value: '12',
                    icon: Icons.emoji_events_rounded,
                    svgPath: 'assets/icons/personal_best_icon.svg',
                    iconColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Filter Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFilterTab('Week', false),
                    _buildFilterTab('Month', true),
                    _buildFilterTab('All Time', false),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Weight Progress Chart
              _buildChartSection(
                title: 'Weight Progress',
                subtitle: '-2.5 kg',
                subtitleColor: const Color(0xFF22C55E),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  child: Image.asset(
                    'assets/images/weight_chart_mock.png', // Placeholder or CustomPaint
                    errorBuilder: (context, error, stackTrace) =>
                        CustomPaint(painter: LineChartPainter()),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Strength Levels Chart
              _buildChartSection(
                title: 'Strength Levels (kg)',
                child: Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(60, 'Bench', AppColors.primary),
                      _buildBar(50, 'Row', AppColors.primary),
                      _buildBar(40, 'Press', AppColors.primary),
                      _buildBar(80, 'Squat', AppColors.primary),
                      _buildBar(100, 'Deadlift', AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Weekly Workouts Chart
              _buildChartSection(
                title: 'Weekly Workouts',
                child: Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(70, 'W1', Colors.orange),
                      _buildBar(70, 'W2', Colors.orange),
                      _buildBar(50, 'W3', Colors.orange),
                      _buildBar(70, 'W4', Colors.orange),
                      _buildBar(68, 'W5', Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Personal Best Records Section
              Container(
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
                      children: [
                        SvgPicture.asset(
                          'assets/icons/build muscle icon.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              AppColors.primary, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Personal Best Records",
                          style: GoogleFonts.outfit(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildRecordRow('Bench Press', '65 kg', 'Apr 6, 2024'),
                    _buildRecordRow('Barbell Row', '55 kg', 'Apr 5, 2024'),
                    _buildRecordRow('Overhead Press', '42.5 kg', 'Apr 3, 2024'),
                    _buildRecordRow('Pull-ups', '8 reps', 'Apr 2, 2024',
                        showDivider: false),
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    String? svgPath,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
            ),
            child: svgPath != null
                ? SvgPicture.asset(
                    svgPath,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  )
                : Icon(icon, color: iconColor, size: 22),
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
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color:
                isSelected ? AppColors.white : AppColors.white.withOpacity(0.4),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required Widget child,
  }) {
    return Container(
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: subtitleColor ?? AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 38,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
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

  Widget _buildRecordRow(String title, String value, String date,
      {bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: GoogleFonts.outfit(
                      color: AppColors.white.withOpacity(0.3),
                      fontSize: 11,
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
        ),
        if (showDivider)
          Divider(
            color: AppColors.white.withOpacity(0.05),
            thickness: 1,
            height: 1,
          ),
      ],
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
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.7,
    );

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()..color = Colors.green;
    canvas.drawCircle(Offset(0, size.height * 0.2), 4, pointPaint);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 4, pointPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.7), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
