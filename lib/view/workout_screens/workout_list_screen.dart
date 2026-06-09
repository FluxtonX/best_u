import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/workout_screens/exercise_session_screen.dart';
import 'package:flutter/material.dart';

class WorkoutListScreen extends StatefulWidget {
  final String? workoutId;
  const WorkoutListScreen({super.key, this.workoutId});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  Map<String, dynamic>? _workout;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutDetails();
  }

  Future<void> _fetchWorkoutDetails() async {
    if (widget.workoutId != null && widget.workoutId!.startsWith('local_')) {
      final localWorkout =
          await LocalWorkoutPlanService().loadWorkout(widget.workoutId!);
      if (localWorkout != null && mounted) {
        setState(() {
          _workout = localWorkout;
          _isLoading = false;
        });
        return;
      }
    }

    // Check if it needs to fetch persisted workout data.
    if (widget.workoutId != null && widget.workoutId != 'demo_id') {
      try {
        final apiService = ApiService();
        final response = await apiService.getWorkoutDetails(widget.workoutId!);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final workout = Map<String, dynamic>.from(data['data']);
            workout['exercises'] = _withLocalExerciseVideos(
              workout['exercises'] as List? ?? [],
            );
            setState(() {
              _workout = workout;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint("Error fetching workout: $e");
      }
    }

    final fallbackWorkout =
        await LocalWorkoutPlanService().loadWorkout('local_w1_d1');
    if (fallbackWorkout != null && mounted) {
      setState(() {
        _workout = fallbackWorkout;
        _isLoading = false;
      });
      return;
    }

    // DISCONNECTED FROM BACKEND FOR PERFECT UI TESTING OR DEMO
    setState(() {
      _workout = {
        'title': 'Chest / Bicep',
        'name': 'Chest / Bicep',
        'estimatedDurationMinutes': 29,
        'durationMinutes': 29,
        'day': 1,
        'totalSets': 6,
        'exercises': [
          {
            'name': 'Press Up',
            'sets': 2,
            'reps': '1-10, 1-6',
            'type': 'Chest',
            'previousReps': 1,
            'targetReps': 10,
            'hasWeightTarget': false,
          },
          {
            'name': 'Bicep Curl',
            'sets': 2,
            'reps': '10, 3-6',
            'type': 'Arms',
            'previousWeight': 6.0,
            'targetWeight': 18.0,
            'targetReps': 10,
            'hasWeightTarget': true,
          },
          {
            'name': 'Sit Ups',
            'sets': 2,
            'reps': '1-10, 1-6',
            'type': 'Core',
            'previousReps': 1,
            'targetReps': 10,
            'hasWeightTarget': false,
          },
        ]
      };
      _workout!['exercises'] = _withLocalExerciseVideos(
        _workout!['exercises'] as List? ?? [],
      );
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _withLocalExerciseVideos(List<dynamic> exercises) {
    final localPlanService = LocalWorkoutPlanService();
    return exercises
        .whereType<Map>()
        .map((exercise) => localPlanService.attachLocalVideo(
              Map<String, dynamic>.from(exercise),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final List<dynamic> exercises = _workout?['exercises'] ?? [];
    final String workoutName =
        _workout?['name'] ?? _workout?['title'] ?? 'Workout';
    final String dayInfo =
        _workout?['day'] != null ? 'DAY ${_workout!['day']}' : 'TODAY';
    final int durationMinutes = _workout?['durationMinutes'] ??
        _workout?['estimatedDurationMinutes'] ??
        0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              dayInfo,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              workoutName,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Top Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryStat('${exercises.length}', 'Exercises'),
                        _buildVerticalDivider(),
                        _buildSummaryStat('$durationMinutes', 'Minutes'),
                        _buildVerticalDivider(),
                        _buildSummaryStat(
                            '${_getTotalSets(exercises)}', 'Total Sets'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Focus Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Today's Focus",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _workout?['description'] ??
                              "Focus on controlled movements and proper form. Rest between sets as needed. Try to match or exceed your previous performance.",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Exercise Breakdown",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Exercise List
                  ...exercises.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final dynamic exercise = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise['name'],
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildSetPreview(exercise),
                                if (exercise['previousWeight'] != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'Previous: ${exercise['previousWeight']} kg',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppBounceAnimation(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExerciseSessionScreen(
                            exercises: exercises,
                            workoutId: widget.workoutId ?? 'mock_workout_id',
                          )),
                );
              },
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'START WORKOUT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.black, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSets(List<dynamic> exercises) {
    int total = 0;
    for (var e in exercises) {
      total += (e['sets'] as int? ?? 0);
    }
    return total;
  }

  String _exercisePrescription(dynamic exercise) {
    final sets = exercise['sets'] as int? ?? 0;
    final reps = exercise['reps']?.toString();
    if (reps != null && reps.isNotEmpty && reps != 'See instructions') {
      return '$sets sets x $reps';
    }

    final duration = exercise['durationSeconds']?.toString();
    if (duration != null && duration.isNotEmpty) {
      return '$sets sets x $duration sec';
    }

    return '$sets sets';
  }

  List<Map<String, dynamic>> _setDetails(dynamic exercise) {
    final details = exercise is Map ? exercise['setDetails'] : null;
    if (details is List && details.isNotEmpty) {
      return details
          .whereType<Map>()
          .map((set) => Map<String, dynamic>.from(set))
          .toList();
    }

    final instructions = exercise is Map ? exercise['setInstructions'] : null;
    if (instructions is List && instructions.isNotEmpty) {
      return instructions.asMap().entries.map((entry) {
        return {
          'set': entry.key + 1,
          'instruction': entry.value?.toString() ?? '',
        };
      }).toList();
    }

    return [
      {
        'set': 1,
        'instruction': _exercisePrescription(exercise),
      }
    ];
  }

  Widget _buildSetPreview(dynamic exercise) {
    final sets = _setDetails(exercise);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sets.map((set) {
        final setNumber = set['set']?.toString() ?? '';
        final instruction = set['instruction']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set $setNumber',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}
