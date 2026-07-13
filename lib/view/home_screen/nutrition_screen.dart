import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

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
  const _NutritionScreenBody({super.key});

  @override
  State<_NutritionScreenBody> createState() => _NutritionScreenBodyState();
}

class _NutritionScreenBodyState extends State<_NutritionScreenBody>
    with TickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _dashboardSummary;

  // tabs — match mockup exactly: Today | Analytics | Coach
  int _selectedTab = 0;
  final List<String> _tabs = ['Today', 'Analytics', 'Coach'];

  // level selector: 0=Beginner 1=Intermediate 2=Elite
  int _selectedLevel = 0;

  // timeline interaction
  bool _showYesNoPrompt = true;   // whether 11AM card shows YES/NO
  bool _answeredNo = false;       // user tapped NO → show advice card

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── data ───────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    Map<String, dynamic>? profile;
    Map<String, dynamic>? dashboard;
    try {
      final pRes = await _apiService.getProfile();
      final dRes = await _apiService.getDashboardSummary();
      if (pRes.statusCode == 200) {
        final d = jsonDecode(pRes.body)['data'];
        if (d is Map<String, dynamic>) profile = Map.from(d);
      }
      if (dRes.statusCode == 200) {
        final d = jsonDecode(dRes.body)['data'];
        if (d is Map<String, dynamic>) dashboard = Map.from(d);
      }
    } catch (e) {
      debugPrint('Nutrition load error: $e');
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _dashboardSummary = dashboard;
      _isLoading = false;
    });
    _fadeCtrl.forward();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────
  double get _fastProgress {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.add(const Duration(hours: 8));
    final end = today.add(const Duration(hours: 14));
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;
    return ((now.difference(start).inSeconds) /
            (end.difference(start).inSeconds))
        .clamp(0.0, 1.0);
  }

  String get _currentWeight => (_profile?['weight'] ?? 82).toString();
  String get _targetWeight => (_profile?['targetWeight'] ?? 75).toString();

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
                onRefresh: _loadData,
                color: AppColors.primary,
                backgroundColor: const Color(0xFF1A1A1A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  child: _isLoading
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: const Text(
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
                    color: sel ? Colors.black : AppColors.white.withOpacity(0.55),
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
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FASTING CARD  (weight chips + level pills + start button)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFastingCard() {
    final progress = _fastProgress;
    final percent = (progress * 100).round();

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
            onTap: () {},
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
              child: const Center(
                child: Text(
                  'Start Today',
                  style: TextStyle(
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
    final sel = _selectedLevel == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = index),
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
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              _goalCell(
                icon: Icons.access_time_rounded,
                label: 'Fast Until',
                value: '2 PM',
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
                          Icon(
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
                          value: 0.40,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF33271A),
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '40%',
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
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          _timelineRow(
            time: '8 AM',
            title: 'Morning Check',
            subtitle: '✓ Fasting goal reached',
            state: _TLState.completed,
            isLast: false,
          ),
          _timelineRow(
            time: '11 AM',
            title: 'Mid-Morning',
            state: _TLState.current,
            isLast: false,
            expandWidget: _build11amExpand(),
          ),
          _timelineRow(
            time: '2 PM',
            title: 'First Goal!',
            state: _TLState.future,
            isLast: false,
          ),
          _timelineRow(
            time: '3 PM',
            title: 'Afternoon',
            state: _TLState.future,
            isLast: false,
          ),
          _timelineRow(
            time: '5 PM',
            title: 'Evening Goal!',
            state: _TLState.future,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // 11AM expandable widget — YES/NO → advice card
  Widget _build11amExpand() {
    if (!_showYesNoPrompt && !_answeredNo) return const SizedBox.shrink();

    if (_answeredNo) {
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
            Text(
              'Not ideal, but that\'s okay.',
              style: const TextStyle(
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
                  onTap: () => setState(() {
                    _showYesNoPrompt = false;
                    _answeredNo = false;
                  }),
                ),
                const SizedBox(width: 10),
                _smallActionBtn(
                  label: 'Not now',
                  filled: false,
                  onTap: () => setState(() {
                    _showYesNoPrompt = false;
                    _answeredNo = false;
                  }),
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
                onTap: () => setState(() => _showYesNoPrompt = false),
              ),
              const SizedBox(width: 10),
              _smallActionBtn(
                label: 'NO ✓',
                filled: true,
                onTap: () => setState(() {
                  _showYesNoPrompt = false;
                  _answeredNo = true;
                }),
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
          border: filled
              ? null
              : Border.all(color: Colors.white.withOpacity(0.2)),
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
                      if (state == _TLState.current) ...[
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
          decoration: BoxDecoration(
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
    final weightLost = _dashboardSummary?['user']?['weightLost'] ?? 3;
    final weeklyStreak = _dashboardSummary?['weekStats']?['weeklyStreak'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            _statBox(
                label: 'Weight lost',
                value: '${weightLost.toString()} kg',
                highlight: true),
            const SizedBox(width: 12),
            _statBox(
                label: 'Fasting streak',
                value: '$weeklyStreak days',
                highlight: false),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('Performance'),
        const SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              _progressRow('Average daily calories', 0.75),
              const SizedBox(height: 14),
              _progressRow('Hydration goal', 0.6),
              const SizedBox(height: 14),
              _progressRow('Macronutrient balance', 0.85),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(
      {required String label, required String value, required bool highlight}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    color: highlight ? AppColors.primary : AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text('${(value * 100).round()}%',
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.07),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
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
        _coachTip('💧', 'Stay hydrated',
            'Drink 250ml of water every hour to support your fasting window and keep energy steady.'),
        const SizedBox(height: 12),
        _coachTip('🥗', 'Break fast smart',
            'Start with protein-rich meals and vegetables to avoid blood sugar spikes after your fast.'),
        const SizedBox(height: 12),
        _coachTip('📋', 'Track your meals',
            'Log what you eat after 2 PM so the app can keep your nutrition plan aligned with your goals.'),
        const SizedBox(height: 24),
        AppBounceAnimation(
          onTap: () {},
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Ask Your Nutrition Coach →',
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
    );
  }

  Widget _coachTip(String emoji, String title, String desc) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(desc,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.55)),
              ],
            ),
          ),
        ],
      ),
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
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _TLState { completed, current, future }
