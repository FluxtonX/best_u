import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/home_screen/nutrition_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _quote;
  List<dynamic> _motivations = [];
  Timer? _quoteTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _startQuoteRotation() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_motivations.isNotEmpty) {
        setState(() {
          final random = Random();
          _quote = _motivations[random.nextInt(_motivations.length)];
        });
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    try {
      final apiService = ApiService();

      final response = await apiService.getDashboardSummary();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _summary = data;
            if (_summary?['activeProgram'] == null) {
              _summary?['activeProgram'] = {
                'name': '8 Week Program',
                'currentWeek': 1,
                'totalWeeks': 8,
              };
            }
            if (_summary?['todayWorkout'] == null) {
              _summary?['todayWorkout'] = {
                'name': 'Upper Body Strength',
                'durationMinutes': 45,
                'exercisesCount': 6,
              };
            }
          });
        }
      }

      final String quoteResponse =
          await rootBundle.loadString('assets/data/motivation.json');
      final quoteData = await json.decode(quoteResponse);
      _motivations = quoteData['motivations'];
      if (_motivations.isNotEmpty) {
        final random = Random();
        _quote = _motivations[random.nextInt(_motivations.length)];
        _startQuoteRotation();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final name =
        _isLoading ? 'John Doe' : (_summary?['user']?['name'] ?? 'User');

    final activeProgram = _isLoading
        ? {'currentWeek': 1, 'totalWeeks': 8}
        : _summary?['activeProgram'];

    final todayWorkout = _isLoading
        ? {
            'name': 'Upper Body Strength Routine',
            'exercisesCount': 6,
            'durationMinutes': 45,
            'id': 'loading_workout',
          }
        : _summary?['todayWorkout'];

    final streak =
        _isLoading ? 5 : (_summary?['weekStats']?['weeklyStreak'] ?? 0);
    final weightProgress =
        _isLoading ? -2.5 : (_summary?['weekStats']?['weightProgress'] ?? 0.0);
    final completedThisWeek =
        _isLoading ? 2 : (_summary?['weekStats']?['completedThisWeek'] ?? 0);
    final totalThisWeek =
        _isLoading ? 3 : (_summary?['weekStats']?['totalThisWeek'] ?? 3);
    final isDayLocked =
        _isLoading ? false : (_summary?['weekStats']?['isDayLocked'] ?? false);
    final nextDay =
        _isLoading ? 1 : (_summary?['weekStats']?['nextDay'] ?? 1);

    final quote = _isLoading
        ? {
            'quote': 'This is a motivational quote placeholder.',
            'author': 'Author Name',
          }
        : _quote;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Skeletonizer(
          enabled: _isLoading,
          effect: ShimmerEffect(
            baseColor: Colors.white.withOpacity(0.04),
            highlightColor: Colors.white.withOpacity(0.12),
            duration: const Duration(milliseconds: 1000),
          ),
          child: RefreshIndicator(
            onRefresh: _fetchDashboardData,
            color: AppColors.primary,
            backgroundColor: const Color(0xFF151515),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.white.withOpacity(0.55),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification / avatar badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Week Progress Card ────────────────────────────────
                  if (activeProgram != null) ...[
                    _buildWeekProgressCard(activeProgram),
                    const SizedBox(height: 14),
                  ],

                  // ── Today's Workout Card ──────────────────────────────
                  if (todayWorkout != null) ...[
                    _buildTodayWorkoutCard(
                      context: context,
                      todayWorkout: todayWorkout,
                      isDayLocked: isDayLocked,
                      nextDay: nextDay,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Nutrition Coach Card ──────────────────────────────
                  _buildNutritionStatusCard(context),
                  const SizedBox(height: 20),

                  // ── This Week Section ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'This Week',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '$completedThisWeek/$totalThisWeek done',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3-column mini stat cards
                  Row(
                    children: [
                      _buildMiniStatCard(
                        label: 'Week',
                        value: '$completedThisWeek/$totalThisWeek',
                        sub: 'days',
                        svgPath: 'assets/icons/week_progress.svg',
                      ),
                      const SizedBox(width: 10),
                      _buildMiniStatCard(
                        label: 'Streak',
                        value: '$streak',
                        sub: 'weeks',
                        svgPath: 'assets/icons/weekly_streak.svg',
                      ),
                      const SizedBox(width: 10),
                      _buildMiniStatCard(
                        label: 'Weight',
                        value: weightProgress == 0.0
                            ? '0 kg'
                            : '${weightProgress > 0 ? "+" : ""}${weightProgress.toStringAsFixed(1)}',
                        sub: 'kg',
                        svgPath: 'assets/icons/weight_progres.svg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Motivational Quote ────────────────────────────────
                  if (quote != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: const Border(
                          left: BorderSide(
                              color: AppColors.primary, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${quote['quote'] ?? "Consistency is key."}"',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.white,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '— ${quote['author'] ?? "Stay consistent"}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary.withOpacity(0.8),
                              fontSize: 12,
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
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEEK PROGRESS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWeekProgressCard(Map<String, dynamic> activeProgram) {
    final current = activeProgram['currentWeek'] as int? ?? 1;
    final total = activeProgram['totalWeeks'] as int? ?? 8;
    final progress = current / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CURRENT WEEK',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Week $current / $total',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${total - current} weeks remaining',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TODAY'S WORKOUT CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTodayWorkoutCard({
    required BuildContext context,
    required Map<String, dynamic> todayWorkout,
    required bool isDayLocked,
    required int nextDay,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  'assets/icons/workout.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            todayWorkout['name'] ?? 'Workout',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _workoutChip(
                  '${todayWorkout['exercisesCount']} exercises', Icons.fitness_center_rounded),
              const SizedBox(width: 10),
              _workoutChip(
                  '${todayWorkout['durationMinutes']} min', Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 18),
          AppBounceAnimation(
            onTap: (_isLoading || isDayLocked)
                ? null
                : () {
                    final workoutId = todayWorkout['id'] ?? 'demo_id';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WorkoutListScreen(
                              workoutId: workoutId.toString())),
                    ).then((_) => _fetchDashboardData());
                  },
            child: isDayLocked
                ? Container(
                    width: double.infinity,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: AppColors.primary.withOpacity(0.5),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day $nextDay available tomorrow',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Great job today! Rest up 💪',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primary.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Today',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.black, size: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _workoutChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NUTRITION STATUS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNutritionStatusCard(BuildContext context) {
    // Simple computed fast progress
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.add(const Duration(hours: 8));
    final end = today.add(const Duration(hours: 14));
    double progress;
    if (now.isBefore(start)) {
      progress = 0.0;
    } else if (now.isAfter(end)) {
      progress = 1.0;
    } else {
      progress =
          (now.difference(start).inSeconds / end.difference(start).inSeconds)
              .clamp(0.0, 1.0);
    }
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NUTRITION COACH',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Morning Fast',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.white.withOpacity(0.5),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '8 AM → 2 PM',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'done',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.white.withOpacity(0.55),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Timer + label
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: '5h 18m',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '  Completed so far',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Goal: Reach 2 PM',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Button
          AppBounceAnimation(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Nutrition',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.black, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MINI STAT CARD (3-col)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required String sub,
    required String svgPath,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width: 16,
                  height: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
