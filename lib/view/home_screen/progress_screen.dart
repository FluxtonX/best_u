import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';

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
              const Text(
                'Progress',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Every rep counts and keeps record',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Top KPI Row
              Row(
                children: [
                  _buildKPICard(
                    label: 'Workout\nMinutes',
                    value: '145',
                    trend: '+14d',
                    icon: Icons.local_fire_department_rounded,
                    iconBg: AppColors.primary.withOpacity(0.2),
                  ),
                  const SizedBox(width: 12),
                  _buildKPICard(
                    label: 'Weight',
                    value: '2.5',
                    unit: 'kg',
                    icon: Icons.trending_up_rounded,
                    iconBg: const Color(0xFF22C55E).withOpacity(0.2),
                    iconColor: const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 12),
                  _buildKPICard(
                    label: 'Protein',
                    value: '12',
                    icon: Icons.fitness_center_rounded,
                    iconBg: const Color(0xFFC6934A).withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Weight Progress Chart
              _buildSectionCard(
                title: 'Weight Progress',
                trailing: const Text('-2.5kg',
                    style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                child: Container(
                  height: 140,
                  padding: const EdgeInsets.only(top: 20),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: WeightLineChartPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Strength Levels Chart
              _buildSectionCard(
                title: 'Strength Levels Up',
                child: Container(
                  height: 170, // Increased height
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStrengthBar(60, 'Mon'),
                      _buildStrengthBar(70, 'Tue'),
                      _buildStrengthBar(80, 'Wed'),
                      _buildStrengthBar(90, 'Thu'),
                      _buildStrengthBar(100, 'Fri'),
                      _buildStrengthBar(110, 'Sat'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Banner 1
              _buildBanner(
                icon: Icons.track_changes_rounded,
                text:
                    "You're on the track up, You've mastered the last 2 workouts",
              ),
              const SizedBox(height: 12),
              // Status Banner 2
              _buildBanner(
                icon: Icons.emoji_events_rounded,
                text: "Strongest lift: Squats - 21 kg this week",
              ),
              const SizedBox(height: 24),

              // Weekly Workouts
              _buildSectionCard(
                title: 'Weekly Workouts',
                trailing: const Text('4/6',
                    style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                child: Container(
                  height: 170, // Increased height to prevent overflow
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildWorkoutBar(60, 'Mon'),
                      _buildWorkoutBar(90, 'Tue'),
                      _buildWorkoutBar(70, 'Wed'),
                      _buildWorkoutBar(80, 'Thu'),
                      _buildWorkoutBar(100, 'Fri'),
                      _buildWorkoutBar(50, 'Sat'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Activity Summary Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Activity Summary',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: 0.85,
                                    strokeWidth: 8,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary),
                                  ),
                                ),
                                const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('85%',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)),
                                    Text('Completed',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 8)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildSmallSummaryCard('2,458', 'Kcal burn',
                            Icons.local_fire_department_rounded),
                        const SizedBox(height: 12),
                        _buildSmallSummaryCard(
                            '70.3 min', 'Avg time', Icons.show_chart_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallSummaryCard(
                        '142 bpm', 'Avg heart rate', Icons.favorite_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallSummaryCard('Adding progress',
                        'this month', Icons.calendar_today_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Personal Best Records
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Personal Best Records",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "View All",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPBItem('Bench Press', 'May 2, 2022', '35.2 kg'),
              _buildPBItem('Squat Row', 'May 12, 2022', '--'),
              _buildPBItem('Overhead Press', 'May 1, 2022', '42.5 kg'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    String? unit,
    String? trend,
    required IconData icon,
    required Color iconBg,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor ?? AppColors.primary, size: 16),
                ),
                if (trend != null)
                  Flexible(
                    child: Text(trend,
                        style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
                if (unit != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(unit,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, Widget? trailing, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              if (trailing != null) trailing,
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildStrengthBar(double height, String label) {
    return Column(
      children: [
        Container(
          width: 42,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWorkoutBar(double height, String label) {
    return Column(
      children: [
        Container(
          width: 42,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B), // More vibrant orange for workouts
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBanner({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(String value, String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPBItem(String title, String date, String weight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white30, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(date,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(weight,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    4,
                    (index) => const Icon(Icons.star_rounded,
                        color: AppColors.primary, size: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeightLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = AppColors.primary;
    final dotOutlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    final List<Offset> points = [
      Offset(0, size.height * 0.4),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.45),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width, size.height * 0.4),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    for (var point in points) {
      canvas.drawCircle(point, 5, dotOutlinePaint);
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Draw days text placeholder
    const textStyle = TextStyle(color: Colors.white24, fontSize: 10);
    final days = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 0; i < days.length; i++) {
      final textSpan = TextSpan(text: days[i], style: textStyle);
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(size.width * 0.2 * (i + 1) - 10, size.height + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
