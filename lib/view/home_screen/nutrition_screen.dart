import 'dart:ui' as ui;

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/nutrition_viewmodel.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';

import '../../services/nutrition_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NutritionScreenBody();
}

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL BODY
// ─────────────────────────────────────────────────────────────────────────────
class _NutritionScreenBody extends StatefulWidget {
  const _NutritionScreenBody();

  @override
  State<_NutritionScreenBody> createState() => _NutritionScreenBodyState();
}

class _NutritionScreenBodyState extends State<_NutritionScreenBody>
    with TickerProviderStateMixin {
  // ── ViewModel (single source of truth) ────────────────────────────────────
  late final NutritionViewModel _vm;

  // tabs — match mockup exactly: Today | Analytics | Coach
  int _selectedTab = 0;
  final List<String> _tabs = ['Today', 'Analytics', 'Coach'];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _vm = NutritionViewModel(
      repo: NutritionRepository(),
      api: ApiService(),
    );

    // Wire milestone callbacks to popups
    _vm.onMilestone = (milestone) {
      if (!mounted) return;
      if (milestone == NutritionMilestone.half) {
        _showFirstGoalReachedPopup();
      } else if (milestone == NutritionMilestone.complete) {
        _showDayCompletePopup();
      }
    };

    // Rebuild when VM notifies of updates (timer ticks, network loads, weight edits)
    _vm.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (!_vm.isLoading && !_fadeCtrl.isCompleted) {
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────
  String get _currentWeight => _vm.currentWeight;
  String get _targetWeight => _vm.targetWeight;

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar row ──────────────────────────────────────────────
            _buildAppBar(),
            // ── Tab pills ────────────────────────────────────────────────
            _buildTabBar(),
            const SizedBox(height: 4),
            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _vm.loadData,
                color: AppColors.primary,
                backgroundColor: const Color(0xFF1A1A1A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  child: _vm.isLoading
                      ? _buildSkeleton()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildTabContent(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        'Nutrition Coach',
        style: TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR  (Today | Analytics | Coach)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color:
                        sel ? Colors.black : AppColors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildTodayTab();
      case 1:
        return _buildAnalyticsTab();
      case 2:
        return _buildCoachTab();
      default:
        return _buildTodayTab();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TODAY TAB  — exactly matches mockup
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTodayTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ── SECTION: Track your fasting ───────────────────────────────
        _sectionLabel('Track your fasting'),
        const SizedBox(height: 10),
        _buildFastingCard(),

        const SizedBox(height: 22),

        // ── SECTION: Today's Goal ─────────────────────────────────────
        _sectionLabel("Today's Goal"),
        const SizedBox(height: 10),
        _buildGoalCard(),

        const SizedBox(height: 22),

        // ── SECTION: Today's Timeline ─────────────────────────────────
        _sectionLabel("Today's Timeline"),
        const SizedBox(height: 10),
        _buildTimelineCard(),

        // ── SECTION: Log Your First Meal (Real-time Nutrition Tracking) ──
        if (_vm.activeSession != null && _vm.currentTimelineStep > 2) ...[
          const SizedBox(height: 22),
          _sectionLabel("Meal Recommendation"),
          const SizedBox(height: 10),
          _buildMealLoggerCard(),
        ],
      ],
    );
  }

  Widget _buildMealLoggerCard() {
    if (_vm.mealLogged) {
      return _card(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A1E),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Completed! 🎉',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Excellent nutrition choice logged!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _selectorRow(String icon, String label, List<String> options,
        int selectedIndex, Function(int) onSelect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(options.length, (i) {
              final sel = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    height: 38,
                    margin: EdgeInsets.only(
                      right: i == options.length - 1 ? 0 : 8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: sel
                            ? Colors.black
                            : AppColors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build your first meal',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Food Emoji indicators
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🥩', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 14),
                  Text('🥦', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 14),
                  Text('🧈', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _selectorRow(
            '🥩',
            'PROTEIN · 100G',
            ['Chicken', 'Fish', 'Tofu'],
            _vm.selectedProtein,
            (val) => _vm.setMealPicker(protein: val),
          ),
          const SizedBox(height: 18),
          _selectorRow(
            '🥦',
            'VEGETABLES · 100G',
            ['Broccoli', 'Green Veg'],
            _vm.selectedFiber,
            (val) => _vm.setMealPicker(fiber: val),
          ),
          const SizedBox(height: 18),
          _selectorRow(
            '🧈',
            'HEALTHY FAT',
            ['Butter', 'Cheese Sauce'],
            _vm.selectedFat,
            (val) => _vm.setMealPicker(fat: val),
          ),
          const SizedBox(height: 24),
          AppBounceAnimation(
            onTap: () => _vm.logMeal(),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "I've Finished My Meal",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.check, color: Colors.black, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FASTING CARD  (weight chips + level pills + start button)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFastingCard() {
    final percent = _vm.fastPercent;
    final buttonLabel = _vm.buttonLabel;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row: weight chips + circular progress
          Row(
            children: [
              // Current weight chip
              _weightChip('Current', _currentWeight),
              const SizedBox(width: 10),
              // Goal weight chip
              _weightChip('Goal', _targetWeight),
              const Spacer(),
              // Circular progress
              _circularProgress(percent),
            ],
          ),

          const SizedBox(height: 18),

          // ── Level selector pills
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _levelPill('Beginner', 0)),
                Expanded(child: _levelPill('Intermediate', 1)),
                Expanded(child: _levelPill('Elite', 2)),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Start Today button
          AppBounceAnimation(
            onTap: () => _vm.handleMainButton(),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // weight chip — "Current 82 kg"
  Widget _weightChip(String label, String value) {
    final isCurrent = label.toLowerCase() == 'current';
    final icon = isCurrent ? Icons.balance_rounded : Icons.adjust_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF26211C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' kg',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // circular ring progress widget
  Widget _circularProgress(int percent) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                'done',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // level pill
  Widget _levelPill(String label, int index) {
    final sel = _vm.selectedLevel == index;
    return GestureDetector(
      onTap: () => _vm.setLevel(index),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: sel ? Colors.black : AppColors.white.withOpacity(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GOAL CARD  (2×2 metric grid)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGoalCard() {
    final session = _vm.activeSession;
    String fastUntil = '2 PM';
    if (session != null) {
      fastUntil =
          _formatTimeOfDay(session.endsAt ?? session.endedAt ?? DateTime.now());
    }

    final weightProgressPct = _vm.weightProgressFraction;
    final int weightProgressPercent = (weightProgressPct * 100).round();

    return _card(
      child: Column(
        children: [
          Row(
            children: [
              _goalCell(
                icon: Icons.access_time_rounded,
                label: 'Fast Until',
                value: fastUntil,
                highlight: true,
              ),
              const SizedBox(width: 10),
              _goalCell(
                icon: Icons.eco_rounded,
                label: 'Next Meal',
                value: 'Protein + Veg',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _goalCell(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories Target',
                value: '1,800 kcal',
              ),
              const SizedBox(width: 10),
              // Weight goal cell with progress bar
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26211C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.adjust_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Weight Goal',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: weightProgressPct,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF33271A),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$weightProgressPercent%',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalCell({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF26211C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: highlight ? AppColors.primary : AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIMELINE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    final step = _vm.currentTimelineStep;
    final session = _vm.activeSession;

    final s0 = session == null
        ? _TLState.future
        : (step > 0 ? _TLState.completed : _TLState.current);

    final s1 = session == null
        ? _TLState.future
        : (step > 1
            ? _TLState.completed
            : (step == 1 ? _TLState.current : _TLState.future));

    final s2 = session == null
        ? _TLState.future
        : (step > 2
            ? _TLState.completed
            : (step == 2 ? _TLState.current : _TLState.future));

    final s3 = session == null
        ? _TLState.future
        : (step > 3
            ? _TLState.completed
            : (step == 3 ? _TLState.current : _TLState.future));

    final s4 = session == null
        ? _TLState.future
        : (step > 4
            ? _TLState.completed
            : (step == 4 ? _TLState.current : _TLState.future));

    // Calculate real-time tracking milestones based on active session startedAt and endsAt
    String t0Str = '8 AM';
    String t1Str = '11 AM';
    String t2Str = '2 PM';
    String t3Str = '3 PM';
    String t4Str = '5 PM';

    // Time-gating: only show "Have you eaten yet?" when real clock reaches the milestone time
    final now = DateTime.now();
    final bool showPrompt8Am = s0 == _TLState.current && now.hour >= 8;
    final bool showPrompt11Am = s1 == _TLState.current && now.hour >= 11;
    final bool showPrompt2Pm = s2 == _TLState.current && now.hour >= 14;
    final bool showPrompt3Pm = s3 == _TLState.current && now.hour >= 15;
    final bool showPrompt5Pm = s4 == _TLState.current && now.hour >= 17;

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          _timelineRow(
            time: t0Str,
            title: 'Morning Check',
            subtitle: _vm.activeSession == null
                ? null
                : (step > 0 ? '✓ Fasting goal reached' : 'Active'),
            state: s0,
            expandWidget: showPrompt8Am ? _build11amExpand() : null,
            isLast: false,
          ),
          _timelineRow(
            time: t1Str,
            title: 'Mid-Morning',
            subtitle: _vm.activeSession == null
                ? null
                : (step > 1 ? '✓ Fasting goal reached' : (step == 1 ? 'Active' : null)),
            state: s1,
            expandWidget: showPrompt11Am ? _build11amExpand() : null,
            isLast: false,
          ),
          _timelineRow(
            time: t2Str,
            title: 'First Goal!',
            subtitle: step > 2
                ? '✓ Fasting goal reached'
                : (step == 2 ? 'Active' : null),
            state: s2,
            tag: 'Meal time',
            tagBgColor: Colors.white.withOpacity(0.08),
            tagTextColor: Colors.white.withOpacity(0.6),
            expandWidget: showPrompt2Pm ? _build11amExpand() : null,
            isLast: false,
          ),
          _timelineRow(
            time: t3Str,
            title: 'Afternoon',
            subtitle: step > 3
                ? '✓ Fasting goal reached'
                : (step == 3 ? 'Active' : null),
            state: s3,
            isLast: false,
            expandWidget: showPrompt3Pm ? _build11amExpand() : null,
          ),
          _timelineRow(
            time: t4Str,
            title: 'Evening Goal!',
            subtitle:
                step > 4 ? '✓ Fast completed' : (step == 4 ? 'Active' : null),
            state: s4,
            tag: 'Meal time',
            tagBgColor: Colors.white.withOpacity(0.08),
            tagTextColor: Colors.white.withOpacity(0.6),
            expandWidget: showPrompt5Pm ? _build11amExpand() : null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // 11AM expandable widget — YES/NO → advice card
  Widget _build11amExpand() {
    if (!_vm.showYesNoPrompt && !_vm.answeredNo) return const SizedBox.shrink();

    if (_vm.answeredNo) {
      // Advice card
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Not ideal, but that\'s okay.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try to make it until 2 PM tomorrow.\nCoffee or tea with cream can help.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withOpacity(0.6),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _smallActionBtn(
                  label: 'Deal! ✓',
                  filled: true,
                  onTap: () => _vm.answerYesDeal(),
                ),
                const SizedBox(width: 10),
                _smallActionBtn(
                  label: 'Not now',
                  filled: false,
                  onTap: () => _vm.answerYesNotNow(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // YES / NO prompt
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have you eaten yet?',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallActionBtn(
                label: 'YES',
                filled: false,
                onTap: () => _vm.answerYes(),
              ),
              const SizedBox(width: 10),
              _smallActionBtn(
                label: 'NO ✓',
                filled: true,
                onTap: () => _vm.answerNo(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallActionBtn({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              filled ? null : Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: filled ? Colors.black : AppColors.white.withOpacity(0.75),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // individual timeline row
  Widget _timelineRow({
    required String time,
    required String title,
    String? subtitle,
    required _TLState state,
    required bool isLast,
    Widget? expandWidget,
    String? tag,
    Color? tagBgColor,
    Color? tagTextColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── dot + vertical line ───────────────────────────────────
          Column(
            children: [
              _tlDot(state),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // ── content ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: state == _TLState.completed
                              ? AppColors.primary
                              : state == _TLState.current
                                  ? AppColors.primary
                                  : AppColors.white.withOpacity(0.45),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBgColor ??
                                AppColors.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: tagTextColor ?? AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ] else if (state == _TLState.current) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Now',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: state != _TLState.future
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (expandWidget != null) expandWidget,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tlDot(_TLState state) {
    switch (state) {
      case _TLState.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.black, size: 15),
        );
      case _TLState.current:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            color: AppColors.primary.withOpacity(0.15),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _TLState.future:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
            color: Colors.white.withOpacity(0.04),
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    final ds = _dashboardSummary;
    final avgFasting = ds?['stats']?['avgFastH'] ?? 0.0;
    final longestFast = ds?['stats']?['longestFast'] ?? '0h';
    final mealsDone = ds?['stats']?['mealsDone'] ?? 0;
    final streak = ds?['weekStats']?['weeklyStreak'] ?? 0;
    final weightLostVal = ds?['user']?['weightLost'] ?? 0.0;
    final goalRate = ds?['weekStats']?['goalRate'] ?? 0;

    Widget _miniStat(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF26211C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // Top small stats (2 rows of 3)
        Row(children: [
          _miniStat('Avg Fasting', '${avgFasting}h'),
          const SizedBox(width: 10),
          _miniStat('Longest Fast', longestFast.toString()),
          const SizedBox(width: 10),
          _miniStat('Meals Done', mealsDone.toString()),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat('Streak', '$streak days'),
          const SizedBox(width: 10),
          _miniStat('Weight Lost', '${(weightLostVal as num).toStringAsFixed(1)} kg'),
          const SizedBox(width: 10),
          _miniStat('Goal Rate', '$goalRate%'),
        ]),

        const SizedBox(height: 18),

        // Goal completion card — driven by weeklyConsistency from Firestore
        Builder(builder: (_) {
          final weeklyConsistency = (ds?['weekStats']?['weeklyConsistency']
                  as List<bool>?) ??
              List.filled(7, false);
          final completedDaysCount =
              weeklyConsistency.where((d) => d).length;
          final goalCompletionPct =
              ((completedDaysCount / 7) * 100).round();
          final goalFraction = goalCompletionPct / 100.0;

          final String perfSubtitle;
          if (goalCompletionPct >= 90) {
            perfSubtitle = 'Outstanding performance 🔥';
          } else if (goalCompletionPct >= 70) {
            perfSubtitle = 'Above average performance ↑';
          } else if (goalCompletionPct >= 40) {
            perfSubtitle = 'Average performance →';
          } else if (completedDaysCount > 0) {
            perfSubtitle = 'Room to improve ↓';
          } else {
            perfSubtitle = 'Start your first goal!';
          }

          return _card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Goal Completion',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completedDaysCount of 7 days this week',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        perfSubtitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.54),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 86,
                        height: 86,
                        child: CircularProgressIndicator(
                          value: goalFraction.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.04),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$goalCompletionPct%',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'rate',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.white.withOpacity(0.54),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),

        // Fasting hours line chart — driven by weeklyHours from Firestore
        Builder(builder: (_) {
          final weeklyHours = (ds?['stats']?['weeklyHours']
                  as List<double>?) ??
              List.filled(7, 0.0);

          // Compute day labels dynamically (index 6 = today, 0 = 6 days ago)
          const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final today = DateTime.now();
          final labels = List.generate(7, (i) {
            final d = today.subtract(Duration(days: 6 - i));
            return dayNames[d.weekday - 1];
          });

          return _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fasting hours this week',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _FastingChartPainter(
                      values: weeklyHours,
                      labels: labels,
                      lineColor: AppColors.primary,
                      labelColor: AppColors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 18),

        // Weekly consistency — driven by weeklyConsistency + weeklyHours
        Builder(builder: (_) {
          final weeklyConsistency = (ds?['weekStats']?['weeklyConsistency']
                  as List<bool>?) ??
              List.filled(7, false);
          final weeklyHours = (ds?['stats']?['weeklyHours']
                  as List<double>?) ??
              List.filled(7, 0.0);

          // Current calendar week: find Monday of this week
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          final monday =
              todayDate.subtract(Duration(days: todayDate.weekday - 1));

          // Average fasting hours (only for days with data > 0)
          final activeDayHours =
              weeklyHours.where((h) => h > 0).toList();
          final avgHours = activeDayHours.isEmpty
              ? 0.0
              : activeDayHours.reduce((a, b) => a + b) /
                  activeDayHours.length;

          const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

          // Build status for each day of the calendar week
          final dayWidgets = <Widget>[];
          for (int i = 0; i < 7; i++) {
            final dayDate = monday.add(Duration(days: i));
            final dateNum = dayDate.day;
            final isFuture = dayDate.isAfter(todayDate);

            // Map this calendar day to the repo's "last 7 days" index
            final daysAgo =
                todayDate.difference(dayDate).inDays; // 0=today, 1=yesterday…
            final repoIdx =
                (daysAgo >= 0 && daysAgo < 7) ? 6 - daysAgo : -1;

            String status;
            if (isFuture) {
              status = 'upcoming';
            } else if (repoIdx >= 0 && weeklyConsistency[repoIdx]) {
              // Completed — check if excellent (above average hours)
              final hours = weeklyHours[repoIdx];
              status = (hours > avgHours && avgHours > 0)
                  ? 'excellent'
                  : 'completed';
            } else if (repoIdx >= 0) {
              status = 'missed';
            } else {
              status = 'missed'; // older than 7 days ago
            }

            // Build the circle badge
            Color badgeBg;
            Widget badgeChild;
            switch (status) {
              case 'excellent':
                badgeBg = const Color(0xFF4E3A20);
                badgeChild = const Icon(Icons.star_rounded,
                    color: AppColors.primary, size: 18);
                break;
              case 'completed':
                badgeBg = const Color(0xFF2E4B2E);
                badgeChild = const Icon(Icons.check_rounded,
                    color: Color(0xFF4CAF50), size: 18);
                break;
              case 'upcoming':
                badgeBg = Colors.white.withOpacity(0.04);
                badgeChild = Text(
                  '$dateNum',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.3),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                );
                break;
              default: // missed
                badgeBg = Colors.white.withOpacity(0.04);
                badgeChild = Text(
                  '—',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.2),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                );
            }

            dayWidgets.add(
              Column(
                children: [
                  // Day letter
                  Text(
                    dayLetters[i],
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Center(child: badgeChild),
                  ),
                  const SizedBox(height: 6),
                  // Date number
                  Text(
                    '$dateNum',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEKLY CONSISTENCY',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: dayWidgets,
                ),
                const SizedBox(height: 14),
                // Legend row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text('Excellent',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 11,
                        )),
                    const SizedBox(width: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(width: 6),
                    Text('Completed',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 11,
                        )),
                    const SizedBox(width: 16),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    const SizedBox(width: 6),
                    Text('Missed',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 11,
                        )),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COACH TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoachTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // top coach card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1A17),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COACH · TODAY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Stay the course.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E2419), Color(0xFF1B120E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1A17),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 34),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _vm.coachMessage,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.65),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A241E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Today's Tip\nPlan your first meal ahead of time — having it ready removes decision fatigue.",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppBounceAnimation(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Get Today's Plan",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOADING SKELETON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _skeletonBox(36, 100),
        const SizedBox(height: 10),
        _skeletonBox(180, double.infinity),
        const SizedBox(height: 20),
        _skeletonBox(36, 100),
        const SizedBox(height: 10),
        _skeletonBox(140, double.infinity),
        const SizedBox(height: 20),
        _skeletonBox(36, 120),
        const SizedBox(height: 10),
        _skeletonBox(280, double.infinity),
      ],
    );
  }

  Widget _skeletonBox(double h, double w) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );
  }

  void _showFirstGoalReachedPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'First Goal Reached! 🏆',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You reached today's first fasting goal. Now enjoy your first meal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Fasting Champion!',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppBounceAnimation(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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

  void _showDayCompletePopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Day Complete!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Congratulations! You've successfully completed your fasting goal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                AppBounceAnimation(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Fantastic!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    if (minute == 0) {
      return '$formattedHour $period';
    } else {
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMinute $period';
    }
  }

  Map<String, dynamic>? get _dashboardSummary {
    final analytics = _vm.analytics;
    final currentWeight = double.tryParse(_vm.currentWeight) ?? 82.0;
    final startWeight = (_vm.profile?['startWeight'] as num?)?.toDouble() ??
        (currentWeight + 1.5);
    final weightLost = (startWeight - currentWeight).clamp(0.0, 100.0);

    return {
      'user': {
        'weightLost': weightLost,
      },
      'stats': {
        'longestFast': '${analytics?['longestFastH'] ?? 0.0}h',
        'avgFastH': analytics?['avgFastH'] ?? 0.0,
        'mealsDone': analytics?['mealsCount'] ?? 0,
        'weeklyHours':
            (analytics?['weeklyHours'] as List<double>?) ??
                List.filled(7, 0.0),
      },
      'weekStats': {
        'weeklyStreak': analytics?['streak'] ?? 0,
        'goalRate': (analytics?['completionPct'] as num?)?.round() ?? 0,
        'weeklyConsistency':
            (analytics?['weeklyConsistency'] as List<bool>?) ??
                List.filled(7, false),
      },
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _TLState { completed, current, future }

// ─────────────────────────────────────────────────────────────────────────────
// FASTING CHART CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────
/// Draws a smooth Catmull-Rom spline line chart with gradient fill, gold dots,
/// and bottom-aligned day labels. Zero-dependency — no fl_chart needed.
class _FastingChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color labelColor;

  _FastingChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const double labelAreaHeight = 24;
    const double dotRadius = 4.5;
    const double topPad = 12;
    final chartHeight = size.height - labelAreaHeight - topPad;
    final chartWidth = size.width;

    // Determine Y range
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    // Map data to pixel coordinates
    final points = <Offset>[];
    final step = chartWidth / (values.length - 1).clamp(1, values.length);
    for (int i = 0; i < values.length; i++) {
      final x = i * step;
      final normalised = (values[i] - minVal) / range;
      final y = topPad + chartHeight * (1.0 - normalised);
      points.add(Offset(x, y));
    }

    // Build smooth Catmull-Rom path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Gradient fill under the curve
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, topPad + chartHeight)
      ..lineTo(points.first.dx, topPad + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topPad),
        Offset(0, topPad + chartHeight),
        [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw dots and labels
    final dotPaintOuter = Paint()..color = lineColor;
    final dotPaintInner = Paint()..color = const Color(0xFF1A1A1A);

    for (int i = 0; i < points.length; i++) {
      // Outer dot
      canvas.drawCircle(points[i], dotRadius, dotPaintOuter);
      // Inner dot (gives a ring look)
      canvas.drawCircle(points[i], dotRadius - 1.8, dotPaintInner);

      // Day label
      final tp = TextPainter(
        text: TextSpan(
          text: i < labels.length ? labels[i] : '',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: labelColor,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2,
            topPad + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FastingChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}
