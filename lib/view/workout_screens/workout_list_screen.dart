import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/pro_access_modal.dart';
import 'package:best_u/view/workout_screens/exercise_session_screen.dart';
import 'package:flutter/material.dart';

class WorkoutListScreen extends StatefulWidget {
  final String? workoutId;
  const WorkoutListScreen({super.key, this.workoutId});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _workout;
  bool _isLoading = true;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _statsCtrl;
  late final AnimationController _focusCtrl;
  late final AnimationController _labelCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _buttonCtrl;
  late final AnimationController _buttonGlowCtrl;
  late final AnimationController _countCtrl;

  // Header
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // Stats card
  late final Animation<double> _statsFade;
  late final Animation<double> _statsScale;

  // Focus card
  late final Animation<double> _focusFade;
  late final Animation<Offset> _focusSlide;

  // Label
  late final Animation<double> _labelFade;
  late final Animation<Offset> _labelSlide;

  // Exercise cards — built dynamically after data loads
  List<Animation<double>> _cardFades = [];
  List<Animation<Offset>> _cardSlides = [];

  // Button
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  // Button pulsing glow
  late final Animation<double> _buttonGlow;

  // Count-up (set after data loads)
  Animation<int>? _exerciseCount;
  Animation<int>? _minuteCount;
  Animation<int>? _setsCount;

  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchWorkoutDetails();
  }

  void _initControllers() {
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _statsFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut));
    _statsScale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOutBack));

    _focusCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _focusFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut));
    _focusSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOutCubic));

    _labelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _labelFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _labelCtrl, curve: Curves.easeOut));
    _labelSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _labelCtrl, curve: Curves.easeOutCubic));

    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _buttonCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _buttonFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOut));
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeOutCubic));

    _buttonGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _buttonGlow = Tween<double>(begin: 0.25, end: 0.55).animate(
        CurvedAnimation(parent: _buttonGlowCtrl, curve: Curves.easeInOut));

    _countCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
  }

  void _buildCardAnimations(int count) {
    _cardsCtrl.duration = Duration(milliseconds: 400 + count * 100);

    _cardFades = List.generate(count, (i) {
      final start = (i / count * 0.6).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _cardsCtrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });
    _cardSlides = List.generate(count, (i) {
      final start = (i / count * 0.6).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(
        CurvedAnimation(
            parent: _cardsCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });
  }

  void _buildCountAnimations(int exercises, int minutes, int sets) {
    _exerciseCount = IntTween(begin: 0, end: exercises)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));
    _minuteCount = IntTween(begin: 0, end: minutes)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));
    _setsCount = IntTween(begin: 0, end: sets)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    _statsCtrl.forward();
    _countCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 260));
    _focusCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _labelCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _buttonCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _focusCtrl.dispose();
    _labelCtrl.dispose();
    _cardsCtrl.dispose();
    _buttonCtrl.dispose();
    _buttonGlowCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkoutDetails() async {
    if (widget.workoutId != null && widget.workoutId!.startsWith('local_')) {
      String level = 'beginner';
      try {
        final res = await ApiService().getStrengthLevel();
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          level = data['data']?['strengthLevel'] ?? 'beginner';
        }
      } catch (_) {}

      final localWorkout = await LocalWorkoutPlanService()
          .loadWorkout(widget.workoutId!, level: level);
      if (localWorkout != null && mounted) {
        _applyWorkout(localWorkout);
        return;
      }
    }

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
            _applyWorkout(workout);
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
      _applyWorkout(fallbackWorkout);
      return;
    }

    // Demo data
    final demo = {
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
    demo['exercises'] = _withLocalExerciseVideos(
      (demo['exercises'] as List? ?? []),
    );
    _applyWorkout(demo);
  }

  void _applyWorkout(Map<String, dynamic> workout) {
    if (!mounted) return;
    final exercises = workout['exercises'] as List? ?? [];
    final duration =
        workout['durationMinutes'] ?? workout['estimatedDurationMinutes'] ?? 0;
    final sets = _getTotalSets(exercises);

    _buildCardAnimations(exercises.length);
    _buildCountAnimations(exercises.length, duration as int, sets);

    setState(() {
      _workout = workout;
      _isLoading = false;
      _animationsReady = true;
    });

    _runSequence();
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
    if (_isLoading || !_animationsReady) {
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
        title: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Column(
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

                  // ── Stats card ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _statsFade,
                    child: ScaleTransition(
                      scale: _statsScale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedBuilder(
                          animation: _countCtrl,
                          builder: (_, __) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSummaryStat(
                                  '${_exerciseCount?.value ?? exercises.length}',
                                  'Exercises'),
                              _buildVerticalDivider(),
                              _buildSummaryStat(
                                  '${_minuteCount?.value ?? durationMinutes}',
                                  'Minutes'),
                              _buildVerticalDivider(),
                              _buildSummaryStat(
                                  '${_setsCount?.value ?? _getTotalSets(exercises)}',
                                  'Total Sets'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Focus card ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _focusFade,
                    child: SlideTransition(
                      position: _focusSlide,
                      child: Container(
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
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Section label ───────────────────────────────────────
                  FadeTransition(
                    opacity: _labelFade,
                    child: SlideTransition(
                      position: _labelSlide,
                      child: const Text(
                        "Exercise Breakdown",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Exercise cards (staggered) ──────────────────────────
                  ...exercises.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final dynamic exercise = entry.value;
                    final fade = idx < _cardFades.length
                        ? _cardFades[idx]
                        : const AlwaysStoppedAnimation(1.0);
                    final slide = idx < _cardSlides.length
                        ? _cardSlides[idx]
                        : const AlwaysStoppedAnimation(Offset.zero);
                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: Container(
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
                              // Index bubble
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
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
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Start Workout Button ──────────────────────────────────────────
          FadeTransition(
            opacity: _buttonFade,
            child: SlideTransition(
              position: _buttonSlide,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppBounceAnimation(
                  onTap: () async {
                    final hasAccess = await ProAccessModal.checkAccess(
                      context,
                      featureName: _workout?['name'] ?? 'Workout Session',
                    );
                    if (!hasAccess || !context.mounted) return;

                    final workoutId = widget.workoutId ?? 'mock_workout_id';
                    final saved =
                        await ExerciseSessionScreen.getSavedSession(workoutId);
                    if (!context.mounted) return;
                    if (saved != null) {
                      final resume = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1B1B20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          title: const Text(
                            'Resume Workout?',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          content: Text(
                            'You have an unfinished session. Would you like to pick up where you left off?',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Start Fresh',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Resume',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      if (resume == false) {
                        final apiService = ApiService();
                        final docId = saved['id'] ?? saved['sessionDocId'];
                        if (docId != null) {
                          await apiService
                              .abandonWorkoutSession(docId.toString());
                        }
                      }

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExerciseSessionScreen(
                                  exercises: exercises,
                                  workoutId: workoutId,
                                  resumeExerciseIndex: resume == true
                                      ? ((saved['currentExerciseIndex'] ??
                                              saved['exerciseIndex']) as num?)
                                          ?.toInt()
                                      : null,
                                  resumeSetIndex: resume == true
                                      ? ((saved['currentSetIndex'] ??
                                              saved['setIndex']) as num?)
                                          ?.toInt()
                                      : null,
                                )),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExerciseSessionScreen(
                                  exercises: exercises,
                                  workoutId: workoutId,
                                )),
                      );
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _buttonGlow,
                    builder: (_, child) => Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: _buttonGlow.value),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: child,
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
