import 'dart:convert';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/home_screen/all_personal_bests_screen.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _weightHistory = [];
  List<Map<String, dynamic>> _strengthLevels = [];
  List<Map<String, dynamic>> _weeklyWorkouts = [];
  List<Map<String, dynamic>> _personalBests = [];
  bool _isLoading = true;
  late final AnimationController _graphController;
  late final Animation<double> _graphAnimation;

  static const Color _card = Color(0xFF17181C);
  static const Color _stroke = Color(0xFF2A2B31);
  static const Color _muted = Color(0xFF8E8F98);
  static const Color _green = Color(0xFF00D26A);
  static const Color _orange = Color(0xFFFF9F0A);

  @override
  void initState() {
    super.initState();
    _graphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _graphAnimation = CurvedAnimation(
      parent: _graphController,
      curve: Curves.easeOutCubic,
    );
    _fetchData();
  }

  @override
  void dispose() {
    _graphController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final apiService = ApiService();
      final responses = await Future.wait([
        apiService.getProgressSummary(),
        apiService.getWeightHistory(),
        apiService.getStrengthLevels(),
        apiService.getPersonalBests(),
      ]);

      final summaryData = _responseData(responses[0]);
      final weightData = _responseData(responses[1]);
      final strengthData = _responseData(responses[2]);
      final personalBestData = _responseData(responses[3]);

      if (!mounted) return;
      setState(() {
        _summary = _asMap(summaryData);
        _weightHistory = _asMapList(weightData);
        _strengthLevels = _asMapList(strengthData);
        _weeklyWorkouts = _asMapList(_summary?['weeklyWorkouts']);
        _personalBests = _asMapList(personalBestData);
        _isLoading = false;
      });
      _graphController
        ..reset()
        ..forward();
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  dynamic _responseData(ApiResponse response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded['data'];
    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Temporarily set mock data for Skeletonizer
      _summary = {
        'totalWorkoutMinutes': 180,
        'workoutIncreasePercent': 12,
        'weightLost': 2.4,
        'weightTrend': -2.4,
        'proteinPercentage': 18,
        'completionRate': 85,
        'avgTime': 42.5,
        'totalCalories': 1250,
        'heartRate': 135,
        'completedThisWeek': 3,
        'totalThisWeek': 6,
        'weeklyWorkouts': List.generate(
            6,
            (index) => {
                  'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index],
                  'value': index % 2 == 0 ? 24.0 : 12.0
                }),
      };
      _weightHistory = List.generate(
          6,
          (index) => {
                'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index],
                'value': 75.0 - (index * 0.2)
              });
      _strengthLevels = List.generate(
          6,
          (index) => {
                'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index],
                'value': 20.0 + (index * 5)
              });
      _weeklyWorkouts = List.generate(
          6,
          (index) => {
                'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][index],
                'value': index % 2 == 0 ? 24.0 : 12.0
              });
      _personalBests = List.generate(
          3,
          (index) => {
                'exercise': 'Bench Press',
                'value': '45.0 kg',
                'date': 'Jun 12, 2026',
                'rating': 4,
              });
    }

    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Skeletonizer(
            enabled: _isLoading,
            effect: ShimmerEffect(
              baseColor: Colors.white.withOpacity(0.04),
              highlightColor: Colors.white.withOpacity(0.12),
              duration: const Duration(milliseconds: 1000),
            ),
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                      child: Column(
                        children: [
                          _buildKpiRow(),
                          const SizedBox(height: 16),
                          _buildWeightProgressCard(),
                          const SizedBox(height: 16),
                          _buildStrengthCard(),
                          const SizedBox(height: 16),
                          _buildBanner(
                            icon: Icons.check_circle_outline_rounded,
                            text:
                                "You're on the track up, You've mastered the last 2 workouts",
                          ),
                          const SizedBox(height: 10),
                          _buildBanner(
                            icon: Icons.emoji_events_outlined,
                            text: 'Strongest lift: Squats - 21 kg this week',
                          ),
                          const SizedBox(height: 16),
                          _buildWeeklyWorkoutsCard(),
                          const SizedBox(height: 16),
                          _buildActivityGrid(),
                          const SizedBox(height: 16),
                          _buildPersonalBestCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _stroke, width: 1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Every rep counts and keeps record',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return Row(
      children: [
        _buildKpiCard(
          icon: Icons.local_fire_department_outlined,
          label: 'Workout\nMinutes',
          value: '${_summary?['totalWorkoutMinutes'] ?? 0}',
          trend: '+${_summary?['workoutIncreasePercent'] ?? 0}d',
          iconColor: AppColors.primary,
        ),
        const SizedBox(width: 14),
        _buildKpiCard(
          icon: Icons.trending_up_rounded,
          label: 'Weight',
          value: '${_summary?['weightLost'] ?? 0}',
          unit: 'kg',
          iconColor: _green,
        ),
        const SizedBox(width: 14),
        _buildKpiCard(
          icon: Icons.grain_rounded,
          label: 'Protein',
          value: '${_summary?['proteinPercentage'] ?? 0}',
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    String? unit,
    String? trend,
  }) {
    return Expanded(
      child: Container(
        height: 148,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: Colors.black, size: 18),
                ),
                const Spacer(),
                if (trend != null)
                  Text(
                    trend,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: _muted,
                fontSize: 13,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (unit != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressCard() {
    return AnimatedBuilder(
      animation: _graphAnimation,
      builder: (context, _) {
        return _buildChartCard(
          title: 'Weight Progress',
          trailing: '${_formatSigned(_summary?['weightTrend'] ?? 0)}kg',
          trailingColor: _green,
          height: 190,
          child: CustomPaint(
            painter: _LineChartPainter(
              _weightHistory,
              progress: _graphAnimation.value,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _buildStrengthCard() {
    return AnimatedBuilder(
      animation: _graphAnimation,
      builder: (context, _) {
        return _buildChartCard(
          title: 'Strength Levels Up',
          height: 192,
          child: _BarChart(
            items: _strengthLevels,
            color: AppColors.primary,
            maxBarHeight: 78,
            progress: _graphAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildWeeklyWorkoutsCard() {
    return AnimatedBuilder(
      animation: _graphAnimation,
      builder: (context, _) {
        return _buildChartCard(
          title: 'Weekly Workouts',
          trailing:
              '${_summary?['completedThisWeek'] ?? 0}/${_summary?['totalThisWeek'] ?? 0}',
          trailingColor: _green,
          height: 172,
          child: _BarChart(
            items: _weeklyWorkouts,
            color: _orange,
            maxBarHeight: 58,
            progress: _graphAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildChartCard({
    required String title,
    required double height,
    required Widget child,
    String? trailing,
    Color trailingColor = Colors.white,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: trailingColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: _cardDecoration(radius: 13),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xFFD9D9DE),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 232,
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Summary',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _graphAnimation,
                      builder: (context, _) {
                        final completion =
                            ((_summary?['completionRate'] ?? 0) as num)
                                    .toDouble() /
                                100;
                        return Center(
                          child: CustomPaint(
                            painter: _RingPainter(
                              value: completion * _graphAnimation.value,
                            ),
                            child: SizedBox(
                              width: 104,
                              height: 104,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(completion * 100 * _graphAnimation.value).round()}%',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: _muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _buildMetricCard(
                    icon: Icons.local_fire_department_outlined,
                    value: _formatNumber(_summary?['totalCalories'] ?? 0),
                    label: 'Kcal burn',
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    icon: Icons.monitor_heart_outlined,
                    value: '${_summary?['avgTime'] ?? 0} min',
                    label: 'Avg time',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.monitor_heart_outlined,
                value: '${_summary?['heartRate'] ?? 0} bpm',
                label: 'Avg heart rate',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMonthProgressCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: _muted,
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

  Widget _buildMonthProgressCard() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Adding progress\nthis month',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Personal Best Records',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AllPersonalBestsScreen(personalBests: _personalBests),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      final curved = CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic);
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 380),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._personalBests.take(3).toList().asMap().entries.map((entry) {
            return _buildPersonalBestRow(
              entry.value,
              showDivider: entry.key !=
                  (_personalBests.length > 3 ? 2 : _personalBests.length - 1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalBestRow(
    Map<String, dynamic> item, {
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF26272C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item['icon'] as IconData? ?? Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['exercise']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['date']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['value']?.toString() ?? '--',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final rating = item['rating'] as int? ?? 0;
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: index < rating
                              ? AppColors.primary
                              : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
      ],
    );
  }

  BoxDecoration _cardDecoration({double radius = 14}) {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _stroke, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    final number = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final text = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _formatSigned(dynamic value) {
    final number =
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    final formatted =
        number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 1);
    return number > 0 ? '+$formatted' : formatted;
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.items,
    required this.color,
    required this.maxBarHeight,
    required this.progress,
  });

  final List<Map<String, dynamic>> items;
  final Color color;
  final double maxBarHeight;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final values =
        items.map((item) => (item['value'] as num?)?.toDouble() ?? 0).toList();
    final maxValue = values.fold<double>(1, (max, v) => v > max ? v : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        final value = ((item['value'] as num?)?.toDouble() ?? 0);
        final isDone = (item['done'] as bool?) ?? value > 0;

        // Done bars animate to real height; empty bars show a tiny dim stub
        final double barHeight = isDone
            ? (value / maxValue * maxBarHeight * progress).clamp(4.0, maxBarHeight)
            : 4.0;

        final Color barColor = isDone
            ? color
            : color.withOpacity(0.15);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['day']?.toString() ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDone
                      ? _ProgressScreenState._muted
                      : _ProgressScreenState._muted.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.items, {required this.progress});

  final List<Map<String, dynamic>> items;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.length < 2) return;

    final chartHeight = size.height - 30;
    final values =
        items.map((item) => (item['value'] as num).toDouble()).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b) - 0.4;
    final maxValue = values.reduce((a, b) => a > b ? a : b) + 0.4;
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;
    final stepX = size.width / (items.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < items.length; i++) {
      final x = stepX * i;
      final y = chartHeight - ((values[i] - minValue) / range * chartHeight);
      points.add(Offset(x, y + 5));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlX = (current.dx + next.dx) / 2;
      path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }

    final linePaint = Paint()
      ..color = _ProgressScreenState._orange
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final metric = path.computeMetrics().first;
    final animatedPath = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(animatedPath, linePaint);

    final dotPaint = Paint()..color = _ProgressScreenState._orange;
    for (int i = 0; i < points.length; i++) {
      final pointProgress = points.length == 1 ? 1.0 : i / (points.length - 1);
      if (pointProgress <= progress) {
        canvas.drawCircle(points[i], 5, dotPaint);
      }
    }

    for (int i = 0; i < items.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: items[i]['day']?.toString() ?? '',
          style: const TextStyle(
            color: _ProgressScreenState._muted,
            fontSize: 10,
            fontFamily: 'Outfit',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, chartHeight + 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.progress != progress;
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.11;
    final trackPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.28)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final valuePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(strokeWidth / 2), -1.2, 6.0, false, trackPaint);
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.2,
      6.0 * value.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
