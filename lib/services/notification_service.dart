import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:best_u/services/api_service.dart';

/// Singleton notification service for Best-U app.
/// Handles 4 notification types: Welcome, Fasting Completion,
/// Daily Workout Completed, and Weekly Workout Completed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Android channel ────────────────────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'best_u_main_v2',
    'Best-U Notifications',
    description: 'Fitness & fasting milestone notifications for Best-U.',
    importance: Importance.max,
    playSound: true,
    showBadge: true, // Force badge display for the channel
  );

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const int _idWelcome = 1;
  static const int _idFastingComplete = 2;
  static const int _idDailyWorkout = 3;
  static const int _idWeeklyWorkout = 4;

  /// Call once from main() before runApp().
  Future<void> initialize() async {
    if (_initialized) return;

    // Android settings — use the transparent notification icon
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');

    // iOS settings — request all permissions at init time
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    // Create the Android notification channel
    await androidImplementation?.createNotificationChannel(_channel);

    // Request permissions for Android 13+
    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── 1. Welcome Notification ────────────────────────────────────────────────
  /// Fire immediately (or after [delay]) on first sign-up / login.
  Future<void> showWelcomeNotification({
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    await _show(
      id: _idWelcome,
      title: 'Welcome to Best-U! 🚀',
      body:
          'Your transformation journey starts today. Let\'s reach your fitness and fasting goals together!',
      type: 'welcome',
    );
  }

  // ── 2. Fasting Completion Notification ────────────────────────────────────
  /// Fire when the 5 PM fasting goal (Day Complete) is reached.
  Future<void> showFastingCompleteNotification() async {
    await _show(
      id: _idFastingComplete,
      title: 'Fasting Goal Completed! 🏆',
      body:
          'Amazing discipline! You\'ve successfully completed today\'s fast. Time to nourish your body! 🥗',
      type: 'fasting',
    );
  }

  // ── 3. Daily Workout Completed Notification ───────────────────────────────
  /// Fire when the user completes a daily workout session.
  Future<void> showDailyWorkoutCompleteNotification() async {
    await _show(
      id: _idDailyWorkout,
      title: 'Workout Crushed! 🏋️‍♂️',
      body:
          'Day completed! You are one step closer to achieving your weekly fitness targets.',
      type: 'workout_daily',
    );
  }

  // ── 4. Weekly Workout Completed Notification ──────────────────────────────
  /// Fire when the user finishes all required days for the current week.
  Future<void> showWeeklyWorkoutCompleteNotification() async {
    await _show(
      id: _idWeeklyWorkout,
      title: 'Week Completed! 🌟',
      body:
          'You\'ve successfully finished this week\'s workout program! Keep up the momentum for next week.',
      type: 'workout_weekly',
    );
  }

  // ── Internal helper ────────────────────────────────────────────────────────
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String type,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'best_u_main_v2',
      'Best-U Notifications',
      channelDescription:
          'Fitness & fasting milestone notifications for Best-U.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      number: 1, // This triggers the red badge counter on Android launchers
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show local push notification
    await _plugin.show(id, title, body, details);

    // Save to Firebase Firestore
    try {
      final apiService = ApiService();
      await apiService.saveNotification(title: title, body: body, type: type);
    } catch (e) {
      // Ignored: User might not be authenticated yet or network issue
    }
  }
}
