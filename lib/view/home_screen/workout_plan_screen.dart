import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';

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
          setState(() {
            _activeProgram = data['data'];
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final String programTitle =
        _activeProgram?['programName'] ?? 'Your Program';
    final List<dynamic> weeks = _activeProgram?['weeks'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                            '${(_overallProgress * 100).toInt()}%',
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
                          value: _overallProgress,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_activeProgram?['completedCount'] ?? 0} of ${_activeProgram?['totalWorkouts'] ?? 0} workouts completed',
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
    );
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
      {required String? workoutId, bool isCurrent = false}) {
    return GestureDetector(
      onTap: () {
        if (workoutId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WorkoutListScreen(workoutId: workoutId)),
          ).then((_) => _fetchData()); // Refresh when returning
        } else {
          // Demo/Mock navigation
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
            color: isCurrent
                ? AppColors.primary.withOpacity(0.3)
                : Colors.white.withOpacity(0.03),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: isCompleted ? Colors.green : AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
