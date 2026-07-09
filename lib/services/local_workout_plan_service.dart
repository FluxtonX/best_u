import 'dart:convert';

import 'package:flutter/services.dart';

class LocalWorkoutPlanService {
  static const String _assetPath =
      'assets/data/best_u_8_week_workout_plan.json';
  static const String _exerciseVideoPath = 'assets/video/exercises';

  static const Map<String, String> _exerciseVideos = {
    'bench dips': 'Triceps-Dip-Floor_Upper-Arms-FIX_.mp4',
    'bench press': 'Dumbbell-Bench-Press-(female)_Chest.mp4',
    'bicep curl': 'Dumbbell-Standing-Biceps-Curl_Upper-Arms-FIX2_.mp4',
    'clock push up': 'Clock-Push-Up_Chest.mp4',
    'clock push ups': 'Clock-Push-Up_Chest.mp4',
    'cross body hammer curl':
        'Dumbbell-Cross-Body-Hammer-Curl-(Version-2)_Upper-Arms-FIX.mp4',
    'dumbbell flys': 'Dumbbell-Fly_Chest-FIX2_.mp4',
    'dumbell pullover': 'Dumbbell-Pullover-(VERSION-2)_Back_.mp4',
    'flat bench lateral raise':
        'Dumbbell-Lying-Rear-Lateral-Raise_Shoulders_.mp4',
    'front raises': 'Dumbbell-Standing-Alternate-Vertical-Front-Raises_.mp4',
    'hammer curls': 'Dumbbell-Hammer-Curl-(version-2)_Upper-Arms-FIX_.mp4',
    'incline bench press': 'Dumbbell-Incline-Bench-Press_Chest-FIX2_.mp4',
    'incline dumbbell flys': 'Dumbbell-Incline-Fly_Chest-FIX2_.mp4',
    'incline dumbbell row':
        'Dumbbell-One-Arm-Bent-over-Row-(female)_Shoulders.mp4',
    'incline tricep extension':
        'Dumbbell-Incline-Triceps-Extension_Upper-Arms-FIX_.mp4',
    'lateral raises': 'Dumbbell-Lateral-Raise_shoulder-FIX_.mp4',
    'leg raises': 'Leg-Raise-Hip-Lift-with-Head-up_Waist.mp4',
    'lunges': 'Lunge-Stretch-(female)_Thighs_.mp4',
    'lunges with weights': 'Dumbbell-Rear-Lunge_Thighs-FIX_.mp4',
    'one arm row': 'Dumbbell-One-Arm-Bent-over-Row-(female)_Shoulders.mp4',
    'plank': 'Front-Elbow-Plank-(male)_Waist-FIX_.mp4',
    'press up': 'Clock-Push-Up_Chest.mp4',
    'pull ups knuckles away': 'Reverse-grip-Pull-up_Back-FIX_.mp4',
    'pull ups knuckles towards': 'Sternum-Pull-up-(Gironda)_Back_.mp4',
    'reverse lunges': 'Dumbbell-Rear-Lunge_Thighs-FIX_.mp4',
    'roller': 'Wheel-Rollout_Waist-FIX2_.mp4',
    'russian twist': 'Russian-Twist-(female)_waist.mp4',
    'russian twist with weights':
        'Dumbbell-Russian-Twist-with-Legs-Floor-Off_Waist_.mp4',
    'shoulder press': 'Dumbbell-Standing-Overhead-Press_shoulder.mp4',
    'shrugs': 'Dumbbell-Shrug_Back-FIX_.mp4',
    'sit ups': 'Sit-up-with-Chair-Assisted_Waist.mp4',
    'squats': 'Wide-Air-Squat_Hips_.mp4',
    'standing calf raises': 'Dumbbell-Standing-Calf-Raise_Calves-FIX_.mp4',
    'tricep extension':
        'Dumbbell-Standing-Triceps-Extension_Upper-Arms-FIX.mp4',
    'tricep kickbacks': 'Dumbbell-Kickback_Upper-Arms.mp4',
    'weighted leg raises': 'Leg-Raise-Hip-Lift-with-Head-up_Waist.mp4',
    'weighted russian twists':
        'Dumbbell-Russian-Twist-with-Legs-Floor-Off_Waist_.mp4',
    'weighted sit ups': 'Dumbbell-Sit-up_Waist_.mp4',
    'wide press ups': 'Wide-Hand-Push-up_Chest.mp4',
    'wipers': 'Wipers-(straight-leg)_Waist-FIX_.mp4',
  };

  Future<Map<String, dynamic>> loadActiveProgram() async {
    final plan = await _loadPlan();
    final weeks = (plan['weeks'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final totalWorkouts = weeks.fold<int>(
      0,
      (total, week) => total + ((week['days'] as List?)?.length ?? 0),
    );

    return {
      'programName': plan['planName'] ?? 'Best-U 8 Week Workout Plan',
      'completedCount': 0,
      'totalWorkouts': totalWorkouts,
      'progressPercentage': 0,
      'weeks': weeks.map((week) {
        final weekNumber = week['week'] as int? ?? 0;
        final days = (week['days'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        return {
          'weekNum': weekNumber,
          'status': '0/${days.length} workouts',
          'isCompleted': false,
          'isCurrent': weekNumber == 1,
          'isLocked': weekNumber > 1,
          'days': days.map((day) {
            final dayNumber = day['day'] as int? ?? 0;
            return {
              'workoutId': _localWorkoutId(weekNumber, dayNumber),
              'title': 'Day $dayNumber',
              'type': day['title'] ?? 'Workout',
              'isCompleted': false,
              'isCurrent': weekNumber == 1 && dayNumber == 1,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>?> loadWorkout(String workoutId) async {
    final match = RegExp(r'^local_w(\d+)_d(\d+)$').firstMatch(workoutId);
    if (match == null) return null;

    final weekNumber = int.tryParse(match.group(1) ?? '');
    final dayNumber = int.tryParse(match.group(2) ?? '');
    if (weekNumber == null || dayNumber == null) return null;

    final plan = await _loadPlan();
    final week = (plan['weeks'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['week'] == weekNumber,
          orElse: () => null,
        );
    final day = (week?['days'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['day'] == dayNumber,
          orElse: () => null,
        );

    if (day == null) return null;

    final exercises = (day['exercises'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_mapExercise)
        .toList();

    return {
      'id': workoutId,
      'title': day['title'] ?? 'Workout',
      'name': day['title'] ?? 'Workout',
      'weekNumber': weekNumber,
      'dayNumber': dayNumber,
      'day': dayNumber,
      'type': day['title'] ?? 'Workout',
      'description': _descriptionFor(day, weekNumber, exercises.length),
      'estimatedDurationMinutes': _estimateDuration(exercises.length),
      'durationMinutes': _estimateDuration(exercises.length),
      'exercises': exercises,
    };
  }

  Future<Map<String, dynamic>> _loadPlan() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Map<String, dynamic> attachLocalVideo(Map<String, dynamic> exercise) {
    final videoFile = _videoFileFor(exercise['name']?.toString() ?? '');
    if (videoFile == null) return exercise;

    return {
      ...exercise,
      'videoUrl': _videoUrlFor(videoFile),
      'videoName': _videoNameFor(videoFile, exercise['name']?.toString() ?? ''),
    };
  }

  Map<String, dynamic> _mapExercise(Map<String, dynamic> exercise) {
    final setItems = (exercise['sets'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final targets = setItems.map(_parseSetInstruction).toList();
    final instructions = setItems
        .map((set) => 'Set ${set['set']}: ${set['instruction']}')
        .join('\n');
    final repsTargets = targets
        .map((target) => target.reps)
        .whereType<_InstructionRange>()
        .toList();
    final weightTargets = targets
        .map((target) => target.weightKg)
        .whereType<_InstructionRange>()
        .toList();
    final durationTargets = targets
        .map((target) => target.durationSeconds)
        .whereType<_InstructionRange>()
        .toList();

    final videoFile = _videoFileFor(exercise['name']?.toString() ?? '');
    final repsText = _formatInstructionRanges(repsTargets);
    final durationText = _formatInstructionRanges(durationTargets);

    return {
      'name': exercise['name'] ?? 'Exercise',
      'sets': setItems.length,
      'reps': repsText.isNotEmpty ? repsText : 'See instructions',
      'durationSeconds': durationText.isNotEmpty ? durationText : null,
      'targetReps': null,
      'previousReps': null,
      'targetWeight': null,
      'previousWeight': null,
      'targetDurationSeconds': null,
      'previousDurationSeconds': null,
      'hasWeightTarget': weightTargets.isNotEmpty,
      'type': 'Strength',
      'instructions': instructions,
      'setDetails': setItems
          .map((set) {
            final instruction = set['instruction']?.toString() ?? '';
            final target = _parseSetInstruction(set);
            return {
              'set': set['set'],
              'instruction': instruction,
              'goal': instruction,
              'targetReps': target.reps == null ? null : _formatRange(target.reps!),
              'targetWeight': target.weightKg == null
                  ? null
                  : '${_formatRange(target.weightKg!)} kg',
              'targetDuration': target.durationSeconds == null
                  ? null
                  : '${_formatRange(target.durationSeconds!)} sec',
              'hasWeightTarget': target.weightKg != null,
            };
          })
          .toList(),
      'setInstructions':
          setItems.map((set) => set['instruction']?.toString() ?? '').toList(),
      'videoUrl': _videoUrlFor(videoFile),
      'videoName': _videoNameFor(videoFile, exercise['name']?.toString() ?? ''),
    };
  }

  _ParsedInstruction _parseSetInstruction(Map<String, dynamic> set) {
    final instruction = set['instruction']?.toString() ?? '';
    final reps = _extractRange(
          instruction,
          RegExp(r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?\s*(?:x\s*)?reps?',
              caseSensitive: false),
        ) ??
        _extractRange(
          instruction,
          RegExp(r'^(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?\s*x',
              caseSensitive: false),
        );

    return _ParsedInstruction(
      reps: reps,
      weightKg: _extractRange(
          instruction,
          RegExp(r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?\s*kg',
              caseSensitive: false)),
      durationSeconds: _extractRange(
          instruction,
          RegExp(r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?\s*sec',
              caseSensitive: false)),
    );
  }

  _InstructionRange? _extractRange(String value, RegExp pattern) {
    final match = pattern.firstMatch(value);
    if (match == null) return null;

    final min = double.tryParse(match.group(1) ?? '');
    if (min == null) return null;

    final max = double.tryParse(match.group(2) ?? '') ?? min;
    return _InstructionRange(min, max);
  }

  String _formatInstructionRanges(List<_InstructionRange> ranges) {
    final values = ranges.map(_formatRange).toSet().toList();
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    return values.join(', ');
  }

  String _formatRange(_InstructionRange range) {
    if (range.min == range.max) return _formatNumber(range.min);
    return '${_formatNumber(range.min)}-${_formatNumber(range.max)}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String? _videoFileFor(String exerciseName) {
    return _exerciseVideos[_normalizeExerciseName(exerciseName)];
  }

  String? _videoUrlFor(String? videoFile) =>
      videoFile == null ? null : '$_exerciseVideoPath/$videoFile';

  String _videoNameFor(String? videoFile, String exerciseName) {
    if (videoFile == null) return exerciseName;
    final withoutExtension =
        videoFile.replaceFirst(RegExp(r'\.(mp4|gif)$'), '');
    return withoutExtension
        .replaceAll(
            RegExp(
                r'_(Chest|Back|Calves|Hips|Shoulders|Thighs|Upper-Arms|Waist|shoulder|waist).*$',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'-?FIX2?$', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\(VERSION-2\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\(version-2\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\(female\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'-?\(male\)', caseSensitive: false), '')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeExerciseName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _descriptionFor(
    Map<String, dynamic> day,
    int weekNumber,
    int exerciseCount,
  ) {
    final focus = day['focus'];
    if (focus is String && focus.trim().isNotEmpty) return focus.trim();
    return 'Week $weekNumber ${day['title'] ?? 'workout'} session with '
        '$exerciseCount exercises. Follow each set instruction and keep form controlled.';
  }

  int _estimateDuration(int exerciseCount) {
    return (exerciseCount * 4).clamp(25, 60).toInt();
  }

  static String _localWorkoutId(int weekNumber, int dayNumber) {
    return 'local_w${weekNumber}_d$dayNumber';
  }
}

class _ParsedInstruction {
  final _InstructionRange? reps;
  final _InstructionRange? weightKg;
  final _InstructionRange? durationSeconds;

  _ParsedInstruction({
    this.reps,
    this.weightKg,
    this.durationSeconds,
  });
}

class _InstructionRange {
  final double min;
  final double max;

  _InstructionRange(this.min, this.max);
}
