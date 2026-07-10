import 'dart:async';
import 'dart:convert';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/workout_screens/achievement_screen.dart';
import 'package:best_u/view/workout_screens/workout_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final List<dynamic> exercises;
  final String workoutId;
  final int? resumeExerciseIndex;
  final int? resumeSetIndex;
  const ExerciseSessionScreen({
    super.key,
    required this.exercises,
    required this.workoutId,
    this.resumeExerciseIndex,
    this.resumeSetIndex,
  });

  static const String _sessionPrefKey = 'workout_session_';

  static Future<Map<String, dynamic>?> getSavedSession(String workoutId) async {
    try {
      final apiService = ApiService();
      final active = await apiService.getActiveWorkoutSession(workoutId);
      if (active != null) return active;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_sessionPrefKey$workoutId');
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  late DateTime _sessionStartTime;
  final Map<String, double> _loggedSetsVolume = {};
  String? _sessionDocId;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showSetRoundAnimation = false;

  // 3-second hold before advancing
  bool _isHolding = false;
  int _holdCountdown = 3;
  Timer? _holdTimer;

  // Hold countdown overlay animation
  late final AnimationController _holdOverlayCtrl;
  late final AnimationController _holdDigitCtrl;
  late final AnimationController _holdRingCtrl;
  late final Animation<double> _holdOverlayFade;
  late final Animation<double> _holdDigitScale;
  late final Animation<double> _holdDigitFade;
  late final Animation<double> _holdRingScale;
  late final Animation<double> _holdRingOpacity;

  // Last results fetched from Firestore (exerciseName -> list of {setNumber, reps, weight})
  Map<String, List<Map<String, dynamic>>> _lastResults = {};
  bool _lastResultsLoaded = false;

  // Session improvements tracking for WorkoutCompleteScreen
  final Map<String, String> _sessionImprovements = {};
  int _personalBestsCount = 0;

  static const String _sessionPrefKey = ExerciseSessionScreen._sessionPrefKey;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _sessionDocId = ApiService().generateSessionId();
    _loadSessionStartTimeAndVolume();
    // Restore saved position if resuming
    if (widget.resumeExerciseIndex != null) {
      _currentExerciseIndex = widget.resumeExerciseIndex!;
    }
    if (widget.resumeSetIndex != null) {
      _currentSetIndex = widget.resumeSetIndex!;
    }

    // ── Hold overlay animations ───────────────────────────────
    _holdOverlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _holdOverlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _holdOverlayCtrl, curve: Curves.easeOut),
    );

    // Per-digit bounce
    _holdDigitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _holdDigitScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.88), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _holdDigitCtrl, curve: Curves.easeOut));
    _holdDigitFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _holdDigitCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // Pulsing ring
    _holdRingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _holdRingScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _holdRingCtrl, curve: Curves.easeInOut),
    );
    _holdRingOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _holdRingCtrl, curve: Curves.easeInOut),
    );

    _initializeVideo();
    _loadLastResults();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _videoController?.dispose();
    _holdTimer?.cancel();
    _holdOverlayCtrl.dispose();
    _holdDigitCtrl.dispose();
    _holdRingCtrl.dispose();
    super.dispose();
  }

  // ─── Last Results Loading ───────────────────────────────────────────────────

  Future<void> _loadLastResults() async {
    final names = widget.exercises
        .whereType<Map>()
        .map((e) => e['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final apiService = ApiService();
    try {
      final results = await apiService.getLastResultsForExercises(names);
      if (mounted) {
        setState(() {
          _lastResults = results;
          _lastResultsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading last results: $e');
      if (mounted) setState(() => _lastResultsLoaded = true);
    }
  }

  Map<String, dynamic>? _lastResultForCurrentSet() {
    final exercise = widget.exercises[_currentExerciseIndex];
    if (exercise is! Map) return null;
    final name = exercise['name']?.toString() ?? '';
    final sets = _lastResults[name] ?? [];
    final setNum =
        _currentSetDetails(Map<String, dynamic>.from(exercise))['set']
                as int? ??
            _currentSetIndex + 1;
    try {
      return sets.firstWhere((s) => s['setNumber'] == setNum);
    } catch (_) {
      return null;
    }
  }

  /// Calculate goal: 1 more rep than last result, or +2kg if already at/above last reps
  Map<String, dynamic> _goalForCurrentSet() {
    final last = _lastResultForCurrentSet();
    final exercise = widget.exercises[_currentExerciseIndex];
    final exerciseMap = exercise is Map
        ? Map<String, dynamic>.from(exercise)
        : <String, dynamic>{};
    final currentSet = _currentSetDetails(exerciseMap);
    final hasWeight = currentSet['hasWeightTarget'] == true;

    if (last == null) {
      // No history — show plan instruction as goal
      return {
        'reps': null,
        'weight': null,
        'displayText': currentSet['goal']?.toString() ?? '--',
      };
    }

    final lastReps = last['reps'] as int? ?? 0;
    final lastWeight = last['weight'] as double? ?? 0.0;

    // Parse target reps from the plan
    final targetRepsStr = currentSet['targetReps']?.toString();
    int? planTargetReps;
    if (targetRepsStr != null) {
      planTargetReps = int.tryParse(targetRepsStr.split('-').last.trim());
    }

    int goalReps = lastReps + 1;
    double goalWeight = lastWeight;

    if (hasWeight && planTargetReps != null && lastReps >= planTargetReps) {
      // At target reps → increase weight instead
      goalReps = lastReps;
      goalWeight = lastWeight + 2.0;
    }

    String display;
    if (hasWeight && goalWeight > 0) {
      final weightStr = goalWeight == goalWeight.roundToDouble()
          ? goalWeight.round().toString()
          : goalWeight.toStringAsFixed(1);
      display = '$goalReps x ${weightStr}kg';
    } else {
      display = '$goalReps reps';
    }

    return {
      'reps': goalReps,
      'weight': goalWeight,
      'displayText': display,
    };
  }

  String _lastResultDisplayText() {
    final last = _lastResultForCurrentSet();
    if (last == null) return '--';
    final reps = last['reps'] as int? ?? 0;
    final weight = last['weight'] as double? ?? 0.0;
    if (weight > 0) {
      final wStr = weight == weight.roundToDouble()
          ? weight.round().toString()
          : weight.toStringAsFixed(1);
      return '$reps x ${wStr}kg';
    }
    return reps > 0 ? '$reps reps' : '--';
  }

  // ─── Session Save / Resume ──────────────────────────────────────────────────

  String get _sessionKey => '$_sessionPrefKey${widget.workoutId}';

  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'exerciseIndex': _currentExerciseIndex,
        'setIndex': _currentSetIndex,
        'weight': _weightController.text,
        'reps': _repsController.text,
        'startTime': _sessionStartTime.toIso8601String(),
        'sessionDocId': _sessionDocId,
      });
      await prefs.setString(_sessionKey, data);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  DateTime? _dateFrom(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _loadSessionStartTimeAndVolume() async {
    // If resuming, try to load original session start time and previous set logs
    if (widget.resumeExerciseIndex != null) {
      final saved = await ExerciseSessionScreen.getSavedSession(widget.workoutId);
      if (saved != null) {
        final startStr = saved['sessionStartTime'] ?? saved['startTime'];
        if (startStr != null) {
          final parsed = DateTime.tryParse(startStr.toString());
          if (parsed != null) {
            setState(() {
              _sessionStartTime = parsed;
            });
          }
        }
        final docId = saved['id'] ?? saved['sessionDocId'];
        if (docId != null) {
          _sessionDocId = docId.toString();
        }
        
        final exIndex = saved['currentExerciseIndex'] ?? saved['exerciseIndex'];
        final setIndex = saved['currentSetIndex'] ?? saved['setIndex'];
        final weightVal = saved['weight'];
        final repsVal = saved['reps'];

        setState(() {
          if (exIndex != null) _currentExerciseIndex = (exIndex as num).toInt();
          if (setIndex != null) _currentSetIndex = (setIndex as num).toInt();
          if (weightVal != null) _weightController.text = weightVal.toString();
          if (repsVal != null) _repsController.text = repsVal.toString();
        });
      }

      // Load previous logged sets for this workout from Firestore to compute initial volume
      try {
        final apiService = ApiService();
        final logs = await apiService.getExerciseLogsForWorkout(widget.workoutId);
        final twelveHoursAgo = DateTime.now().subtract(const Duration(hours: 12));
        for (final log in logs) {
          final date = _dateFrom(log['loggedAt']);
          if (date != null && date.isAfter(twelveHoursAgo)) {
            final exerciseName = log['exerciseName']?.toString() ?? '';
            final setNum = (log['setNumber'] as num?)?.toInt() ?? 0;
            final weight = (log['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = (log['reps'] as num?)?.toInt() ?? 0;
            final setKey = '$exerciseName-$setNum';
            _loggedSetsVolume[setKey] = weight * reps;
          }
        }
      } catch (e) {
        debugPrint("Error restoring session volume: $e");
      }
    }
  }

  int get _totalSetsCount {
    int count = 0;
    for (final ex in widget.exercises) {
      if (ex is Map) {
        final sets = ex['sets'];
        if (sets is num) {
          count += sets.toInt();
        }
      }
    }
    return count > 0 ? count : 1;
  }

  Future<void> _updateSessionProgress({required bool isCompleted}) async {
    if (_sessionDocId == null) return;
    try {
      final apiService = ApiService();
      final durationMinutes = DateTime.now()
          .difference(_sessionStartTime)
          .inMinutes
          .clamp(1, 999);
      final totalVolume = _loggedSetsVolume.values
          .fold<double>(0.0, (sum, val) => sum + val)
          .round();
      final double completionPercentage = _loggedSetsVolume.length / _totalSetsCount;

      await apiService.updateWorkoutSession(
        docId: _sessionDocId!,
        workoutId: widget.workoutId,
        timeTakenMinutes: durationMinutes,
        volumeLifted: totalVolume,
        completionPercentage: completionPercentage,
        isCompleted: isCompleted,
        currentExerciseIndex: _currentExerciseIndex,
        currentSetIndex: _currentSetIndex,
        weight: _weightController.text,
        reps: _repsController.text,
        sessionStartTime: _sessionStartTime.toIso8601String(),
      );
    } catch (e) {
      debugPrint("Error updating session progress: $e");
    }
  }

  // ─── Video ──────────────────────────────────────────────────────────────────

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

  // ─── Logging & Advancing ────────────────────────────────────────────────────

  Future<void> _logSet() async {
    final exercise = widget.exercises[_currentExerciseIndex];
    final currentSet = _currentSetDetails(
      Map<String, dynamic>.from(exercise as Map),
    );
    final apiService = ApiService();
    final exerciseName = exercise['name']?.toString() ?? '';
    final loggedReps = int.tryParse(_repsController.text) ?? 0;
    final loggedWeight = double.tryParse(_weightController.text) ?? 0.0;
    final setNum = currentSet['set'] as int? ?? _currentSetIndex + 1;

    try {
      await apiService.logSet({
        'workoutId': widget.workoutId,
        'exerciseName': exerciseName,
        'weight': loggedWeight,
        'reps': loggedReps,
        'setNumber': setNum,
        'goal': currentSet['goal'] ?? currentSet['instruction'],
      });
      final setKey = '$exerciseName-$setNum';
      _loggedSetsVolume[setKey] = loggedWeight * loggedReps;
      _updateSessionProgress(isCompleted: false);
    } catch (e) {
      debugPrint("Error logging set: $e");
    }

    // Check for personal best
    _checkPersonalBest(exerciseName, setNum, loggedReps, loggedWeight);
  }

  void _checkPersonalBest(
      String exerciseName, int setNum, int loggedReps, double loggedWeight) {
    final sets = _lastResults[exerciseName] ?? [];
    Map<String, dynamic>? last;
    try {
      last = sets.firstWhere((s) => s['setNumber'] == setNum);
    } catch (_) {
      last = null;
    }

    bool isPB = false;
    int repDiff = loggedReps;
    double weightDiff = loggedWeight;

    if (last == null) {
      // First time logging this set of this exercise — it is a Personal Best!
      isPB = loggedReps > 0 || loggedWeight > 0;
    } else {
      final lastReps = last['reps'] as int? ?? 0;
      final lastWeight = last['weight'] as double? ?? 0.0;
      repDiff = loggedReps - lastReps;
      weightDiff = loggedWeight - lastWeight;

      if (loggedWeight > 0 && lastWeight > 0) {
        // Weight exercise: PB if more weight, or same weight + more reps
        isPB = loggedWeight > lastWeight ||
            (loggedWeight >= lastWeight && loggedReps > lastReps);
      } else {
        // Bodyweight / timed: PB if more reps/seconds
        isPB = loggedReps > lastReps;
      }
    }

    if (isPB) {
      _personalBestsCount++;
      final wStr = loggedWeight > 0
          ? ' x ${loggedWeight == loggedWeight.roundToDouble() ? loggedWeight.round() : loggedWeight.toStringAsFixed(1)}kg'
          : '';
      
      if (last == null) {
        _sessionImprovements[exerciseName] = '${loggedReps} reps$wStr';
      } else {
        final sign = weightDiff > 0 ? '+' : '';
        final wDiffStr = weightDiff > 0
            ? ' (+$weightDiff kg)'
            : '';
        final repSign = repDiff >= 0 ? '+' : '';
        _sessionImprovements[exerciseName] = '${repSign}${repDiff} reps$wDiffStr';
      }
    }
  }

  void _onTapActionButton() {
    if (_isHolding) return;

    // Start 3-second hold countdown
    setState(() {
      _isHolding = true;
      _holdCountdown = 3;
    });

    // Show overlay + first digit animation
    _holdOverlayCtrl.forward(from: 0);
    _holdDigitCtrl.forward(from: 0);
    _holdRingCtrl.repeat(reverse: true);

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_holdCountdown <= 1) {
        timer.cancel();
        _holdRingCtrl.stop();
        _holdOverlayCtrl.reverse().then((_) {
          if (mounted) setState(() => _isHolding = false);
        });
        _onCompleteExercise();
      } else {
        setState(() => _holdCountdown--);
        // Animate the new digit
        _holdDigitCtrl.forward(from: 0);
      }
    });
  }

  void _onCompleteExercise() async {
    await _logSet();

    if (!mounted) return;

    final nextPosition = _nextWorkoutPosition();
    if (nextPosition == null) {
      await _clearSession();
      _completeWorkout();
      return;
    }

    final isNewSetRound = nextPosition.setIndex != _currentSetIndex;
    setState(() {
      _currentExerciseIndex = nextPosition.exerciseIndex;
      _currentSetIndex = nextPosition.setIndex;
      _weightController.clear();
      _repsController.clear();
      _showSetRoundAnimation = isNewSetRound;
    });
    _initializeVideo();
    await _saveSession();

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
      await _updateSessionProgress(isCompleted: true);
      await _clearSession();

      if (!mounted) return;
      final durationMinutes = DateTime.now()
          .difference(_sessionStartTime)
          .inMinutes
          .clamp(1, 999);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AchievementScreen(
            nextScreen: WorkoutCompleteScreen(
              workoutId: widget.workoutId,
              exercisesCompleted: widget.exercises.length,
              durationMinutes: durationMinutes,
              personalBests: _personalBestsCount,
              improvements: Map<String, String>.from(_sessionImprovements),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error completing workout: $e");
      if (!mounted) return;
      final durationMinutes = DateTime.now()
          .difference(_sessionStartTime)
          .inMinutes
          .clamp(1, 999);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AchievementScreen(
            nextScreen: WorkoutCompleteScreen(
              workoutId: widget.workoutId,
              exercisesCompleted: widget.exercises.length,
              durationMinutes: durationMinutes,
              personalBests: _personalBestsCount,
              improvements: Map<String, String>.from(_sessionImprovements),
            ),
          ),
        ),
      );
    }
  }

  // ─── Exercise / Set Helpers ─────────────────────────────────────────────────

  bool _hasWeightInput(Map<String, dynamic> exercise) {
    // Show weight field if ANY set for this exercise has a weight target
    final details = _setDetailsFor(exercise);
    return details.any((set) => set['hasWeightTarget'] == true);
  }

  bool _isTimedExercise(Map<String, dynamic> exercise) {
    // Timed if durationSeconds is set OR no reps in any set instruction
    if (exercise['durationSeconds'] != null &&
        exercise['durationSeconds'].toString().isNotEmpty) {
      return true;
    }
    final reps = exercise['reps']?.toString().trim();
    return reps == null || reps.isEmpty || reps == 'See instructions';
  }

  String _currentSetLabel(Map<String, dynamic> exercise) {
    final setNumber = _currentSetDetails(exercise)['set'];
    return 'Set ${setNumber ?? _currentSetIndex + 1}';
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
        'instruction': '',
        'goal': '',
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
    if (_isHolding) return _holdCountdown.toString();
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Scaffold(body: Center(child: Text("No exercises found")));
    }

    final exercise =
        Map<String, dynamic>.from(widget.exercises[_currentExerciseIndex]);
    final progress = _currentSetStep / _totalSetSteps;
    final hasWeightInput = _hasWeightInput(exercise);
    final isTimed = _isTimedExercise(exercise);
    final currentSetRound = _currentSetIndex + 1;
    final maxSetCount = _maxSetCount;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await _updateSessionProgress(isCompleted: false);
          await _saveSession();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
            children: [
              // Top Navigation & Progress
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await _updateSessionProgress(isCompleted: false);
                            await _saveSession();
                            if (mounted) Navigator.pop(context);
                          },
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
                        const SizedBox(width: 40),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
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
                                  _isVideoInitialized &&
                                          _videoController != null
                                      ? Positioned.fill(
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                              width: _videoController!
                                                  .value.size.width,
                                              height: _videoController!
                                                  .value.size.height,
                                              child: VideoPlayer(
                                                  _videoController!),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: (exercise['videoUrl'] !=
                                                      null &&
                                                  exercise['videoUrl']
                                                      .toString()
                                                      .isNotEmpty)
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        const SizedBox(
                                                          width: 50,
                                                          height: 50,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                    Color>(
                                                              AppColors.primary,
                                                            ),
                                                            backgroundColor:
                                                                Color(
                                                                    0xFFEAEAEA),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .fitness_center_rounded,
                                                          color:
                                                              AppColors.primary,
                                                          size: 24,
                                                        )
                                                            .animate(
                                                                onPlay: (controller) =>
                                                                    controller
                                                                        .repeat())
                                                            .shimmer(
                                                                duration:
                                                                    1500.ms,
                                                                color: Colors
                                                                    .white)
                                                            .scale(
                                                                begin: const Offset(
                                                                    0.95, 0.95),
                                                                end: const Offset(
                                                                    1.05, 1.05),
                                                                duration:
                                                                    1000.ms,
                                                                curve: Curves
                                                                    .easeInOut)
                                                            .then()
                                                            .scale(
                                                                begin: const Offset(
                                                                    1.05, 1.05),
                                                                end:
                                                                    const Offset(
                                                                        0.95,
                                                                        0.95),
                                                                duration:
                                                                    1000.ms,
                                                                curve: Curves
                                                                    .easeInOut),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 18),
                                                    Text(
                                                      "Loading Video...",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.6),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    )
                                                        .animate(
                                                            onPlay:
                                                                (controller) =>
                                                                    controller
                                                                        .repeat())
                                                        .shimmer(
                                                            duration: 2000.ms,
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha:
                                                                        0.3)),
                                                  ],
                                                )
                                              : Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.04),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .videocam_off_rounded,
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.3),
                                                        size: 32,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      "Video unavailable",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.4),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                          const SizedBox(height: 14),

                          // Exercise Name
                          Text(
                            exercise['name'],
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Set label below exercise name
                          Text(
                            _currentSetLabel(exercise),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Last Result | Goal boxes
                          _buildLastResultAndGoal(exercise),
                          const SizedBox(height: 14),

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

                          // Weight and Reps/Seconds Inputs
                          if (hasWeightInput)
                            Row(
                              children: [
                                _buildInputBox(
                                  "Weight (kg)",
                                  _weightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                                const SizedBox(width: 10),
                                _buildInputBox(
                                  isTimed
                                      ? "Seconds Achieved"
                                      : "Reps Completed",
                                  _repsController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                _buildInputBox(
                                  isTimed
                                      ? "Seconds Achieved"
                                      : "Reps Completed",
                                  _repsController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: AppBounceAnimation(
                  onTap: _isHolding ? null : _onTapActionButton,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isHolding
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.primary,
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

              // ── Hold Countdown Overlay ─────────────────────────
              if (_isHolding)
                FadeTransition(
                  opacity: _holdOverlayFade,
                  child: _buildHoldOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_holdDigitCtrl, _holdRingCtrl, _holdOverlayCtrl]),
      builder: (_, __) {
        return Container(
          color: Colors.black.withValues(alpha: 0.72),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                Transform.scale(
                  scale: _holdRingScale.value,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: _holdRingOpacity.value),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                // Inner circle
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1B1B20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Digit
                FadeTransition(
                  opacity: _holdDigitFade,
                  child: Transform.scale(
                    scale: _holdDigitScale.value,
                    child: Text(
                      '$_holdCountdown',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 62,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

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

  /// Replaces the old SET / TARGET boxes with the new Last Result | Goal layout
  Widget _buildLastResultAndGoal(Map<String, dynamic> exercise) {
    final lastText = _lastResultsLoaded ? _lastResultDisplayText() : '…';
    final goal = _lastResultsLoaded ? _goalForCurrentSet() : null;
    final goalText = goal?['displayText']?.toString() ?? '…';

    return Row(
      children: [
        _buildStatBox(
          "LAST RESULT",
          lastText,
          isGoal: false,
        ),
        const SizedBox(width: 10),
        _buildStatBox(
          "GOAL",
          goalText,
          isGoal: true,
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, {bool isGoal = false}) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGoal
                ? AppColors.primary.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 12,
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
                color: AppColors.primary,
                fontSize: isGoal ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.number,
  }) {
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
              keyboardType: keyboardType,
              onTap: () {
                // Select all on tap so user doesn't have to clear manually
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                hintText: '0',
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w600,
                ),
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
