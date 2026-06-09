import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/workout_screens/achievement_screen.dart';
import 'package:best_u/view/workout_screens/workout_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final List<dynamic> exercises;
  final String workoutId;
  const ExerciseSessionScreen({
    super.key,
    required this.exercises,
    required this.workoutId,
  });

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  final TextEditingController _weightController =
      TextEditingController(text: '0');
  final TextEditingController _repsController =
      TextEditingController(text: '0');

  final DateTime _sessionStartTime = DateTime.now();
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showSetRoundAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideo() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _isVideoInitialized = false;
    });

    final exercise = _exerciseWithLocalVideo(
      widget.exercises[_currentExerciseIndex],
    );
    widget.exercises[_currentExerciseIndex] = exercise;
    final videoUrl = exercise['videoUrl']?.toString();

    try {
      if (videoUrl == null ||
          videoUrl.isEmpty ||
          (!videoUrl.startsWith('http') && !videoUrl.startsWith('assets/'))) {
        debugPrint("No valid exercise video found for ${exercise['name']}");
        return;
      } else if (videoUrl.startsWith('assets/')) {
        _videoController = VideoPlayerController.asset(videoUrl);
      } else {
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
          _videoController?.setLooping(true);
        }
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
        _retryWithLocalVideo(exercise);
      });
    } catch (e) {
      debugPrint("Video controller setup error: $e");
      _retryWithLocalVideo(exercise);
    }
  }

  void _retryWithLocalVideo(dynamic exercise) {
    final localExercise = _exerciseWithLocalVideo(exercise);
    final localVideoUrl = localExercise['videoUrl']?.toString();
    final currentVideoUrl = exercise['videoUrl']?.toString();

    if (localVideoUrl == null ||
        localVideoUrl.isEmpty ||
        localVideoUrl == currentVideoUrl) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
      return;
    }

    widget.exercises[_currentExerciseIndex] = localExercise;
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(localVideoUrl);
    _videoController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController?.play();
      _videoController?.setLooping(true);
    }).catchError((error) {
      debugPrint("Local video initialization error: $error");
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });
  }

  Map<String, dynamic> _exerciseWithLocalVideo(dynamic exercise) {
    if (exercise is! Map) return <String, dynamic>{};
    return LocalWorkoutPlanService().attachLocalVideo(
      Map<String, dynamic>.from(exercise),
    );
  }

  Future<void> _logSet() async {
    final exercise = widget.exercises[_currentExerciseIndex];
    final currentSet = _currentSetDetails(
      Map<String, dynamic>.from(exercise as Map),
    );
    final apiService = ApiService();
    try {
      await apiService.logSet({
        'workoutId': widget.workoutId,
        'exerciseName': exercise['name'],
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'reps': int.tryParse(_repsController.text) ?? 0,
        'setNumber': currentSet['set'] as int? ?? _currentSetIndex + 1,
        'goal': currentSet['goal'] ?? currentSet['instruction'],
      });
    } catch (e) {
      debugPrint("Error logging set: $e");
    }
  }

  void _onCompleteExercise() async {
    await _logSet();

    if (!mounted) return;

    final nextPosition = _nextWorkoutPosition();
    if (nextPosition == null) {
      _completeWorkout();
      return;
    }

    final isNewSetRound = nextPosition.setIndex != _currentSetIndex;
    setState(() {
      _currentExerciseIndex = nextPosition.exerciseIndex;
      _currentSetIndex = nextPosition.setIndex;
      _weightController.text = '0';
      _repsController.text = '0';
      _showSetRoundAnimation = isNewSetRound;
    });
    _initializeVideo();

    if (isNewSetRound) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _showSetRoundAnimation = false;
        });
      });
    }
  }

  Future<void> _completeWorkout() async {
    try {
      final apiService = ApiService();
      // We'll use a placeholder for timeTakenMinutes as we don't track it yet in UI
      await apiService.completeWorkout(widget.workoutId, 45, 0);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AchievementScreen(
            nextScreen: WorkoutCompleteScreen(
              exercisesCompleted: widget.exercises.length,
              durationMinutes: DateTime.now()
                  .difference(_sessionStartTime)
                  .inMinutes
                  .clamp(1, 999),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error completing workout: $e");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AchievementScreen(
            nextScreen: WorkoutCompleteScreen(
              exercisesCompleted: widget.exercises.length,
              durationMinutes: DateTime.now()
                  .difference(_sessionStartTime)
                  .inMinutes
                  .clamp(1, 999),
            ),
          ),
        ),
      );
    }
  }

  bool _hasWeightInput(Map<String, dynamic> exercise) {
    return _currentSetDetails(exercise)['hasWeightTarget'] == true;
  }

  String _currentSetLabel(Map<String, dynamic> exercise) {
    final setNumber = _currentSetDetails(exercise)['set'];
    return 'Set ${setNumber ?? _currentSetIndex + 1}';
  }

  String _targetValue(Map<String, dynamic> exercise) {
    final currentSet = _currentSetDetails(exercise);
    final goal = currentSet['goal'] ?? currentSet['instruction'];
    return goal?.toString() ?? '--';
  }

  String _setsRepsText(Map<String, dynamic> exercise) {
    final sets = exercise['sets'] ?? 0;
    final reps = exercise['reps']?.toString().trim();
    if (reps == null || reps.isEmpty || reps == 'See instructions') {
      final duration = exercise['durationSeconds']?.toString().trim();
      if (duration == null || duration.isEmpty) {
        return '$sets';
      }
      return '$sets × $duration sec';
    }
    return '$sets × $reps';
  }

  String _setsTargetLabel(Map<String, dynamic> exercise) {
    final reps = exercise['reps']?.toString().trim();
    if (reps == null || reps.isEmpty || reps == 'See instructions') {
      return "   sets × time";
    }
    return "   sets × reps";
  }

  List<Map<String, dynamic>> _setDetailsFor(dynamic exercise) {
    if (exercise is! Map) {
      return [
        {
          'set': 1,
          'instruction': '',
          'goal': '',
          'hasWeightTarget': false,
        }
      ];
    }

    final details = exercise['setDetails'];
    if (details is List && details.isNotEmpty) {
      return details
          .whereType<Map>()
          .map((set) => Map<String, dynamic>.from(set))
          .toList();
    }

    final instructions = exercise['setInstructions'];
    if (instructions is List && instructions.isNotEmpty) {
      return instructions.asMap().entries.map((entry) {
        return {
          'set': entry.key + 1,
          'instruction': entry.value?.toString() ?? '',
          'goal': entry.value?.toString() ?? '',
          'hasWeightTarget': RegExp(
                  r'\d+(?:\.\d+)?(?:\s*-\s*\d+(?:\.\d+)?)?\s*kg',
                  caseSensitive: false)
              .hasMatch(entry.value?.toString() ?? ''),
        };
      }).toList();
    }

    return [
      {
        'set': 1,
        'instruction': _setsRepsText(Map<String, dynamic>.from(exercise)),
        'goal': _setsRepsText(Map<String, dynamic>.from(exercise)),
        'hasWeightTarget': exercise['hasWeightTarget'] == true,
      }
    ];
  }

  Map<String, dynamic> _currentSetDetails(Map<String, dynamic> exercise) {
    final details = _setDetailsFor(exercise);
    final setIndex = _currentSetIndex.clamp(0, details.length - 1).toInt();
    return details[setIndex];
  }

  String _actionButtonText(Map<String, dynamic> exercise) {
    final nextPosition = _nextWorkoutPosition();
    if (nextPosition == null) return 'COMPLETE WORKOUT';
    if (nextPosition.setIndex != _currentSetIndex) {
      return 'START SET ${nextPosition.setIndex + 1}';
    }
    if (nextPosition.exerciseIndex > _currentExerciseIndex) {
      return 'NEXT EXERCISE';
    }
    return 'CONTINUE';
  }

  _WorkoutPosition? _nextWorkoutPosition() {
    for (var index = _currentExerciseIndex + 1;
        index < widget.exercises.length;
        index++) {
      if (_exerciseHasSet(index, _currentSetIndex)) {
        return _WorkoutPosition(index, _currentSetIndex);
      }
    }

    for (var setIndex = _currentSetIndex + 1;
        setIndex < _maxSetCount;
        setIndex++) {
      for (var index = 0; index < widget.exercises.length; index++) {
        if (_exerciseHasSet(index, setIndex)) {
          return _WorkoutPosition(index, setIndex);
        }
      }
    }

    return null;
  }

  bool _exerciseHasSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= widget.exercises.length) {
      return false;
    }
    return _setDetailsFor(widget.exercises[exerciseIndex]).length > setIndex;
  }

  int get _maxSetCount {
    var maxSets = 1;
    for (final exercise in widget.exercises) {
      final setCount = _setDetailsFor(exercise).length;
      if (setCount > maxSets) maxSets = setCount;
    }
    return maxSets;
  }

  int get _totalSetSteps {
    var total = 0;
    for (final exercise in widget.exercises) {
      total += _setDetailsFor(exercise).length;
    }
    return total == 0 ? 1 : total;
  }

  int get _currentSetStep {
    var step = 0;
    for (var setIndex = 0; setIndex < _currentSetIndex; setIndex++) {
      for (var exerciseIndex = 0;
          exerciseIndex < widget.exercises.length;
          exerciseIndex++) {
        if (_exerciseHasSet(exerciseIndex, setIndex)) step++;
      }
    }
    for (var exerciseIndex = 0;
        exerciseIndex < _currentExerciseIndex;
        exerciseIndex++) {
      if (_exerciseHasSet(exerciseIndex, _currentSetIndex)) step++;
    }
    return step + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Scaffold(body: Center(child: Text("No exercises found")));
    }

    final exercise =
        Map<String, dynamic>.from(widget.exercises[_currentExerciseIndex]);
    final progress = _currentSetStep / _totalSetSteps;
    final hasWeightInput = _hasWeightInput(exercise);
    final currentSetRound = _currentSetIndex + 1;
    final maxSetCount = _maxSetCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Text(
                        'Set $currentSetRound of $maxSetCount • Exercise ${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer for balance
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 3,
                            backgroundColor: const Color(0xFF1F1F1F),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    child: _showSetRoundAnimation
                        ? _buildSetRoundBanner(currentSetRound)
                        : Text(
                            'Complete set $currentSetRound for every exercise before moving on.',
                            key: ValueKey('set-helper-$currentSetRound'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white.withValues(alpha: 0.46),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: SizedBox.expand(
                  key: ValueKey(
                    'exercise-$_currentExerciseIndex-set-$_currentSetIndex',
                  ),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Demonstration Card
                      Container(
                        width: double.infinity,
                        height: 210,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              _isVideoInitialized && _videoController != null
                                  ? Positioned.fill(
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: SizedBox(
                                          width: _videoController!
                                              .value.size.width,
                                          height: _videoController!
                                              .value.size.height,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                      ),
                                    )
                                  : Center(
                                        child: (exercise['videoUrl'] != null &&
                                                exercise['videoUrl']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      const SizedBox(
                                                        width: 50,
                                                        height: 50,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<Color>(
                                                            AppColors.primary,
                                                          ),
                                                          backgroundColor:
                                                              Color(0xFFEAEAEA),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.fitness_center_rounded,
                                                        color: AppColors.primary,
                                                        size: 24,
                                                      )
                                                          .animate(
                                                              onPlay: (controller) =>
                                                                  controller.repeat())
                                                          .shimmer(
                                                              duration: 1500.ms,
                                                              color: Colors.white)
                                                          .scale(
                                                              begin: const Offset(
                                                                  0.95, 0.95),
                                                              end: const Offset(
                                                                  1.05, 1.05),
                                                              duration: 1000.ms,
                                                              curve: Curves.easeInOut)
                                                          .then()
                                                          .scale(
                                                              begin: const Offset(
                                                                  1.05, 1.05),
                                                              end: const Offset(
                                                                  0.95, 0.95),
                                                              duration: 1000.ms,
                                                              curve: Curves.easeInOut),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 18),
                                                  Text(
                                                    "Loading Video...",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      color: Colors.black
                                                          .withValues(alpha: 0.6),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  )
                                                      .animate(
                                                          onPlay: (controller) =>
                                                              controller.repeat())
                                                      .shimmer(
                                                          duration: 2000.ms,
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.3)),
                                                ],
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.04),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.videocam_off_rounded,
                                                      color: Colors.black
                                                          .withValues(alpha: 0.3),
                                                      size: 32,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    "Video unavailable",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      color: Colors.black
                                                          .withValues(alpha: 0.4),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title and Sets/Reps
                      Text(
                        exercise['name'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _setsRepsText(exercise),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: _setsTargetLabel(exercise),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color:
                                    AppColors.primary.withValues(alpha: 0.75),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Previous and Target Stats
                      Row(
                        children: [
                          _buildStatBox("SET", _currentSetLabel(exercise)),
                          const SizedBox(width: 10),
                          _buildStatBox("TARGET", _targetValue(exercise),
                              isTarget: true),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Log Section Header
                      Text(
                        "Log Your Result",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Weight and Reps Inputs
                      if (hasWeightInput)
                        Row(
                          children: [
                            _buildInputBox("Weight (kg)", _weightController),
                            const SizedBox(width: 10),
                            _buildInputBox("Reps Completed", _repsController),
                          ],
                        )
                      else
                        Row(
                          children: [
                            _buildInputBox("Reps Completed", _repsController),
                          ],
                        ),
                    ],
                  ),
                  ),
                ),
              ),
            ),

            // Complete Exercise Button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: AppBounceAnimation(
                onTap: _onCompleteExercise,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _actionButtonText(exercise),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRoundBanner(int setRound) {
    return Container(
      key: ValueKey('set-round-$setRound'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.repeat_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Set $setRound round started',
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool isTarget = false}) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isTarget
                ? AppColors.primary.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isTarget ? AppColors.primary : Colors.white,
                fontSize: isTarget ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController controller) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPosition {
  final int exerciseIndex;
  final int setIndex;

  const _WorkoutPosition(this.exerciseIndex, this.setIndex);
}
