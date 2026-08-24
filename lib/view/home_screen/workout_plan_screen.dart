import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/book_download_button.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  Map<String, dynamic>? _activeProgram;
  double _overallProgress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getActiveProgram();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Determine if any workout was completed TODAY across all weeks
          final programData =
              Map<String, dynamic>.from(data['data'] as Map);
          final today = DateTime.now();
          final todayStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          // Step 1: Check if ANY workout was completed today
          bool anyCompletedToday = false;
          for (final week in (programData['weeks'] as List)) {
            for (final day in ((week as Map)['days'] as List)) {
              final completedAtRaw = (day as Map)['completedAt']?.toString();
              if (completedAtRaw != null) {
                final completedAt = DateTime.tryParse(completedAtRaw);
                if (completedAt != null) {
                  final completedStr =
                      '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';
                  if (completedStr == todayStr) {
                    anyCompletedToday = true;
                    break;
                  }
                }
              }
            }
            if (anyCompletedToday) break;
          }

          // Step 2: Mark ONLY the next pending (not yet completed) day as locked.
          // Already-completed days are NEVER locked — just show their checkmark.
          final weeks = (programData['weeks'] as List).map((week) {
            final mappedWeek = Map<String, dynamic>.from(week as Map);
            final days = (mappedWeek['days'] as List).map((day) {
              final mappedDay = Map<String, dynamic>.from(day as Map);
              final isCompleted = mappedDay['isCompleted'] == true;
              final isCurrent = mappedDay['isCurrent'] == true;
              // Lock only the current (next pending) day, not completed ones
              final isLockedToday =
                  anyCompletedToday && !isCompleted && isCurrent;
              return {...mappedDay, 'isLockedToday': isLockedToday};
            }).toList();
            return {...mappedWeek, 'days': days};
          }).toList();
          programData['weeks'] = weeks;

          setState(() {
            _activeProgram = programData;
            _overallProgress =
                (data['data']['progressPercentage'] ?? 0) / 100.0;
            _isLoading = false;
          });
          return;
        }
      }

      await _useLocalPlanData();
    } catch (e) {
      debugPrint("Error fetching program data: $e");
      await _useLocalPlanData();
    }
  }

  Future<void> _useLocalPlanData() async {
    final localProgram = await LocalWorkoutPlanService().loadActiveProgram();
    if (!mounted) return;

    setState(() {
      _overallProgress = 0.0;
      _activeProgram = localProgram;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String programTitle = _isLoading
        ? 'Best-U 8-Week Transformation'
        : (_activeProgram?['programName'] ?? 'Your Program');
        
    final double overallProgress = _isLoading ? 0.35 : _overallProgress;
    final completedCount = _isLoading ? 8 : (_activeProgram?['completedCount'] ?? 0);
    final totalWorkouts = _isLoading ? 24 : (_activeProgram?['totalWorkouts'] ?? 0);
    
    final List<dynamic> weeks = _isLoading
        ? List.generate(4, (index) => {
            'weekNum': index + 1,
            'status': '0/3 workouts',
            'isCompleted': index == 0,
            'isCurrent': index == 1,
            'isLocked': index > 1,
            'days': [
              {'title': 'Day 1 - Chest & Triceps', 'type': 'Strength', 'isCompleted': index == 0, 'isCurrent': index == 1, 'workoutId': 'dummy'},
              {'title': 'Day 2 - Back & Biceps', 'type': 'Strength', 'isCompleted': false, 'isCurrent': false, 'workoutId': 'dummy'},
              {'title': 'Day 3 - Legs & Shoulders', 'type': 'Strength', 'isCompleted': false, 'isCurrent': false, 'workoutId': 'dummy'},
            ]
          })
        : (_activeProgram?['weeks'] ?? []);

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
            onRefresh: _fetchData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Text(
                  programTitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white,
                    fontSize: 28,
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
                          Text(
                            '${(overallProgress * 100).toInt()}%',
                            style: const TextStyle(
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
                          value: overallProgress,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$completedCount of $totalWorkouts workouts completed',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Book Download Banner
                const BookDownloadButton(),
                const SizedBox(height: 32),

                // Weeks List
                if (weeks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'No weeks data available yet',
                        style:
                            TextStyle(color: AppColors.white.withOpacity(0.5)),
                      ),
                    ),
                  )
                else
                  ...weeks.map((week) => _buildWeekItem(
                        weekNumber: week['weekNum'] ?? 0,
                        status: week['status'] ?? '',
                        isCompleted: week['isCompleted'] ?? false,
                        isCurrent: week['isCurrent'] ?? false,
                        isLocked: week['isLocked'] ?? false,
                        isExpanded: week['isCurrent'] ?? false,
                        days: week['days'] != null
                            ? (week['days'] as List)
                                .map((day) => _buildDayItem(
                                      context,
                                      day['title'] ?? 'Day',
                                      day['type'] ?? 'Base',
                                      day['isCompleted'] ?? false,
                                      workoutId: day['workoutId'],
                                      isCurrent: day['isCurrent'] ?? false,
                                      isLockedToday:
                                          day['isLockedToday'] ?? false,
                                    ))
                                .toList()
                            : null,
                      )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ));
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
      child: IgnorePointer(
        ignoring: isLocked,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }

  Widget _buildDayItem(
      BuildContext context, String day, String type, bool isCompleted,
      {required String? workoutId,
      bool isCurrent = false,
      bool isLockedToday = false}) {
    final bool isFutureLocked = !isCompleted && !isCurrent;
    // Completed days are ALWAYS clickable for review.
    // Locked-today (next pending day, already trained today) shows a soft message.
    // Only truly future-locked days (beyond the current week) block navigation.
    final bool isClickable = isCompleted || isCurrent || isLockedToday;

    Color iconBgColor;
    Widget iconWidget;

    if (isCompleted) {
      iconBgColor = Colors.green.withOpacity(0.15);
      iconWidget = const Icon(Icons.check_rounded, color: Colors.green, size: 16);
    } else if (isLockedToday) {
      iconBgColor = Colors.white.withOpacity(0.05);
      iconWidget = Icon(Icons.lock_clock_rounded, color: AppColors.primary.withOpacity(0.5), size: 16);
    } else if (isFutureLocked) {
      iconBgColor = Colors.white.withOpacity(0.02);
      iconWidget = Icon(Icons.lock_outline_rounded, color: AppColors.white.withOpacity(0.15), size: 16);
    } else {
      // Active / Current
      iconBgColor = Colors.white.withOpacity(0.05);
      iconWidget = const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 16);
    }

    String subtitleText = type;
    Color titleColor = AppColors.white;
    Color subtitleColor = AppColors.white.withOpacity(0.4);

    if (isLockedToday) {
      subtitleText = 'Come back tomorrow 💪';
      titleColor = AppColors.white.withOpacity(0.7);
      subtitleColor = AppColors.primary.withOpacity(0.6);
    } else if (isFutureLocked) {
      titleColor = AppColors.white.withOpacity(0.3);
      subtitleColor = AppColors.white.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: !isClickable
          ? null
          : () {
              // Soft informational message for locked-today days, but still
              // allow navigation so the client can review/test the workout.
              if (isLockedToday) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '💪 Great work today! Come back tomorrow for your next session.',
                      style: TextStyle(fontFamily: 'Outfit'),
                    ),
                    backgroundColor: const Color(0xFF1A1A1A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              if (workoutId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WorkoutListScreen(workoutId: workoutId)),
                ).then((_) => _fetchData());
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const WorkoutListScreen(workoutId: 'demo_id')),
                ).then((_) => _fetchData());
              }
            },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent && !isLockedToday
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white.withOpacity(0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent && !isLockedToday)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
