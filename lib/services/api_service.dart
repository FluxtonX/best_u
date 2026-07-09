import 'dart:convert';

import 'package:best_u/services/local_workout_plan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ApiResponse {
  final int statusCode;
  final String body;

  const ApiResponse(this.statusCode, this.body);
}

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalWorkoutPlanService _localPlan = LocalWorkoutPlanService();

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated Firebase user found.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userRef {
    return _db.collection('users').doc(_currentUser.uid);
  }

  ApiResponse _ok(dynamic data, {int statusCode = 200}) {
    return ApiResponse(
        statusCode,
        jsonEncode({
          'success': true,
          'data': _jsonSafe(data),
        }));
  }

  ApiResponse _message(String message, {int statusCode = 200}) {
    return ApiResponse(
        statusCode,
        jsonEncode({
          'success': statusCode < 400,
          'message': message,
        }));
  }

  dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is DocumentReference) return value.path;
    if (value is List) return value.map(_jsonSafe).toList();
    if (value is Map) {
      return value
          .map((key, item) => MapEntry(key.toString(), _jsonSafe(item)));
    }
    return value;
  }

  Future<Map<String, dynamic>> _ensureProfile() async {
    final user = _currentUser;
    final snapshot = await _userRef.get();
    if (snapshot.exists) {
      final data = _withProfileAliases(snapshot.data()!);
      return {
        'id': user.uid,
        'firebaseUid': user.uid,
        'email': user.email,
        ...data,
      };
    }

    final profile = {
      'firebaseUid': user.uid,
      'email': user.email ?? '',
      'name': user.displayName ?? 'User',
      'onboardingCompleted': false,
      'streak': 0,
      'weightLost': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _userRef.set(profile, SetOptions(merge: true));

    return {
      'id': user.uid,
      ...profile,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }

  Future<ApiResponse> onboarding(Map<String, dynamic> userData) async {
    final currentWeight = userData['currentWeight'] ?? userData['weight'];
    final goal = userData['goal'] ??
        ((userData['goals'] is List && (userData['goals'] as List).isNotEmpty)
            ? (userData['goals'] as List).first
            : null);

    final profile = {
      ...userData,
      'weight': currentWeight,
      'currentWeight': currentWeight,
      'goal': goal,
      'goals': userData['goals'] ?? [goal ?? 'Weight Loss'],
      'experienceLevel': userData['fitnessLevel'] ?? 'Beginner',
      'onboardingCompleted': true,
      'subscriptionStatus': 'active',
      'currentWeek': 1,
      'currentDay': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _userRef.set(profile, SetOptions(merge: true));
    await _userRef.collection('progress').doc('program').set({
      'currentWeek': 1,
      'currentDay': 1,
      'completedWorkouts': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _ok(await _ensureProfile(), statusCode: 201);
  }

  Future<ApiResponse> getProfile() async {
    return _ok(await _ensureProfile());
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> profileData) async {
    final normalizedData = _withProfileAliases(profileData);
    await _userRef.set({
      ...normalizedData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _ok(await _ensureProfile());
  }

  Map<String, dynamic> _withProfileAliases(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    if (normalized['fitnessLevel'] != null &&
        normalized['experienceLevel'] == null) {
      normalized['experienceLevel'] = normalized['fitnessLevel'];
    }
    if (normalized['experienceLevel'] != null &&
        normalized['fitnessLevel'] == null) {
      normalized['fitnessLevel'] = normalized['experienceLevel'];
    }
    if (normalized['currentWeight'] != null && normalized['weight'] == null) {
      normalized['weight'] = normalized['currentWeight'];
    }
    if (normalized['weight'] != null && normalized['currentWeight'] == null) {
      normalized['currentWeight'] = normalized['weight'];
    }
    if (normalized['goals'] is List &&
        (normalized['goals'] as List).isNotEmpty &&
        normalized['goal'] == null) {
      normalized['goal'] = (normalized['goals'] as List).first;
    }
    if (normalized['goal'] != null && normalized['goals'] == null) {
      normalized['goals'] = [normalized['goal']];
    }
    return normalized;
  }

  Future<ApiResponse> getDashboardSummary() async {
    final profile = await _ensureProfile();
    final programProgress = await _programProgress();
    final currentWeek = programProgress['currentWeek'] ?? 1;
    final currentDay = programProgress['currentDay'] ?? 1;
    final workoutId = _localWorkoutId(currentWeek, currentDay);
    final todayWorkout = await _localPlan.loadWorkout(workoutId);

    // --- Real week stats ---
    final completionsSnapshot =
        await _userRef.collection('workoutCompletions').get();
    final completions =
        completionsSnapshot.docs.map((doc) => doc.data()).toList();

    // Week progress: workouts completed in current Mon–Sun week
    final completedThisWeek = _thisWeekCompletedCount(completions);

    // Weekly streak: how many consecutive past weeks had all 3 days done
    final weeklyStreak = _weeklyStreakCount(completions);

    // Weight progress: difference between first logged weight and latest logged weight.
    // If no logs are present, progress is 0.0 kg.
    final weightLogsSnapshot = await _userRef.collection('weightLogs').get();
    double weightProgress = 0.0;
    if (weightLogsSnapshot.docs.isNotEmpty) {
      final logs = weightLogsSnapshot.docs.map((doc) => doc.data()).toList();
      logs.sort((a, b) {
        final aDate = _dateFrom(a['createdAt']) ?? _dateFrom(a['date']) ?? DateTime.now();
        final bDate = _dateFrom(b['createdAt']) ?? _dateFrom(b['date']) ?? DateTime.now();
        return aDate.compareTo(bDate);
      });
      final firstWeight = (logs.first['weight'] as num).toDouble();
      final latestWeight = (logs.last['weight'] as num).toDouble();
      weightProgress = double.parse((latestWeight - firstWeight).toStringAsFixed(1));
    }

    // Day-lock: if the most recent completion was today, lock the next workout
    bool isDayLocked = false;
    DateTime? lastCompletedAt;
    for (final c in completions) {
      final date = _dateFrom(c['completedAt']);
      if (date != null &&
          (lastCompletedAt == null || date.isAfter(lastCompletedAt!))) {
        lastCompletedAt = date;
      }
    }
    if (lastCompletedAt != null) {
      final now = DateTime.now();
      isDayLocked = lastCompletedAt!.year == now.year &&
          lastCompletedAt!.month == now.month &&
          lastCompletedAt!.day == now.day;
    }

    return ApiResponse(
        200,
        jsonEncode({
          'success': true,
          'user': {
            'name': profile['name'] ?? 'User',
            'streak': weeklyStreak,
            'weightLost': profile['weightLost'] ?? 0,
          },
          'activeProgram': {
            'name': 'Best-U 8-Week Transformation',
            'currentWeek': currentWeek,
            'totalWeeks': 8,
          },
          'todayWorkout': {
            'id': workoutId,
            'name': todayWorkout?['title'] ?? 'Workout',
            'durationMinutes': todayWorkout?['durationMinutes'] ?? 45,
            'exercisesCount':
                (todayWorkout?['exercises'] as List?)?.length ?? 0,
          },
          'weekStats': {
            'completedThisWeek': completedThisWeek,
            'totalThisWeek': 3,
            'weeklyStreak': weeklyStreak,
            'weightProgress': weightProgress,
            'isDayLocked': isDayLocked,
            'nextDay': currentDay,
            'nextWeek': currentWeek,
          },
        }));
  }

  /// Returns how many workouts were completed in the current Mon–Sun week.
  int _thisWeekCompletedCount(List<Map<String, dynamic>> completions) {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    return completions.where((c) {
      final date = _dateFrom(c['completedAt']);
      if (date == null) return false;
      return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          date.isBefore(weekEnd);
    }).length;
  }

  /// Returns the weekly streak: number of consecutive past weeks
  /// where at least 3 workouts were completed.
  int _weeklyStreakCount(List<Map<String, dynamic>> completions) {
    if (completions.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;

    // Check up to 52 past weeks
    for (int weeksAgo = 1; weeksAgo <= 52; weeksAgo++) {
      final weekOffset = Duration(days: weeksAgo * 7);
      final refDay = now.subtract(weekOffset);
      final monday = refDay.subtract(Duration(days: refDay.weekday - 1));
      final weekStart = DateTime(monday.year, monday.month, monday.day);
      final weekEnd = weekStart.add(const Duration(days: 7));

      final count = completions.where((c) {
        final date = _dateFrom(c['completedAt']);
        if (date == null) return false;
        return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            date.isBefore(weekEnd);
      }).length;

      if (count >= 3) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    return streak;
  }

  Future<ApiResponse> getDailyQuote() async {
    return _ok({
      'quote': "The only bad workout is the one that didn't happen.",
      'author': 'Best-U',
    });
  }

  Future<ApiResponse> getPrograms({int page = 1, int limit = 10}) async {
    final activeProgram = await _localPlan.loadActiveProgram();
    return _ok([activeProgram]);
  }

  Future<ApiResponse> getActiveProgram() async {
    final program = await _localPlan.loadActiveProgram();
    final progress = await _programProgress();
    final completedIds = (progress['completedWorkouts'] as List? ?? [])
        .map((id) => '$id')
        .toSet();

    // Fetch completion timestamps so plan screen can detect same-day locks
    final completionsSnapshot =
        await _userRef.collection('workoutCompletions').get();
    final completionDates = <String, DateTime>{};
    for (final doc in completionsSnapshot.docs) {
      final data = doc.data();
      final workoutId = data['workoutId']?.toString();
      final date = _dateFrom(data['completedAt']);
      if (workoutId != null && date != null) {
        completionDates[workoutId] = date;
      }
    }

    int completedCount = 0;

    final weeks = (program['weeks'] as List).map((week) {
      final mappedWeek = Map<String, dynamic>.from(week as Map);
      final days = (mappedWeek['days'] as List).map((day) {
        final mappedDay = Map<String, dynamic>.from(day as Map);
        final workoutId = mappedDay['workoutId']?.toString();
        final isCompleted =
            workoutId != null && completedIds.contains(workoutId);
        if (isCompleted) completedCount++;
        return {
          ...mappedDay,
          'isCompleted': isCompleted,
          'completedAt': workoutId != null
              ? completionDates[workoutId]?.toIso8601String()
              : null,
          'isCurrent': workoutId ==
              _localWorkoutId(
                progress['currentWeek'] ?? 1,
                progress['currentDay'] ?? 1,
              ),
        };
      }).toList();
      final weekCompletedCount =
          days.where((day) => day['isCompleted'] == true).length;
      return {
        ...mappedWeek,
        'days': days,
        'status': '$weekCompletedCount/${days.length} workouts',
        'isCompleted': days.isNotEmpty && weekCompletedCount == days.length,
        'isCurrent': mappedWeek['weekNum'] == (progress['currentWeek'] ?? 1),
        'isLocked': mappedWeek['weekNum'] > (progress['currentWeek'] ?? 1),
      };
    }).toList();

    final totalWorkouts = program['totalWorkouts'] ?? 24;
    return _ok({
      ...program,
      'completedCount': completedCount,
      'totalWorkouts': totalWorkouts,
      'progressPercentage':
          totalWorkouts == 0 ? 0 : (completedCount / totalWorkouts) * 100,
      'weeks': weeks,
    });
  }

  Future<ApiResponse> getWorkoutDetails(String id) async {
    final workout = await _localPlan.loadWorkout(id);
    if (workout == null) {
      return _message('Workout not found', statusCode: 404);
    }
    return _ok(workout);
  }

  Future<ApiResponse> completeWorkout(
      String id, int timeTakenMinutes, int volumeLifted) async {
    final completedAt = DateTime.now();
    await _userRef.collection('workoutCompletions').doc(id).set({
      'workoutId': id,
      'timeTakenMinutes': timeTakenMinutes,
      'volumeLifted': volumeLifted,
      'completedAt': completedAt,
    }, SetOptions(merge: true));

    final progress = await _programProgress();
    final completedWorkouts = (progress['completedWorkouts'] as List? ?? [])
        .map((id) => '$id')
        .toSet()
      ..add(id);
    final next = _nextWorkoutPosition(id);

    await _userRef.collection('progress').doc('program').set({
      'completedWorkouts': completedWorkouts.toList(),
      'currentWeek': next.$1,
      'currentDay': next.$2,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Recalculate and persist the weekly streak on the user profile
    final allCompletionsSnapshot =
        await _userRef.collection('workoutCompletions').get();
    final allCompletions =
        allCompletionsSnapshot.docs.map((doc) => doc.data()).toList();
    final newStreak = _weeklyStreakCount(allCompletions);
    await _userRef.set({
      'streak': newStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return _ok({
      'workoutId': id,
      'completedAt': completedAt,
      'currentWeek': next.$1,
      'currentDay': next.$2,
      'weeklyStreak': newStreak,
    });
  }

  Future<ApiResponse> logSet(Map<String, dynamic> setData) async {
    final doc = await _userRef.collection('exerciseLogs').add({
      ...setData,
      'loggedAt': FieldValue.serverTimestamp(),
    });
    return _ok({'id': doc.id, ...setData}, statusCode: 201);
  }

  /// Returns the most recent logged result for a specific exercise + set number.
  /// Returns null if no previous log found.
  Future<Map<String, dynamic>?> getLastResultForExercise(
      String exerciseName, int setNumber) async {
    try {
      final snapshot = await _userRef
          .collection('exerciseLogs')
          .where('exerciseName', isEqualTo: exerciseName)
          .where('setNumber', isEqualTo: setNumber)
          .orderBy('loggedAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      return {
        'reps': (data['reps'] as num?)?.toInt() ?? 0,
        'weight': (data['weight'] as num?)?.toDouble() ?? 0.0,
        'loggedAt': _dateFrom(data['loggedAt'])?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('getLastResultForExercise error: $e');
      return null;
    }
  }

  /// Batch fetches last results for multiple exercises (all set numbers combined).
  /// Returns a map of exerciseName -> list of {setNumber, reps, weight}.
  Future<Map<String, List<Map<String, dynamic>>>> getLastResultsForExercises(
      List<String> exerciseNames) async {
    final result = <String, List<Map<String, dynamic>>>{};
    if (exerciseNames.isEmpty) return result;
    try {
      final snapshot = await _userRef
          .collection('exerciseLogs')
          .where('exerciseName', whereIn: exerciseNames.take(10).toList())
          .orderBy('loggedAt', descending: true)
          .limit(200)
          .get();

      // Group by exercise name, keeping only the most recent per set number
      final seen = <String, Set<int>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['exerciseName']?.toString();
        if (name == null) continue;
        final setNum = (data['setNumber'] as num?)?.toInt() ?? 1;
        seen[name] ??= {};
        if (seen[name]!.contains(setNum)) continue;
        seen[name]!.add(setNum);
        result[name] ??= [];
        result[name]!.add({
          'setNumber': setNum,
          'reps': (data['reps'] as num?)?.toInt() ?? 0,
          'weight': (data['weight'] as num?)?.toDouble() ?? 0.0,
        });
      }
    } catch (e) {
      debugPrint('getLastResultsForExercises error: $e');
    }
    return result;
  }

  Future<ApiResponse> getProgressSummary() async {
    final profile = await _ensureProfile();
    final completionsSnapshot =
        await _userRef.collection('workoutCompletions').get();
    final exerciseLogsSnapshot =
        await _userRef.collection('exerciseLogs').get();
    final weightHistory = await _weightHistoryData();

    final completions =
        completionsSnapshot.docs.map((doc) => doc.data()).toList();
    final exerciseLogs =
        exerciseLogsSnapshot.docs.map((doc) => doc.data()).toList();
    final totalWorkoutMinutes = completions.fold<int>(
      0,
      (total, item) =>
          total + ((item['timeTakenMinutes'] as num?)?.toInt() ?? 0),
    );
    final completedThisWeek = completions.where((item) {
      final date = _dateFrom(item['completedAt']);
      if (date == null) return false;
      return DateTime.now().difference(date).inDays < 7;
    }).length;
    final avgTime = completions.isEmpty
        ? (profile['avgTime'] ?? 0)
        : totalWorkoutMinutes / completions.length;
    final firstWeight =
        weightHistory.isNotEmpty ? (weightHistory.first['value'] as num) : null;
    final lastWeight =
        weightHistory.isNotEmpty ? (weightHistory.last['value'] as num) : null;
    final weightTrend = firstWeight != null && lastWeight != null
        ? lastWeight - firstWeight
        : 0;

    return _ok({
      'totalWorkoutMinutes': totalWorkoutMinutes == 0
          ? (profile['totalWorkoutMinutes'] ?? 0)
          : totalWorkoutMinutes,
      'workoutIncreasePercent': completedThisWeek,
      'weightLost': weightTrend.abs(),
      'weightTrend': weightTrend,
      'proteinPercentage': profile['proteinPercentage'] ?? 12,
      'completionRate': completions.isEmpty
          ? (profile['completionRate'] ?? 0)
          : ((completedThisWeek / 6) * 100).clamp(0, 100).round(),
      'avgTime': double.parse((avgTime as num).toStringAsFixed(1)),
      'totalCalories': totalWorkoutMinutes == 0
          ? (profile['totalCalories'] ?? 0)
          : totalWorkoutMinutes * 7,
      'heartRate': profile['heartRate'] ?? 142,
      'completedThisWeek': completedThisWeek,
      'totalThisWeek': 6,
      'weeklyWorkouts': _weeklyWorkoutData(completions),
      'strengthLevels': _strengthLevelData(exerciseLogs),
    });
  }

  Future<ApiResponse> logWeight(double weight, String date) async {
    await _userRef.collection('weightLogs').add({
      'weight': weight,
      'date': date,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await updateProfile({'weight': weight});
    return _ok({'weight': weight, 'date': date}, statusCode: 201);
  }

  Future<ApiResponse> getWeightHistory() async {
    return _ok(await _weightHistoryData());
  }

  Future<ApiResponse> getPersonalBests() async {
    final explicitSnapshot = await _userRef.collection('personalBests').get();
    if (explicitSnapshot.docs.isNotEmpty) {
      return _ok(explicitSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
    }

    final logsSnapshot = await _userRef.collection('exerciseLogs').get();
    final bestByExercise = <String, Map<String, dynamic>>{};
    for (final doc in logsSnapshot.docs) {
      final data = doc.data();
      final exerciseName = data['exerciseName']?.toString();
      if (exerciseName == null || exerciseName.isEmpty) continue;
      final weight = (data['weight'] as num?)?.toDouble() ?? 0;
      final current = bestByExercise[exerciseName];
      final currentWeight = (current?['rawWeight'] as num?)?.toDouble() ?? -1;
      if (weight >= currentWeight) {
        bestByExercise[exerciseName] = {
          'exercise': exerciseName,
          'value': weight > 0 ? '${weight.toStringAsFixed(1)} kg' : '--',
          'rawWeight': weight,
          'date': _displayDate(_dateFrom(data['loggedAt']) ?? DateTime.now()),
          'rating': weight > 0 ? 4 : 3,
        };
      }
    }

    final bests = bestByExercise.values.toList();
    if (bests.isEmpty) {
      return _ok([
        {
          'exercise': 'Bench Press',
          'value': '--',
          'date': _displayDate(DateTime.now()),
          'rating': 3,
        },
      ]);
    }
    return _ok(bests);
  }

  Future<ApiResponse> getStrengthLevels() async {
    final explicitSnapshot = await _userRef.collection('strengthLevels').get();
    if (explicitSnapshot.docs.isNotEmpty) {
      return _ok(explicitSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList());
    }
    final logsSnapshot = await _userRef.collection('exerciseLogs').get();
    return _ok(_strengthLevelData(
        logsSnapshot.docs.map((doc) => doc.data()).toList()));
  }

  Future<ApiResponse> getSubscriptionStatus() async {
    final profile = await _ensureProfile();
    // paymentProcessed is only set to true when the user completes the
    // in-app payment sheet — NOT during onboarding.
    final paymentProcessed = profile['paymentProcessed'] == true;
    final priceId = profile['selectedPriceId'] as String?;
    return _ok({
      'status': paymentProcessed ? 'active' : 'inactive',
      'isActive': paymentProcessed,
      'priceId': paymentProcessed ? priceId : null,
    });
  }

  Future<ApiResponse> checkout(String priceId) async {
    await _userRef.set({
      'subscriptionStatus': 'active',
      'selectedPriceId': priceId,
      'paymentProcessed': true, // only set via real payment sheet
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return _ok({'status': 'active', 'priceId': priceId});
  }

  Future<ApiResponse> getPortalSession() async {
    return _ok({'status': 'active'});
  }

  Future<Map<String, dynamic>> _programProgress() async {
    final snapshot = await _userRef.collection('progress').doc('program').get();
    if (snapshot.exists) {
      return snapshot.data()!;
    }

    final initial = {
      'currentWeek': 1,
      'currentDay': 1,
      'completedWorkouts': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _userRef.collection('progress').doc('program').set(initial);
    return {
      'currentWeek': 1,
      'currentDay': 1,
      'completedWorkouts': <String>[],
    };
  }

  Future<List<Map<String, dynamic>>> _weightHistoryData() async {
    final snapshot = await _userRef.collection('weightLogs').get();
    final rows = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final date = _dateFrom(data['createdAt']) ??
              _dateFrom(data['date']) ??
              DateTime.now();
          return {
            'id': doc.id,
            'day': _dayLabel(date),
            'value': (data['weight'] as num?)?.toDouble() ?? 0,
            'date': date.toIso8601String(),
          };
        })
        .where((item) => (item['value'] as num) > 0)
        .toList()
      ..sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));

    if (rows.isNotEmpty) return rows.take(6).toList();

    final profile = await _ensureProfile();
    final weight = (profile['weight'] as num?)?.toDouble() ??
        (profile['currentWeight'] as num?)?.toDouble() ??
        0;
    if (weight <= 0) return _fallbackWeightHistory();
    return List.generate(5, (index) {
      final date = DateTime.now().subtract(Duration(days: 4 - index));
      return {
        'day': _dayLabel(date),
        'value':
            double.parse((weight + ((4 - index) * 0.2)).toStringAsFixed(1)),
        'date': date.toIso8601String(),
      };
    });
  }

  List<Map<String, dynamic>> _weeklyWorkoutData(
      List<Map<String, dynamic>> completions) {
    return List.generate(6, (index) {
      final date = DateTime.now().subtract(Duration(days: 5 - index));
      final count = completions.where((item) {
        final completedAt = _dateFrom(item['completedAt']);
        return completedAt != null &&
            completedAt.year == date.year &&
            completedAt.month == date.month &&
            completedAt.day == date.day;
      }).length;
      return {
        'day': _dayLabel(date),
        'value': count * 24, // 0 if no workout done that day
        'done': count > 0,
      };
    });
  }

  List<Map<String, dynamic>> _strengthLevelData(
      List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      // No data at all — return 6 zero bars
      return List.generate(6, (index) {
        final date = DateTime.now().subtract(Duration(days: 5 - index));
        return {'day': _dayLabel(date), 'value': 0.0, 'done': false};
      });
    }

    return List.generate(6, (index) {
      final date = DateTime.now().subtract(Duration(days: 5 - index));
      double volume = 0;
      for (final item in logs) {
        final loggedAt = _dateFrom(item['loggedAt']);
        if (loggedAt == null ||
            loggedAt.year != date.year ||
            loggedAt.month != date.month ||
            loggedAt.day != date.day) {
          continue;
        }
        final weight = (item['weight'] as num?)?.toDouble() ?? 0;
        final reps = (item['reps'] as num?)?.toDouble() ?? 0;
        volume += weight * reps;
      }
      return {
        'day': _dayLabel(date),
        'value': volume.clamp(0, 100), // 0 if no exercises logged that day
        'done': volume > 0,
      };
    });
  }

  List<Map<String, dynamic>> _fallbackWeightHistory() {
    const values = [78.4, 77.2, 78.0, 77.4, 78.0];
    return List.generate(values.length, (index) {
      final date =
          DateTime.now().subtract(Duration(days: values.length - 1 - index));
      return {
        'day': _dayLabel(date),
        'value': values[index],
        'date': date.toIso8601String(),
      };
    });
  }

  DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _dayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  (int, int) _nextWorkoutPosition(String workoutId) {
    final match = RegExp(r'^local_w(\d+)_d(\d+)$').firstMatch(workoutId);
    final week = int.tryParse(match?.group(1) ?? '') ?? 1;
    final day = int.tryParse(match?.group(2) ?? '') ?? 1;
    if (day < 3) return (week, day + 1);
    if (week < 8) return (week + 1, 1);
    return (8, 3);
  }

  String _localWorkoutId(int week, int day) => 'local_w${week}_d$day';
}
