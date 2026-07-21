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
  /// 50 % of the fast window reached ("First Goal Reached" popup)
  half,

  /// 100 % of the fast window reached ("Day Complete" popup)
  complete,
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
  /// Fired when a trackable milestone is reached for the first time.
  void Function(NutritionMilestone)? onMilestone;

  // ── Session ──────────────────────────────────────────────────────────────
  FastingSession? _activeSession;
  FastingSession? get activeSession => _activeSession;

  // ── User profile ─────────────────────────────────────────────────────────
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  String get currentWeight => (_profile?['weight'] ?? 82).toString();
  String get targetWeight => (_profile?['targetWeight'] ?? 75).toString();

  // ── Level ────────────────────────────────────────────────────────────────
  int _selectedLevel = 0;
  int get selectedLevel => _selectedLevel;

  // ── Analytics / coach ────────────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? get analytics => _analytics;

  String _coachMessage =
      'Start your first fast today — every journey begins with a single step.';
  String get coachMessage => _coachMessage;

  // ── Meal ─────────────────────────────────────────────────────────────────
  bool get mealLogged => _activeSession?.mealLogged ?? false;

  int selectedProtein = 0;
  int selectedFiber = 0;
  int selectedFat = 0;

  // ── YES / NO prompt ──────────────────────────────────────────────────────
  bool _showYesNoPrompt = true;
  bool get showYesNoPrompt => _showYesNoPrompt;

  bool _answeredNo = false;
  bool get answeredNo => _answeredNo;

  int currentTimelineStep = 0;

  // ── Progress ─────────────────────────────────────────────────────────────
  double get fastProgress {
    if (_activeSession == null) return 0.0;
    final s = _activeSession!;
    final now = DateTime.now();
    final end = s.endsAt ?? s.endedAt;
    if (end == null) return 0.0;
    if (now.isBefore(s.startedAt)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    final total = end.difference(s.startedAt).inSeconds;
    if (total <= 0) return 0.0;
    return (now.difference(s.startedAt).inSeconds / total).clamp(0.0, 1.0);
  }

  int get fastPercent => (currentTimelineStep * 20).clamp(0, 100);

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

      if (_activeSession != null) {
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

    // Also honour flags already written to Firestore (survives reinstall)
    final fired = _activeSession?.remindersFired ?? [];
    if (fired.contains('25')) _ach25Shown = true;
    if (fired.contains('50')) _ach50Shown = true;
    if (fired.contains('100')) _ach100Shown = true;
  }

  void _syncYesNoState() {
    final resp = _activeSession?.yesNoResponse;
    if (resp == 'yes') {
      _showYesNoPrompt = false;
      _answeredNo = true;
    } else if (resp != null && resp.startsWith('no_')) {
      currentTimelineStep = int.tryParse(resp.split('_')[1]) ?? 0;
      _showYesNoPrompt = currentTimelineStep <= 4;
      _answeredNo = false;
    } else if (resp == 'no') {
      currentTimelineStep = 1;
      _showYesNoPrompt = true;
      _answeredNo = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION STREAM LISTENER
  // ─────────────────────────────────────────────────────────────────────────
  void _onSessionUpdate(FastingSession? session) {
    _activeSession = session;
    if (session != null) _syncYesNoState();
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
  // MILESTONE DETECTION
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _checkMilestones() async {
    final session = _activeSession;
    if (session == null || session.status != 'active') return;
    final progress = fastProgress;

    // 25 % — tracked silently; UI handles the inline YES/NO prompt
    if (progress >= 0.25 && !_ach25Shown) {
      _ach25Shown = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ach25_${session.id}', true);
      await _repo.markReminderFired(session.id, '25');
    }


  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Session lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> handleMainButton() async {
    if (_activeSession == null || _activeSession!.status == 'completed') {
      await startFast();
    } else if (_activeSession!.status == 'paused') {
      await resumeFast();
    } else if (_activeSession!.status == 'active') {
      await completeFast();
    }
  }

  Future<void> startFast() async {
    try {
      int seconds = 60;
      if (_selectedLevel == 1) seconds = 120;
      if (_selectedLevel == 2) seconds = 180;

      final session = await _repo.startSession(
        duration: Duration(seconds: seconds),
        level: _selectedLevel,
      );

      _activeSession = session;
      _ach25Shown = false;
      _ach50Shown = false;
      _ach100Shown = false;
      _showYesNoPrompt = true;
      _answeredNo = false;
      currentTimelineStep = 0;

      _ensureTicker();
      notifyListeners();
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
    if (_activeSession == null) return;
    try {
      await _repo.completeSession(_activeSession!.id);
      _activeSession = null;
      _ticker?.cancel();
      notifyListeners();
      await loadData();
    } catch (e) {
      debugPrint('NutritionViewModel.completeFast error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — YES / NO
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> answerYes() async {
    // User selected YES (they ate early) -> show advice card
    _showYesNoPrompt = false;
    _answeredNo = true;
    notifyListeners();
    if (_activeSession != null) {
      await _repo.saveYesNoResponse(_activeSession!.id, 'yes');
    }
  }

  Future<void> answerNo() async {
    if (currentTimelineStep < 4) {
      currentTimelineStep++;
    } else {
      _showYesNoPrompt = false;
      currentTimelineStep++;
    }
    notifyListeners();
    
    if (_activeSession != null) {
      final session = _activeSession!;
      await _repo.saveYesNoResponse(session.id, 'no_$currentTimelineStep');

      // User manually completed the 2 PM goal (Step 2 -> 3)
      if (currentTimelineStep == 3 && !_ach50Shown) {
        _ach50Shown = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ach50_${session.id}', true);
        await _repo.markReminderFired(session.id, '50');
        onMilestone?.call(NutritionMilestone.half);
      }

      // User manually completed the 5 PM goal (Step 4 -> 5)
      if (currentTimelineStep == 5 && !_ach100Shown) {
        _ach100Shown = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ach100_${session.id}', true);
        if (!session.dayComplete) {
          await _repo.markDayComplete(session.id);
        }
        await _repo.markReminderFired(session.id, '100');
        onMilestone?.call(NutritionMilestone.complete);
        NotificationService.instance.showFastingCompleteNotification();
        await loadData(); // refresh analytics tab
      }
    }
  }

  Future<void> answerYesDeal() async {
    _showYesNoPrompt = false;
    _answeredNo = false;
    notifyListeners();
    if (_activeSession != null) {
      await completeFast();
    }
  }

  void answerYesNotNow() {
    _answeredNo = false;
    _showYesNoPrompt = true;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Meal logging
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logMeal() async {
    if (_activeSession == null) return;
    try {
      final label =
          'Protein: ${_proteinLabel()}, Fiber: ${_fiberLabel()}, Fat: ${_fatLabel()}';
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
  String _fiberLabel() =>
      ['Broccoli', 'Green Veg', 'Green Veg'][selectedFiber.clamp(0, 2)];
  String _fatLabel() =>
      ['Butter', 'Cheese Sauce', 'Cheese Sauce'][selectedFat.clamp(0, 2)];

  void setMealPicker({int? protein, int? fiber, int? fat}) {
    if (protein != null) selectedProtein = protein;
    if (fiber != null) selectedFiber = fiber;
    if (fat != null) selectedFat = fat;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS — Level & weights
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setLevel(int level) async {
    _selectedLevel = level;
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
    if (_activeSession == null) return 'Start Today';
    switch (_activeSession!.status) {
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
    if (_activeSession == null) return false;
    return _activeSession!.status == 'completed' || _activeSession!.dayComplete;
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
