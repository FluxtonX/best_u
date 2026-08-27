import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fasting_session.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/nutrition_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE EVENT ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum NutritionMilestone {
  /// 50 % of the fast window reached
  half,

  /// Fast goal complete
  complete,

  /// Level successfully completed & user promoted to next level
  levelPromoted,

  /// Morning check-in prompt
  morningCheck,
}

// ─────────────────────────────────────────────────────────────────────────────
// NUTRITION VIEW-MODEL
// ─────────────────────────────────────────────────────────────────────────────
/// Central controller for the Nutrition Coach feature.
///
/// The screen creates one instance, subscribes [onMilestone] to show popups,
/// and calls the action methods from button handlers.
/// All persistent state is stored in Firestore via [NutritionRepository].
class NutritionViewModel extends ChangeNotifier {
  // ── Dependencies ────────────────────────────────────────────────────────
  final NutritionRepository _repo;
  final ApiService _api;

  // ── Popup callback (wired by the screen) ────────────────────────────────
  /// Fired when a trackable milestone or level completion is reached.
  void Function(NutritionMilestone milestone,
      {int? completedLevel, int? nextLevel})? onMilestone;

  // ── Session ──────────────────────────────────────────────────────────────
  FastingSession? _activeSession;
  final Map<int, FastingSession> _todaySessions = {};

  /// Returns the active or completed session for the currently selected level.
  /// This ensures completed levels remain completed today and do not restart.
  FastingSession? get activeSession {
    final sessionForLevel = _todaySessions[_selectedLevel];
    if (sessionForLevel != null) return sessionForLevel;
    if (_activeSession != null && _activeSession!.level == _selectedLevel) {
      return _activeSession;
    }
    return null;
  }

  // ── User profile ─────────────────────────────────────────────────────────
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  String get currentWeight => (_profile?['weight'] ?? 82).toString();
  String get targetWeight => (_profile?['targetWeight'] ?? 75).toString();

  // ── Level: 0 = Beginner (12 PM), 1 = Intermediate (2 PM), 2 = Elite (4 PM) ─
  int _selectedLevel = 0;
  int get selectedLevel => _selectedLevel;

  int get endFastHour {
    switch (_selectedLevel) {
      case 0:
        return 12; // Beginner: 12:00 PM
      case 1:
        return 14; // Intermediate: 2:00 PM
      case 2:
        return 16; // Elite: 4:00 PM
      default:
        return 12;
    }
  }

  String get fastGoalTimeText {
    switch (_selectedLevel) {
      case 0:
        return "12 PM";
      case 1:
        return "2 PM";
      case 2:
        return "4 PM";
      default:
        return "12 PM";
    }
  }

  String get levelName {
    switch (_selectedLevel) {
      case 0:
        return "Beginner";
      case 1:
        return "Intermediate";
      case 2:
        return "Elite";
      default:
        return "Beginner";
    }
  }

  /// Target fasting duration in hours based on chosen tier
  int get targetHoursForLevel {
    switch (_selectedLevel) {
      case 0:
        return 12; // Beginner (12h)
      case 1:
        return 14; // Intermediate (14h)
      case 2:
        return 16; // Elite (16h)
      default:
        return 12;
    }
  }

  int get maxTimelineStep {
    switch (_selectedLevel) {
      case 0:
        return 2; // Step 0 (8 AM), Step 1 (10:30 AM), Step 2 (12 PM)
      case 1:
        return 2; // Step 0 (8 AM), Step 1 (11 AM), Step 2 (2 PM)
      case 2:
        return 3; // Step 0 (8 AM), Step 1 (11 AM), Step 2 (2 PM), Step 3 (4 PM)
      default:
        return 2;
    }
  }

  // ── Analytics / coach ────────────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? get analytics => _analytics;

  String _coachMessage =
      'Start your fast today — every journey begins with a single step.';
  String get coachMessage => _coachMessage;

  // ── Meal ─────────────────────────────────────────────────────────────────
  bool get mealLogged => activeSession?.mealLogged ?? false;

  int selectedProtein = 0;
  int selectedFat = 0;

  // ── YES / NO prompt & Deal state ──────────────────────────────────────────
  bool _showYesNoPrompt = true;
  bool get showYesNoPrompt => _showYesNoPrompt;

  bool _answeredYes = false;
  bool get answeredYes => _answeredYes;

  bool _answeredNo = false;
  bool get answeredNo => _answeredNo;

  bool? _dealAccepted;
  bool? get dealAccepted => _dealAccepted;

  int currentTimelineStep = 0;

  // ── Real-Time Clock Step Unlocking ─────────────────────────────────────────
  int getTargetHourForStep(int step) {
    if (_selectedLevel == 0) {
      // Beginner: 8 AM, 10:30 AM, 12 PM
      switch (step) {
        case 0:
          return 8;
        case 1:
          return 10;
        case 2:
          return 12;
        default:
          return 8;
      }
    } else if (_selectedLevel == 1) {
      // Intermediate: 8 AM, 11 AM, 2 PM
      switch (step) {
        case 0:
          return 8;
        case 1:
          return 11;
        case 2:
          return 14;
        default:
          return 8;
      }
    } else {
      // Elite: 8 AM, 11 AM, 2 PM, 4 PM
      switch (step) {
        case 0:
          return 8;
        case 1:
          return 11;
        case 2:
          return 14;
        case 3:
          return 16;
        default:
          return 8;
      }
    }
  }

  String getTargetTimeStringForStep(int step) {
    if (_selectedLevel == 0) {
      switch (step) {
        case 0:
          return "8:00 AM";
        case 1:
          return "10:30 AM";
        case 2:
          return "12:00 PM";
        default:
          return "8:00 AM";
      }
    } else if (_selectedLevel == 1) {
      switch (step) {
        case 0:
          return "8:00 AM";
        case 1:
          return "11:00 AM";
        case 2:
          return "2:00 PM";
        default:
          return "8:00 AM";
      }
    } else {
      switch (step) {
        case 0:
          return "8:00 AM";
        case 1:
          return "11:00 AM";
        case 2:
          return "2:00 PM";
        case 3:
          return "4:00 PM";
        default:
          return "8:00 AM";
      }
    }
  }

  bool isStepUnlocked(int step) {
    if (step == 0) return true; // Step 0 (8 AM) is always unlocked when active
    final now = DateTime.now();
    return now.hour >= getTargetHourForStep(step);
  }

  // ── Front page blurb banner ──────────────────────────────────────────────
  bool _showBlurb = true;
  bool get showBlurb => _showBlurb;
  void toggleBlurb() {
    _showBlurb = !_showBlurb;
    notifyListeners();
  }

  // ── Exact Client Dialogue Texts ──────────────────────────────────────────
  static const String blurbTitle = "Nutrition Coach";
  static const String blurbContent =
      "What this coach will do is track and motivate you daily so you can achieve your weight loss goals. The number one key to weight loss is controlled fasting.\n\n"
      "No-one can go straight to a long fast. It is a step by step, day by day improvement. With this coach we help get you there.\n\n"
      "Consistency over time creates results!";

  String get currentQuestion => "Have you eaten yet?";

  String get currentYesAdvice {
    return "Ok. This is not ideal. The goal is to fast until $fastGoalTimeText. If you get hungry, have a coffee / tea with a small pour of cream or coconut cream. Let's try and do better tomorrow. Deal?";
  }

  String get currentNoMotivation {
    return "Great, keep it up. Remember the goal is to make it to $fastGoalTimeText. If you get hungry, have a coffee / tea with a small pour of cream or coconut cream, it will push the hunger window out for two hours.";
  }

  static const String mealGuidance =
      "Good work on reaching your fasting goal with no food! Remember, for this meal the goal is to eat Protein and Fat:\n\n"
      "• Protein: Around 100 grams of meat / fish / tofu is ideal (~30g of actual protein per meal).\n"
      "• Healthy Fat: Butter, cheese sauce, avocado, or nuts to satisfy hunger completely.\n\n"
      "💡 Tip: The hunger satisfaction with healthy fats is the MOST important part. The plan does not work if you are still hungry. Adding healthy fats makes the fast sustainable and fuels your body.";

  // ── Real-Time Duration & Progress Calculations ───────────────────────────

  /// Total target seconds for current fast (e.g. 12h = 43,200s, 14h = 50,400s, 16h = 57,600s)
  int get totalTargetSeconds {
    final s = activeSession;
    if (s != null && s.endsAt != null) {
      final diff = s.endsAt!.difference(s.startedAt).inSeconds;
      if (diff > 0) return diff;
    }
    return targetHoursForLevel * 3600;
  }

  /// Exact seconds elapsed since fasting started
  int get elapsedSeconds {
    final s = activeSession;
    if (s == null) return 0;
    final now = DateTime.now();
    if (now.isBefore(s.startedAt)) return 0;
    final end =
        (s.status == 'completed' || s.dayComplete) ? (s.endedAt ?? now) : now;
    final elapsed = end.difference(s.startedAt).inSeconds;
    return elapsed >= 0 ? elapsed : 0;
  }

  /// Exact seconds remaining until target duration is fulfilled
  int get remainingSeconds {
    final s = activeSession;
    if (s == null) return totalTargetSeconds;
    if (s.status == 'completed' || s.dayComplete) return 0;
    final total = totalTargetSeconds;
    final elapsed = elapsedSeconds;
    final rem = total - elapsed;
    return rem > 0 ? rem : 0;
  }

  /// Normalized progress from 0.0 to 1.0 (never 1.0 until elapsed >= target)
  double get fastProgress {
    final s = activeSession;
    if (s == null) return 0.0;
    if (s.status == 'completed' || s.dayComplete) return 1.0;
    final total = totalTargetSeconds;
    if (total <= 0) return 0.0;
    return (elapsedSeconds / total).clamp(0.0, 1.0);
  }

  /// Standard Intermittent Fasting progress percentage (0 to 100%)
  /// Formula: min(100, (elapsedSeconds / totalTargetSeconds) * 100)
  int get fastPercent {
    final s = activeSession;
    if (s == null) return 0;
    if (s.status == 'completed' || s.dayComplete) return 100;
    final total = totalTargetSeconds;
    if (total <= 0) return 0;
    final double pct = (elapsedSeconds / total) * 100;
    return pct.clamp(0.0, 100.0).round();
  }

  bool isLevelCompletedToday(int level) {
    final s = _todaySessions[level];
    if (s == null) return false;
    return s.dayComplete || s.status == 'completed';
  }

  String get formattedElapsedTime {
    final sec = elapsedSeconds;
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  String get formattedRemainingTime {
    if (isTodayCompleted) return 'Goal Reached ✓';
    final s = activeSession;
    if (s == null) return 'Ready to start';
    if (s.status == 'completed' || s.dayComplete) return 'Completed';
    final sec = remainingSeconds;
    if (sec <= 0) return 'Goal Reached! 🏆';
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final sc = (sec % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${sc}s left';
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ── Milestone dedup (local + Firestore backed) ───────────────────────────
  bool _ach25Shown = false;
  bool _ach50Shown = false;
  bool _ach100Shown = false;

  // ── Internals ─────────────────────────────────────────────────────────────
  Timer? _ticker;
  StreamSubscription<FastingSession?>? _sessionSub;

  // ─────────────────────────────────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────────────────────────────────
  NutritionViewModel({
    required NutritionRepository repo,
    required ApiService api,
  })  : _repo = repo,
        _api = api {
    _sessionSub = _repo.sessionStream.listen(_onSessionUpdate);
    loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _ticker?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA LOADING
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadData() async {
    try {
      final pRes = await _api.getProfile();
      if (pRes.statusCode == 200) {
        final decoded = json.decode(pRes.body);
        if (decoded is Map && decoded['data'] is Map) {
          _profile = Map<String, dynamic>.from(decoded['data'] as Map);
        }
      }

      _analytics = await _repo.getNutritionAnalytics();
      _coachMessage = await _repo.generateCoachMessage();
      _selectedLevel = await _repo.getSavedLevel();

      final todaySessions = await _repo.getTodaySessions();
      _todaySessions.clear();
      for (final s in todaySessions) {
        _todaySessions[s.level] = s;
      }

      if (_activeSession != null) {
        _todaySessions[_activeSession!.level] = _activeSession!;
        await _loadMilestoneFlags(_activeSession!.id);
        _syncYesNoState();
      }
    } catch (e) {
      debugPrint('NutritionViewModel.loadData error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMilestoneFlags(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    _ach25Shown = prefs.getBool('ach25_$sessionId') ?? false;
    _ach50Shown = prefs.getBool('ach50_$sessionId') ?? false;
    _ach100Shown = prefs.getBool('ach100_$sessionId') ?? false;

    // Also honour flags already written to Firestore
    final fired = _activeSession?.remindersFired ?? [];
    if (fired.contains('25')) _ach25Shown = true;
    if (fired.contains('50')) _ach50Shown = true;
    if (fired.contains('100')) _ach100Shown = true;
  }

  void _syncYesNoState() {
    final resp = _activeSession?.yesNoResponse;
    if (resp == null) return;

    if (resp.startsWith('step_')) {
      final parsedStep = int.tryParse(resp.split('_')[1]);
      if (parsedStep != null) {
        currentTimelineStep = parsedStep;
        _showYesNoPrompt = true;
        _answeredYes = false;
        _answeredNo = false;
      }
    } else if (resp.startsWith('yes_') ||
        resp.startsWith('deal_accepted_') ||
        resp.startsWith('deal_declined_')) {
      final parts = resp.split('_');
      final lastPart = parts.last;
      final parsedStep = int.tryParse(lastPart);
      if (parsedStep != null) currentTimelineStep = parsedStep;
      _answeredYes = true;
      _answeredNo = false;
      _showYesNoPrompt = false;
    } else if (resp.startsWith('no_')) {
      final parts = resp.split('_');
      if (parts.length >= 3) {
        final parsedStep = int.tryParse(parts[2]);
        if (parsedStep != null) currentTimelineStep = parsedStep;
      }
      _answeredNo = true;
      _answeredYes = false;
      _showYesNoPrompt = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION STREAM LISTENER
  // ─────────────────────────────────────────────────────────────────────────
  void _onSessionUpdate(FastingSession? session) {
    _activeSession = session;
    if (session != null) {
      _todaySessions[session.level] = session;
      _syncYesNoState();
    }
    _ensureTicker();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1-SECOND TICKER
  // ─────────────────────────────────────────────────────────────────────────
  void _ensureTicker() {
    _ticker?.cancel();
    if (_activeSession != null && _activeSession!.status == 'active') {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
        _checkMilestones();
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MILESTONE DETECTION & AUTO-COMPLETION
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkMilestones() async {
    final session = _activeSession;
    if (session == null || session.status != 'active') return;
    final progress = fastProgress;

    // 25 % — milestone tracked
    if (progress >= 0.25 && !_ach25Shown) {
      _ach25Shown = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ach25_${session.id}', true);
      await _repo.markReminderFired(session.id, '25');
    }

    // 50 % — milestone tracked
    if (progress >= 0.50 && !_ach50Shown) {
      _ach50Shown = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ach50_${session.id}', true);
      await _repo.markReminderFired(session.id, '50');
    }

    // 100 % — Goal target duration reached!
    if (progress >= 1.0 && !_ach100Shown) {
      _ach100Shown = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ach100_${session.id}', true);
      await _repo.markReminderFired(session.id, '100');
      await completeFast();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Session lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  bool get isTodayCompleted => isLevelCompletedToday(_selectedLevel);

  Future<void> handleMainButton() async {
    if (isTodayCompleted) return;
    final session = activeSession; // level-matched
    if (session == null || session.status == 'completed') {
      await startFast();
    } else if (session.status == 'paused') {
      await resumeFast();
    } else if (session.status == 'active') {
      await completeFast();
    }
  }

  Future<void> startFast() async {
    if (isTodayCompleted) return;
    try {
      final duration = Duration(hours: targetHoursForLevel);

      final session = await _repo.startSession(
        duration: duration,
        level: _selectedLevel,
      );

      _activeSession = session;
      _todaySessions[_selectedLevel] = session;
      _ach25Shown = false;
      _ach50Shown = false;
      _ach100Shown = false;
      _showYesNoPrompt = true;
      _answeredNo = false;
      _answeredYes = false;
      _dealAccepted = null;
      currentTimelineStep = 0;

      _ensureTicker();
      notifyListeners();

      // Trigger morning check phone notification
      NotificationService.instance
          .showMorningCheckNotification(targetTime: fastGoalTimeText);
    } catch (e) {
      debugPrint('NutritionViewModel.startFast error: $e');
    }
  }

  Future<void> pauseFast() async {
    if (_activeSession == null) return;
    try {
      await _repo.pauseSession(_activeSession!.id);
    } catch (e) {
      debugPrint('NutritionViewModel.pauseFast error: $e');
    }
  }

  Future<void> resumeFast() async {
    if (_activeSession == null) return;
    try {
      await _repo.resumeSession(_activeSession!.id);
    } catch (e) {
      debugPrint('NutritionViewModel.resumeFast error: $e');
    }
  }

  Future<void> completeFast() async {
    final session = activeSession; // level-matched guard
    if (session == null) return;
    try {
      final now = DateTime.now();
      await _repo.completeSession(session.id);
      _todaySessions[_selectedLevel] = FastingSession(
        id: session.id,
        startedAt: session.startedAt,
        endsAt: session.endsAt,
        endedAt: now,
        status: 'completed',
        dayComplete: true,
        level: session.level,
        mealLogged: session.mealLogged,
        remindersFired: session.remindersFired,
        yesNoResponse: session.yesNoResponse,
        meta: session.meta,
      );
      _activeSession = null;
      _ticker?.cancel();
      notifyListeners();
      await onFastCompletedForLevel();
      await loadData();
    } catch (e) {
      debugPrint('NutritionViewModel.completeFast error: $e');
    }
  }

  /// Handles level completion and progression to next tier
  Future<void> onFastCompletedForLevel() async {
    final completed = _selectedLevel;
    int nextLevel = completed;

    if (completed == 0) {
      nextLevel = 1; // Intermediate is unlocked
      await NotificationService.instance.showFastingCompleteNotification(
        levelName: 'Beginner',
        targetTime: '12 PM',
        nextLevel: 'Intermediate (2 PM)',
      );
    } else if (completed == 1) {
      nextLevel = 2; // Elite is unlocked
      await NotificationService.instance.showFastingCompleteNotification(
        levelName: 'Intermediate',
        targetTime: '2 PM',
        nextLevel: 'Elite (4 PM)',
      );
    } else {
      nextLevel = 2; // Elite complete
      await NotificationService.instance.showFastingCompleteNotification(
        levelName: 'Elite',
        targetTime: '4 PM',
      );
    }

    onMilestone?.call(
      NutritionMilestone.levelPromoted,
      completedLevel: completed,
      nextLevel: nextLevel,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — YES / NO & DEAL
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> answerYes() async {
    _answeredYes = true;
    _answeredNo = false;
    _showYesNoPrompt = false;
    _dealAccepted = null;
    notifyListeners();
    if (_activeSession != null) {
      await _repo.saveYesNoResponse(
          _activeSession!.id, 'yes_step_$currentTimelineStep');
    }
  }

  Future<void> answerNo() async {
    _answeredYes = false;
    _answeredNo = true;
    _showYesNoPrompt = false;
    notifyListeners();

    if (_activeSession != null) {
      await _repo.saveYesNoResponse(
          _activeSession!.id, 'no_step_$currentTimelineStep');
    }
  }

  Future<void> advanceTimelineStep() async {
    final maxStep = maxTimelineStep;
    if (currentTimelineStep <= maxStep) {
      currentTimelineStep++;
    }

    _answeredNo = false;
    _answeredYes = false;
    _showYesNoPrompt = currentTimelineStep <= maxStep;
    _dealAccepted = null;
    notifyListeners();

    if (_activeSession != null) {
      final session = _activeSession!;
      await _repo.saveYesNoResponse(session.id, 'step_$currentTimelineStep');
    }
  }

  Future<void> answerYesDeal() async {
    _dealAccepted = true;
    notifyListeners();
    if (_activeSession != null) {
      await _repo.saveYesNoResponse(
          _activeSession!.id, 'deal_accepted_step_$currentTimelineStep');
    }
    await advanceTimelineStep();
  }

  Future<void> answerYesNotNow() async {
    _dealAccepted = false;
    notifyListeners();
    if (_activeSession != null) {
      await _repo.saveYesNoResponse(
          _activeSession!.id, 'deal_declined_step_$currentTimelineStep');
    }
    await advanceTimelineStep();
  }

  void resetPrompt() {
    _showYesNoPrompt = true;
    _answeredYes = false;
    _answeredNo = false;
    _dealAccepted = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Meal logging (Protein and Fat)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logMeal() async {
    if (_activeSession == null) return;
    try {
      final label = 'Protein: ${_proteinLabel()}, Fat: ${_fatLabel()}';
      await _repo.saveMealCompletion(
        sessionId: _activeSession!.id,
        mealType: label,
      );
      notifyListeners();
      await loadData();
    } catch (e) {
      debugPrint('NutritionViewModel.logMeal error: $e');
    }
  }

  String _proteinLabel() =>
      ['Chicken', 'Fish', 'Tofu'][selectedProtein.clamp(0, 2)];
  String _fatLabel() =>
      ['Butter', 'Cheese Sauce', 'Avocado'][selectedFat.clamp(0, 2)];

  void setMealPicker({int? protein, int? fat}) {
    if (protein != null) selectedProtein = protein;
    if (fat != null) selectedFat = fat;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Level & weights
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setLevel(int level) async {
    _selectedLevel = level;
    final session = _todaySessions[level] ??
        (_activeSession?.level == level ? _activeSession : null);
    if (session != null) {
      if (session.dayComplete || session.status == 'completed') {
        currentTimelineStep = maxTimelineStep + 1; // Completed for today!
        _showYesNoPrompt = false;
      } else {
        _syncYesNoState();
      }
    } else {
      currentTimelineStep = 0;
      _showYesNoPrompt = true;
      _answeredYes = false;
      _answeredNo = false;
      _dealAccepted = null;
    }
    notifyListeners();
    await _repo.saveLevel(level);
  }

  Future<void> saveWeightGoal({
    required double currentWeight,
    required double goalWeight,
  }) async {
    _profile ??= {};
    _profile!['weight'] = currentWeight;
    _profile!['targetWeight'] = goalWeight;
    notifyListeners();
    await _repo.saveUserWeightGoal(
        currentWeight: currentWeight, goalWeight: goalWeight);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPUTED HELPERS (used by the screen)
  // ─────────────────────────────────────────────────────────────────────────

  String get buttonLabel {
    if (isTodayCompleted) return 'Day Complete ✓ (See You Tomorrow)';
    final session = activeSession; // level-matched
    if (session == null) return 'Start Today';
    switch (session.status) {
      case 'active':
        return 'End Fast';
      case 'paused':
        return 'Resume Fast';
      default:
        return 'Start Today';
    }
  }

  /// True when progress >= 25% — used by timeline to show mid-morning prompt.
  bool get atMidMorning => fastProgress >= 0.25;

  /// True when fast is fully complete OR user answered YES.
  bool get fastEnded {
    final session = activeSession; // level-matched
    if (session == null) return false;
    return session.status == 'completed' || session.dayComplete;
  }

  double get weightProgressFraction {
    if (_profile == null) return 0.0;
    final current = double.tryParse(currentWeight) ?? 82.0;
    final target = double.tryParse(targetWeight) ?? 75.0;
    final start =
        (_profile?['startWeight'] as num?)?.toDouble() ?? (current + 5);
    final totalToLose = start - target;
    if (totalToLose <= 0) return 0.0;
    return ((start - current) / totalToLose).clamp(0.0, 1.0);
  }
}
