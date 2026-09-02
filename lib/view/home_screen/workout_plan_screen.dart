import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/book_download_button.dart';
import 'package:best_u/view/widgets/pro_access_modal.dart';
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
  String _strengthLevel = 'beginner'; // 'beginner' | 'advanced'

  @override
  void initState() {
    super.initState();
    _initPlan();
  }

  Future<void> _initPlan() async {
    await _loadStrengthLevel();
    await _fetchData();
  }

  Future<void> _loadStrengthLevel() async {
    try {
      final res = await ApiService().getStrengthLevel();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          final level = data['data']?['strengthLevel'] ?? 'beginner';
          setState(() => _strengthLevel = level);
        }
      }
    } catch (_) {}
  }

  Future<void> _setStrengthLevel(String level) async {
    if (_strengthLevel == level) return;
    setState(() {
      _strengthLevel = level;
      _isLoading = true;
    });
    await ApiService().setStrengthLevel(level);
    await _fetchData(level: level);
  }

  Future<void> _fetchData({String? level}) async {
    final effectiveLevel = level ?? _strengthLevel;
    try {
      final apiService = ApiService();
      final response = await apiService.getActiveProgram(level: effectiveLevel);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Determine if any workout was completed TODAY across all weeks
          final programData = Map<String, dynamic>.from(data['data'] as Map);
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

          // Step 2: Mark if the current session is on a rest-recommended day (already trained today)
          final weeks = (programData['weeks'] as List).map((week) {
            final mappedWeek = Map<String, dynamic>.from(week as Map);
            final days = (mappedWeek['days'] as List).map((day) {
              final mappedDay = Map<String, dynamic>.from(day as Map);
              final isCompleted = mappedDay['isCompleted'] == true;
              final isCurrent = mappedDay['isCurrent'] == true;
              final isRestRecommended =
                  anyCompletedToday && !isCompleted && isCurrent;
              return {
                ...mappedDay,
                'isRestRecommended': isRestRecommended,
                'isLockedToday': isRestRecommended,
              };
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

      await _useLocalPlanData(level: effectiveLevel);
    } catch (e) {
      debugPrint("Error fetching program data: $e");
      await _useLocalPlanData(level: effectiveLevel);
    }
  }

  Future<void> _useLocalPlanData({String? level}) async {
    final effectiveLevel = level ?? _strengthLevel;
    final localProgram = await LocalWorkoutPlanService()
        .loadActiveProgram(level: effectiveLevel);
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
    final completedCount =
        _isLoading ? 8 : (_activeProgram?['completedCount'] ?? 0);
    final totalWorkouts =
        _isLoading ? 24 : (_activeProgram?['totalWorkouts'] ?? 0);

    final List<dynamic> weeks = _isLoading
        ? List.generate(
            4,
            (index) => {
                  'weekNum': index + 1,
                  'status': '0/3 workouts',
                  'isCompleted': index == 0,
                  'isCurrent': index == 1,
                  'isLocked': index > 1,
                  'days': [
                    {
                      'title': 'Day 1 - Chest & Triceps',
                      'type': 'Strength',
                      'isCompleted': index == 0,
                      'isCurrent': index == 1,
                      'workoutId': 'dummy'
                    },
                    {
                      'title': 'Day 2 - Back & Biceps',
                      'type': 'Strength',
                      'isCompleted': false,
                      'isCurrent': false,
                      'workoutId': 'dummy'
                    },
                    {
                      'title': 'Day 3 - Legs & Shoulders',
                      'type': 'Strength',
                      'isCompleted': false,
                      'isCurrent': false,
                      'workoutId': 'dummy'
                    },
                  ]
                })
        : (_activeProgram?['weeks'] ?? []);

    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Skeletonizer(
            enabled: _isLoading,
            effect: ShimmerEffect(
              baseColor: Colors.white.withValues(alpha: 0.04),
              highlightColor: Colors.white.withValues(alpha: 0.12),
              duration: const Duration(milliseconds: 1000),
            ),
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        color: AppColors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Beginner / Advanced toggle ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          _levelTab('🏃 Beginner', 'beginner'),
                          _levelTab('💪 Advanced', 'advanced'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Active Level Focus Badge
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _strengthLevel == 'advanced'
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _strengthLevel == 'advanced' ? '🏋️' : '🏃',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _strengthLevel == 'advanced'
                                      ? 'Advanced Weights Plan (8 Weeks)'
                                      : 'Beginner Bodyweight Plan (8 Weeks)',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _strengthLevel == 'advanced'
                                      ? 'Chest/Bicep • Shoulder/Tris • Legs/Back • 6 reps = +5kg overload'
                                      : 'Foundation bodyweight conditioning & strength test loop',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color:
                                        AppColors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Overall Progress Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05)),
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
                                  color: AppColors.white.withValues(alpha: 0.5),
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
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
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
                              color: AppColors.white.withValues(alpha: 0.4),
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
                            style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.5)),
                          ),
                        ),
                      )
                    else
                      ...weeks.map((week) => _buildWeekItem(
                            weekNumber: week['weekNum'] ?? 0,
                            status: week['status'] ?? '',
                            focus: week['focus'] ?? '',
                            isCompleted: week['isCompleted'] ?? false,
                            isCurrent: week['isCurrent'] ?? false,
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
                                          isRestRecommended:
                                              day['isRestRecommended'] ?? false,
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
    String focus = '',
    bool isCompleted = false,
    bool isCurrent = false,
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
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
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
                ? Colors.green.withValues(alpha: 0.12)
                : isCurrent
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : (isCurrent
                    ? Icons.fitness_center_rounded
                    : Icons.calendar_today_rounded),
            color: isCompleted
                ? Colors.green
                : (isCurrent
                    ? AppColors.primary
                    : AppColors.white.withValues(alpha: 0.4)),
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Week $weekNumber',
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (focus.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    focus,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              status,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CURRENT WEEK',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ] else if (isCompleted) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 22,
        ),
        children: days != null
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(children: days),
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildDayItem(
      BuildContext context, String day, String type, bool isCompleted,
      {required String? workoutId,
      bool isCurrent = false,
      bool isRestRecommended = false}) {
    Color iconBgColor;
    Widget iconWidget;
    String statusBadgeText = '';

    if (isCompleted) {
      iconBgColor = Colors.green.withValues(alpha: 0.15);
      iconWidget =
          const Icon(Icons.check_rounded, color: Colors.green, size: 16);
      statusBadgeText = 'COMPLETED';
    } else if (isCurrent) {
      iconBgColor = AppColors.primary.withValues(alpha: 0.15);
      iconWidget = const Icon(Icons.play_arrow_rounded,
          color: AppColors.primary, size: 16);
      statusBadgeText = isRestRecommended ? 'REST DAY' : 'UP NEXT';
    } else {
      // Upcoming session
      iconBgColor = Colors.white.withValues(alpha: 0.04);
      iconWidget = Icon(Icons.fitness_center_rounded,
          color: AppColors.white.withValues(alpha: 0.35), size: 15);
      statusBadgeText = 'PREVIEW';
    }

    String subtitleText = type;
    Color titleColor = AppColors.white;
    Color subtitleColor = AppColors.white.withValues(alpha: 0.5);

    if (isRestRecommended) {
      subtitleText = '$type • Rest recommended today 💪';
      subtitleColor = AppColors.primary.withValues(alpha: 0.7);
    } else if (!isCompleted && !isCurrent) {
      subtitleText = '$type • Upcoming session';
    }

    return GestureDetector(
      onTap: () async {
        final hasAccess = await ProAccessModal.checkAccess(
          context,
          featureName: '$day - $type',
        );
        if (!hasAccess || !context.mounted) return;

        if (workoutId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WorkoutListScreen(workoutId: workoutId)),
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
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF1E1C14)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          day,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (statusBadgeText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.12)
                                : isCurrent
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusBadgeText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isCompleted
                                  ? Colors.green
                                  : isCurrent
                                      ? AppColors.primary
                                      : AppColors.white.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isCurrent
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelTab(String label, String value) {
    final selected = _strengthLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setStrengthLevel(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: selected
                    ? Colors.white
                    : AppColors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
