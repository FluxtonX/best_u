class WorkoutSession {
  final String id;
  final String title;
  final String? weekInfo;
  final List<Exercise> exercises;
  final DateTime startTime;
  DateTime? endTime;

  WorkoutSession({
    required this.id,
    required this.title,
    this.weekInfo,
    required this.exercises,
    required this.startTime,
    this.endTime,
  });

  int get totalVolume {
    int volume = 0;
    for (var exercise in exercises) {
      volume += exercise.totalVolume;
    }
    return volume;
  }

  int get completedExercisesCount {
    return exercises.where((e) => e.isCompleted).length;
  }
}

class Exercise {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? imagePath;
  final List<WorkoutSet> sets;
  bool isCompleted;

  Exercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.imagePath,
    required this.sets,
    this.isCompleted = false,
  });

  int get totalVolume {
    int volume = 0;
    for (var set in sets) {
      if (set.isCompleted) {
        volume += (set.weight * set.reps).toInt();
      }
    }
    return volume;
  }
}

class WorkoutSet {
  double weight;
  int reps;
  bool isCompleted;
  final double? lastWeight;
  final int? lastReps;
  final double? targetWeight;
  final int? targetReps;

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.lastWeight,
    this.lastReps,
    this.targetWeight,
    this.targetReps,
  });
}
