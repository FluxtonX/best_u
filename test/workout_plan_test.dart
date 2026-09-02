import 'package:flutter_test/flutter_test.dart';
import 'package:best_u/services/local_workout_plan_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalWorkoutPlanService Tests', () {
    final service = LocalWorkoutPlanService();

    test('Loads beginner 8-week workout plan correctly', () async {
      final program = await service.loadActiveProgram(level: 'beginner');
      expect(program['weeks'], isNotNull);
      final weeks = program['weeks'] as List;
      expect(weeks.length, 8);

      final workout = await service.loadWorkout('local_w1_d1', level: 'beginner');
      expect(workout, isNotNull);
      expect(workout!['exercises'], isNotEmpty);
    });

    test('Loads advanced 8-week workout plan correctly', () async {
      final program = await service.loadActiveProgram(level: 'advanced');
      expect(program['weeks'], isNotNull);
      final weeks = program['weeks'] as List;
      expect(weeks.length, 8);
      expect(program['programName'], contains('Advanced'));

      final workout = await service.loadWorkout('local_w1_d1', level: 'advanced');
      expect(workout, isNotNull);
      expect(workout!['exercises'], isNotEmpty);

      final exercises = workout['exercises'] as List;
      expect(exercises.first['name'], 'Bench Press');
    });
  });
}
