// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/models/fasting_session.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/nutrition_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:best_u/view/home_screen/main_home_screen.dart';
import 'package:best_u/view/home_screen/nutrition_screen.dart';
import 'package:best_u/view/home_screen/notification_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NutritionRepository _nutritionRepo = NutritionRepository();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  Map<String, dynamic>? _quote;
  List<dynamic> _motivations = [];
  Timer? _quoteTimer;
  List<FastingSession> _todaySessions = [];

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
      if (_motivations.isNotEmpty && mounted) {
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
      try {
        _todaySessions = await _nutritionRepo.getTodaySessions();
      } catch (_) {}

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
    final nextDay = _isLoading ? 1 : (_summary?['weekStats']?['nextDay'] ?? 1);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      AppBounceAnimation(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen()),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: ApiService().getNotificationsStream(),
                            builder: (context, snapshot) {
                              bool hasUnread = false;
                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  if (data['isRead'] == false) {
                                    hasUnread = true;
                                    break;
                                  }
                                }
                              }
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
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
                          left: BorderSide(color: AppColors.primary, width: 3),
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
                  // ── BestU Website Link ──────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('https://bestu.health/');
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131313),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BestU Health Website',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'bestu.health',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color:
                                        AppColors.primary.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: AppColors.white.withOpacity(0.3),
                            size: 16,
                          ),
                        ],
                      ),
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
              _workoutChip('${todayWorkout['exercisesCount']} exercises',
                  Icons.fitness_center_rounded),
              const SizedBox(width: 10),
              _workoutChip('${todayWorkout['durationMinutes']} min',
                  Icons.timer_outlined),
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
    return StreamBuilder<FastingSession?>(
      stream: _nutritionRepo.sessionStream,
      builder: (context, snapshot) {
        var session = snapshot.data;
        if (session == null && _todaySessions.isNotEmpty) {
          session = _todaySessions.last;
        }
        final now = DateTime.now();

        double progress = 0.0;
        int percent = 0;
        String timerText = '0h 00m';
        String timerLabel = 'Not started yet';
        String goalText = 'Goal: Reach 12 PM';
        String timeRangeText = '8 AM → 12 PM';
        String btnText = 'Start Nutrition';

        if (session != null) {
          final level = session.level;
          if (level == 1) {
            goalText = 'Goal: Reach 2 PM';
            timeRangeText = '8 AM → 2 PM';
          } else if (level == 2) {
            goalText = 'Goal: Reach 4 PM';
            timeRangeText = '8 AM → 4 PM';
          } else {
            goalText = 'Goal: Reach 12 PM';
            timeRangeText = '8 AM → 12 PM';
          }

          if (session.status == 'completed' || session.dayComplete) {
            if (level == 0) {
              progress = 0.50;
              percent = 50;
              timerLabel = 'Beginner Fast Completed';
              goalText = 'Beginner Reached (12 PM) 🏆';
            } else if (level == 1) {
              progress = 0.75;
              percent = 75;
              timerLabel = 'Intermediate Fast Completed';
              goalText = 'Intermediate Reached (2 PM) 🏆';
            } else {
              progress = 1.0;
              percent = 100;
              timerLabel = 'Elite Fast Completed';
              goalText = 'Elite Reached (4 PM) 👑';
            }
            final end = session.endedAt ?? session.endsAt ?? now;
            final diff = end.difference(session.startedAt);
            final h = diff.inHours;
            final m = diff.inMinutes.remainder(60);
            timerText = '${h}h ${m.toString().padLeft(2, '0')}m';
            btnText = 'View Nutrition';
          } else {
            final start = session.startedAt;
            final end = session.endsAt ?? now.add(const Duration(hours: 4));
            if (now.isAfter(start)) {
              final elapsed = now.difference(start);
              final h = elapsed.inHours;
              final m = elapsed.inMinutes.remainder(60);
              timerText = '${h}h ${m.toString().padLeft(2, '0')}m';
              timerLabel = 'Completed so far';
            }

            final totalSeconds = end.difference(start).inSeconds;
            double elapsedProgress = 0.0;
            if (totalSeconds > 0) {
              elapsedProgress = (now.difference(start).inSeconds / totalSeconds)
                  .clamp(0.0, 1.0);
            }
            if (level == 0) {
              progress = elapsedProgress * 0.50;
              percent = (elapsedProgress * 50).round();
            } else if (level == 1) {
              progress = 0.50 + (elapsedProgress * 0.25);
              percent = (50 + (elapsedProgress * 25)).round();
            } else {
              progress = 0.75 + (elapsedProgress * 0.25);
              percent = (75 + (elapsedProgress * 25)).round();
            }
            btnText = 'Continue Nutrition';
          }
        }

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
                              timeRangeText,
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
                            backgroundColor:
                                AppColors.primary.withOpacity(0.12),
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
                    TextSpan(
                      text: timerText,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '  $timerLabel',
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
                child: Text(
                  goalText,
                  style: const TextStyle(
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
                  // Switch bottom-nav to Nutrition tab if possible, else push
                  final mainState = MainHomeScreen.mainKey.currentState;
                  if (mainState != null) {
                    mainState.switchToNutrition();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NutritionScreen()),
                    );
                  }
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        btnText,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
