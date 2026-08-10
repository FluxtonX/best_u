import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fasting_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION IDs
//   We reserve a block of IDs per session so we can cancel them individually.
//   Base = sessionId.hashCode & 0xFFFFF  (stay within int32)
//   +0  = 100% completion
//   +1  = 25% milestone
//   +2  = 50% milestone
//   +3  = 75% milestone
//   +4…+23 = 20 hourly hunger-check reminders (Intermediate/Elite)
// ─────────────────────────────────────────────────────────────────────────────

class NutritionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _kActiveSessionKey = 'nutrition_active_session_id';

  StreamController<FastingSession?>? _sessionCtrl;

  NutritionRepository() {
    _sessionCtrl = StreamController.broadcast();
    _initNotifications();
    _restoreActiveSession();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('No authenticated user');
    return u.uid;
  }

  // ── Firestore refs ─────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> get _metaRef =>
      _db.collection('users').doc(_uid).collection('nutrition').doc('meta');

  CollectionReference<Map<String, dynamic>> get _sessionsRef =>
      _metaRef.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _mealsRef =>
      _metaRef.collection('meals');

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _db.collection('users').doc(_uid);

  // ── Session stream ─────────────────────────────────────────────────────────

  Stream<FastingSession?> get sessionStream => _sessionCtrl!.stream;

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Returns a stable base notification-ID for a session (fits in int32).
  int _baseId(String sessionId) => sessionId.hashCode.abs() % 0xFFFFF;

  NotificationDetails get _notifDetails {
    final android = const AndroidNotificationDetails(
      'fasting_channel',
      'Fasting reminders',
      channelDescription: 'Notifications for fasting milestones and reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> _safeZonedSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails,
  ) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint(
          'Exact alarm scheduling failed: $e. Falling back to inexact alarm.');
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (innerErr) {
        debugPrint(
            'Fallback inexact notification scheduling also failed: $innerErr');
      }
    }
  }

  /// Schedule the four milestone notifications for a session.
  /// milestoneKey: '25', '50', '75', '100'
  Future<void> _scheduleMilestoneNotifications(
    String sessionId,
    DateTime startedAt,
    DateTime endsAt,
  ) async {
    final base = _baseId(sessionId);
    final totalSeconds = endsAt.difference(startedAt).inSeconds;

    final milestones = [
      (
        '25',
        1,
        'Quarter-way there! 💪',
        'Keep going — you\'re 25% through your fast.'
      ),
      (
        '50',
        2,
        'Halfway! Great work 🔥',
        'You\'ve hit 50% — the hardest part is behind you.'
      ),
      (
        '75',
        3,
        'Almost there! 🏃',
        '75% done — finish strong, your goal is close.'
      ),
      (
        '100',
        0,
        'Fasting complete 🎉',
        'You\'ve completed your fast — time to eat your first meal!'
      ),
    ];

    for (final (key, offset, title, body) in milestones) {
      final pct = int.parse(key) / 100.0;
      final fireAt =
          startedAt.add(Duration(seconds: (totalSeconds * pct).round()));
      if (fireAt.isBefore(DateTime.now())) continue;
      await _safeZonedSchedule(
        base + offset,
        title,
        body,
        tz.TZDateTime.from(fireAt, tz.local),
        _notifDetails,
      );
    }
  }

  /// Schedule hourly hunger-check reminders for Intermediate (16h) / Elite (20h).
  /// These fire every 90 minutes after the first hour of fasting.
  Future<void> _scheduleHungerCheckReminders(
    String sessionId,
    DateTime startedAt,
    DateTime endsAt,
    int level,
  ) async {
    if (level == 0) return; // Beginner — no hunger-check reminders

    final base = _baseId(sessionId);
    const interval = Duration(minutes: 90);
    final now = DateTime.now();
    var fireAt = startedAt.add(const Duration(hours: 1));
    int idx = 4; // IDs +4 through +23

    while (fireAt.isBefore(endsAt) && idx < 24) {
      if (fireAt.isAfter(now)) {
        await _safeZonedSchedule(
          base + idx,
          'Still going strong? 💧',
          'Remember: water and black coffee are allowed during your fast.',
          tz.TZDateTime.from(fireAt, tz.local),
          _notifDetails,
        );
      }
      fireAt = fireAt.add(interval);
      idx++;
    }
  }

  /// Cancel all notifications associated with a session (0 through 23).
  Future<void> cancelAllSessionNotifications(String sessionId) async {
    final base = _baseId(sessionId);
    for (int i = 0; i < 24; i++) {
      try {
        await _notifications.cancel(base + i);
      } catch (_) {}
    }
  }

  // ── Restore persisted session ──────────────────────────────────────────────

  Future<void> _restoreActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_kActiveSessionKey);
      if (id == null) {
        _sessionCtrl?.add(null);
        return;
      }
      final doc = await _sessionsRef.doc(id).get();
      if (!doc.exists) {
        await prefs.remove(_kActiveSessionKey);
        _sessionCtrl?.add(null);
        return;
      }
      final session = FastingSession.fromDoc(doc);
      _sessionCtrl?.add(session);
      // Live listener for remote changes
      _sessionsRef.doc(id).snapshots().listen((snap) {
        _sessionCtrl?.add(FastingSession.fromDoc(snap));
      });
    } catch (e) {
      debugPrint('Restore session error: $e');
      _sessionCtrl?.add(null);
    }
  }

  // ── Session lifecycle ──────────────────────────────────────────────────────

  /// Start a new fasting session.
  /// level: 0=Beginner (12h), 1=Intermediate (16h), 2=Elite (20h)
  Future<FastingSession> startSession({
    required Duration duration,
    int level = 0,
    Map<String, dynamic>? meta,
  }) async {
    final now = DateTime.now();
    final endsAt = now.add(duration);

    final doc = await _sessionsRef.add({
      'startedAt': Timestamp.fromDate(now),
      'endsAt': Timestamp.fromDate(endsAt),
      'status': 'active',
      'level': level,
      'dayComplete': false,
      'mealLogged': false,
      'yesNoResponse': null,
      'remindersFired': <String>[],
      'meta': meta ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final session = FastingSession(
      id: doc.id,
      startedAt: now,
      endsAt: endsAt,
      status: 'active',
      level: level,
      meta: meta,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveSessionKey, doc.id);

    // Persist level on meta doc
    await _metaRef.set({'level': level}, SetOptions(merge: true));

    // Push to stream and start live listener
    _sessionCtrl?.add(session);
    _sessionsRef.doc(doc.id).snapshots().listen((snap) {
      _sessionCtrl?.add(FastingSession.fromDoc(snap));
    });

    // Schedule all milestone + hunger-check notifications
    await _scheduleMilestoneNotifications(doc.id, now, endsAt);
    await _scheduleHungerCheckReminders(doc.id, now, endsAt, level);

    return session;
  }

  Future<void> pauseSession(String sessionId) async {
    final now = DateTime.now();
    await _sessionsRef.doc(sessionId).set({
      'status': 'paused',
      'pausedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await cancelAllSessionNotifications(sessionId);
  }

  Future<void> resumeSession(String sessionId) async {
    final doc = await _sessionsRef.doc(sessionId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final pausedTs = data['pausedAt'] as Timestamp?;
    final endsTs = data['endsAt'] as Timestamp?;
    final startedTs = data['startedAt'] as Timestamp?;
    final level = (data['level'] as int?) ?? 0;

    if (pausedTs == null || endsTs == null || startedTs == null) {
      await _sessionsRef
          .doc(sessionId)
          .set({'status': 'active'}, SetOptions(merge: true));
      return;
    }

    final pausedAt = pausedTs.toDate();
    final endsAt = endsTs.toDate();
    final startedAt = startedTs.toDate();
    final pausedDuration = DateTime.now().difference(pausedAt);
    final newEnds = endsAt.add(pausedDuration);
    final newStart =
        startedAt.add(pausedDuration); // shift for accurate milestones

    await _sessionsRef.doc(sessionId).set({
      'status': 'active',
      'pausedAt': null,
      'endsAt': Timestamp.fromDate(newEnds),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Re-schedule notifications from the shifted start
    await _scheduleMilestoneNotifications(sessionId, newStart, newEnds);
    await _scheduleHungerCheckReminders(sessionId, newStart, newEnds, level);
  }

  Future<void> completeSession(String sessionId) async {
    final now = DateTime.now();
    await _sessionsRef.doc(sessionId).set({
      'status': 'completed',
      'endedAt': Timestamp.fromDate(now),
      'dayComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_kActiveSessionKey);
    if (current == sessionId) await prefs.remove(_kActiveSessionKey);

    await cancelAllSessionNotifications(sessionId);
  }

  /// Marks dayComplete=true without ending the session (milestone popup gating).
  Future<void> markDayComplete(String sessionId) async {
    await _sessionsRef.doc(sessionId).set({
      'dayComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── YES / NO response ──────────────────────────────────────────────────────

  /// Save the user's answer to the mid-fast "Have you eaten yet?" prompt.
  /// response: 'yes' | 'no'
  Future<void> saveYesNoResponse(String sessionId, String response) async {
    await _sessionsRef.doc(sessionId).set({
      'yesNoResponse': response,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (response == 'yes') {
      // User broke the fast early — mark as completed
      await completeSession(sessionId);
    }
  }

  // ── Reminder milestone tracking ────────────────────────────────────────────

  /// Mark a milestone key (e.g. '25', '50') as already fired in Firestore
  /// so it is not triggered again after app restart.
  Future<void> markReminderFired(String sessionId, String key) async {
    await _sessionsRef.doc(sessionId).set({
      'remindersFired': FieldValue.arrayUnion([key]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Meal completion ────────────────────────────────────────────────────────

  Future<void> saveMealCompletion({
    required String sessionId,
    required String mealType,
    Map<String, dynamic>? meta,
  }) async {
    final now = DateTime.now();
    await _mealsRef.add({
      'sessionId': sessionId,
      'mealType': mealType,
      'meta': meta ?? {},
      'completedAt': Timestamp.fromDate(now),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mark session as meal-logged
    await _sessionsRef.doc(sessionId).set({
      'mealLogged': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Weight / goal ──────────────────────────────────────────────────────────

  /// Save current weight and goal weight to the user's Firestore profile.
  Future<void> saveUserWeightGoal({
    required double currentWeight,
    required double goalWeight,
  }) async {
    await _profileRef.set({
      'weight': currentWeight,
      'targetWeight': goalWeight,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Load current & goal weight from the user's Firestore profile.
  Future<Map<String, double>> loadUserWeightGoal() async {
    try {
      final doc = await _profileRef.get();
      final d = doc.data() ?? {};
      final current = (d['weight'] as num?)?.toDouble() ?? 0.0;
      final goal = (d['targetWeight'] as num?)?.toDouble() ?? 0.0;
      return {'currentWeight': current, 'goalWeight': goal};
    } catch (_) {
      return {'currentWeight': 0.0, 'goalWeight': 0.0};
    }
  }

  // ── Level preference ───────────────────────────────────────────────────────

  Future<int> getSavedLevel() async {
    try {
      final doc = await _metaRef.get();
      return (doc.data()?['level'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveLevel(int level) async {
    await _metaRef.set({'level': level}, SetOptions(merge: true));
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Returns the rich analytics map used by the Analytics tab and Coach tab.
  Future<Map<String, dynamic>> getNutritionAnalytics() async {
    final sessionsSnap = await _sessionsRef.get();
    final mealsSnap = await _mealsRef.get();

    final sessions = sessionsSnap.docs.map((d) => d.data()).toList();
    final meals = mealsSnap.docs.map((d) => d.data()).toList();

    // ── Completion stats ──────────────────────────────────────────────────
    double totalFastingHours = 0.0;
    int completed = 0;
    for (final s in sessions) {
      final started = (s['startedAt'] as Timestamp?)?.toDate();
      final ended = (s['endedAt'] as Timestamp?)?.toDate() ??
          (s['endsAt'] as Timestamp?)?.toDate();
      if (started != null && ended != null) {
        totalFastingHours += ended.difference(started).inMinutes / 60.0;
      }
      if ((s['status'] ?? '') == 'completed') completed++;
    }
    final completionPct = sessions.isEmpty
        ? 0.0
        : double.parse(
            ((completed / sessions.length) * 100.0).toStringAsFixed(1));

    // ── Streak ────────────────────────────────────────────────────────────
    final completedSessions = sessions
        .where((s) => s['status'] == 'completed')
        .toList()
      ..sort((a, b) {
        final at = (a['startedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bt = (b['startedAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bt.compareTo(at);
      });

    int streak = 0;
    DateTime? lastDay;
    for (final s in completedSessions) {
      final dt = (s['startedAt'] as Timestamp?)?.toDate();
      if (dt == null) break;
      final d = DateTime(dt.year, dt.month, dt.day);
      if (lastDay == null) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        if (d == todayDate ||
            d == todayDate.subtract(const Duration(days: 1))) {
          streak = 1;
          lastDay = d;
        } else {
          break;
        }
      } else {
        if (lastDay.difference(d).inDays == 1) {
          streak++;
          lastDay = d;
        } else if (d == lastDay) {
          continue;
        } else {
          break;
        }
      }
    }

    // ── 7-day fasting hours ───────────────────────────────────────────────
    final now = DateTime.now();
    final List<double> weeklyHours = List.filled(7, 0.0);
    for (final s in sessions) {
      final started = (s['startedAt'] as Timestamp?)?.toDate();
      final ended = (s['endedAt'] as Timestamp?)?.toDate() ??
          (s['endsAt'] as Timestamp?)?.toDate();
      if (started == null || ended == null) continue;
      final daysAgo = now
          .difference(DateTime(started.year, started.month, started.day))
          .inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        weeklyHours[6 - daysAgo] += ended.difference(started).inMinutes / 60.0;
      }
    }

    // ── Weekly consistency ────────────────────────────────────────────────
    final List<bool> weeklyConsistency = List.filled(7, false);
    for (final s in sessions) {
      if (s['status'] != 'completed') continue;
      final started = (s['startedAt'] as Timestamp?)?.toDate();
      if (started == null) continue;
      final daysAgo = now
          .difference(DateTime(started.year, started.month, started.day))
          .inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        weeklyConsistency[6 - daysAgo] = true;
      }
    }

    // ── Longest fast ──────────────────────────────────────────────────────
    double longestFastH = 0.0;
    for (final s in sessions) {
      final started = (s['startedAt'] as Timestamp?)?.toDate();
      final ended = (s['endedAt'] as Timestamp?)?.toDate() ??
          (s['endsAt'] as Timestamp?)?.toDate();
      if (started != null && ended != null) {
        final h = ended.difference(started).inMinutes / 60.0;
        if (h > longestFastH) longestFastH = h;
      }
    }

    return {
      'totalFastingHours': double.parse(totalFastingHours.toStringAsFixed(1)),
      'sessionsCount': sessions.length,
      'mealsCount': meals.length,
      'completionPct': completionPct,
      'streak': streak,
      'weeklyHours': weeklyHours,
      'weeklyConsistency': weeklyConsistency,
      'longestFastH': double.parse(longestFastH.toStringAsFixed(1)),
      'avgFastH': sessions.isEmpty
          ? 0.0
          : double.parse(
              (totalFastingHours / sessions.length).toStringAsFixed(1)),
    };
  }

  // ── Coach message ──────────────────────────────────────────────────────────

  Future<String> generateCoachMessage() async {
    final analytics = await getNutritionAnalytics();
    final pct = (analytics['completionPct'] as double?) ?? 0.0;
    final hours = (analytics['totalFastingHours'] as double?) ?? 0.0;
    final streak = (analytics['streak'] as int?) ?? 0;
    final sessionsCount = (analytics['sessionsCount'] as int?) ?? 0;

    if (streak >= 7 && pct > 80) {
      return "You're on fire — ${streak}-day streak! Keep the momentum!";
    }
    if (pct > 80 && hours > 30) {
      return "Outstanding work — your consistency is paying off. Stay the course.";
    }
    if (streak >= 3) {
      return "${streak}-day streak! Good consistency — focus on sustainable progress.";
    }
    if (pct > 50) {
      return "Good consistency — focus on sustainable progress. You've got this!";
    }
    if (sessionsCount == 0) {
      return "Start your first fast today — every journey begins with a single step.";
    }
    return "Try to hit one more fast this week — small wins add up.";
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _sessionCtrl?.close();
  }
}
