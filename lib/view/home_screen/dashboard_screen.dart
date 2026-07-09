import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
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

      // Step 1: Fetch dashboard summary from Firebase/local program data.
      final response = await apiService.getDashboardSummary();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _summary = data;

            // FALLBACK: If no active program is found in DB, show Week 1 Skeleton
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

      // Step 2: Load Random Quote from Assets (Kept as per your design preference)
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
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();

    // When loading, use dummy data so Skeletonizer has contents to skeletonize.
    final name =
        _isLoading ? 'John Doe' : (_summary?['user']?['name'] ?? 'User');

    final activeProgram = _isLoading
        ? {
            'currentWeek': 1,
            'totalWeeks': 8,
          }
        : _summary?['activeProgram'];

    final todayWorkout = _isLoading
        ? {
            'name': 'Upper Body Strength Routine',
            'exercisesCount': 6,
            'durationMinutes': 45,
            'id': 'loading_workout',
          }
        : _summary?['todayWorkout'];

    final streak = _isLoading ? 5 : (_summary?['weekStats']?['weeklyStreak'] ?? 0);
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
            'quote':
                'This is a motivational quote placeholder that will fade out.',
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      '$greeting,\n$name',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to crush your workout?',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Current Week Card
                    if (activeProgram != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                            width: 1,
                          ),
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Week ${activeProgram['currentWeek']}/${activeProgram['totalWeeks']}',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (activeProgram['currentWeek'] /
                                    activeProgram['totalWeeks']),
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${activeProgram['totalWeeks'] - activeProgram['currentWeek']} weeks remaining',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primary.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Today's Workout Section
                    if (todayWorkout != null) ...[
                      const Text(
                        "Today's Workout",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TODAY',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        todayWorkout['name'] ?? 'Workout',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          color: AppColors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/workout.svg',
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${todayWorkout['exercisesCount']} exercises',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: AppColors.primary
                                                  .withOpacity(0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${todayWorkout['durationMinutes']} min',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: AppColors.primary
                                                  .withOpacity(0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/icons/workout.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            AppBounceAnimation(
                              onTap: isDayLocked
                                  ? null
                                  : () {
                                      final workoutId =
                                          todayWorkout['id'] ?? 'demo_id';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                WorkoutListScreen(
                                                    workoutId:
                                                        workoutId.toString())),
                                      ).then((_) => _fetchDashboardData()); // REFRESH
                                    },
                              child: isDayLocked
                                  ? Container(
                                      width: double.infinity,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.08),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            color: AppColors.primary
                                                .withOpacity(0.5),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Day $nextDay available tomorrow',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: AppColors.white
                                                      .withOpacity(0.5),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Great job today! Rest up 💪',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: AppColors.primary
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
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
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.35),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'START WORKOUT',
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: Colors.black,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(Icons.chevron_right_rounded,
                                              color: Colors.black, size: 20),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // This Week Stats
                    const Text(
                      "This Week",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      title: 'Week Progress',
                      value: '$completedThisWeek/$totalThisWeek days',
                      svgPath: 'assets/icons/week_progress.svg',
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Weekly Streak',
                      value: '$streak weeks',
                      svgPath: 'assets/icons/weekly_streak.svg',
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Weight Progress',
                      value: weightProgress == 0.0
                          ? '0 kg'
                          : '${weightProgress > 0 ? "+" : ""}${weightProgress.toStringAsFixed(1)} kg',
                      svgPath: 'assets/icons/weight_progres.svg',
                    ),
                    const SizedBox(height: 32),

                    // Quote Container
                    if (quote != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: const Border(
                            left:
                                BorderSide(color: AppColors.primary, width: 4),
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
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '— ${quote['author'] ?? "Stay consistent"}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primary.withOpacity(0.8),
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
          ),
        ));
  }
}

Widget _buildStatCard({
  required String title,
  required String value,
  required String svgPath,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
