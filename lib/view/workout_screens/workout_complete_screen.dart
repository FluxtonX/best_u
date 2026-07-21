import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/services/notification_service.dart';
import 'package:best_u/view/home_screen/main_home_screen.dart';
import 'package:best_u/view/home_screen/widgets/weight_update_modal.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class WorkoutCompleteScreen extends StatefulWidget {
  final int exercisesCompleted;
  final int durationMinutes;
  final int personalBests;
  final Map<String, String> improvements;
  final String workoutId;

  const WorkoutCompleteScreen({
    super.key,
    this.exercisesCompleted = 0,
    this.durationMinutes = 42,
    this.personalBests = 0,
    this.improvements = const {},
    this.workoutId = '',
  });

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _audioController;

  // ─── Controllers ──────────────────────────────────────────────
  late final AnimationController _checkCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _headerCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _rowsCtrl;
  late final AnimationController _bottomCtrl;
  late final AnimationController _countCtrl;

  // ─── Check icon ───────────────────────────────────────────────
  late final Animation<double> _checkScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;

  // ─── Header (title + subtitle) ────────────────────────────────
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  // ─── Stat cards (3 staggered) ─────────────────────────────────
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  // ─── Progress card ────────────────────────────────────────────
  late final Animation<double> _progressFade;
  late final Animation<Offset> _progressSlide;

  // ─── Improvement rows ─────────────────────────────────────────
  late final List<Animation<double>> _rowFades;
  late final List<Animation<Offset>> _rowSlides;

  // ─── Bottom cards + button ────────────────────────────────────
  late final Animation<double> _bottomFade;
  late final Animation<Offset> _bottomSlide;

  // ─── Count-up ─────────────────────────────────────────────────
  late final Animation<int> _exerciseCount;
  late final Animation<int> _personalBestsCount;
  late final Animation<int> _durationCount;

  @override
  void initState() {
    super.initState();

    // ── Check bounce ──────────────────────────────────────────
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut));

    // ── Pulsing glow ring ─────────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.45)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowScale = Tween<double>(begin: 1.0, end: 1.22)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // ── Header ────────────────────────────────────────────────
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    // ── Stat cards ────────────────────────────────────────────
    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardFades = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardsCtrl,
          curve: Interval(i * 0.22, 0.55 + i * 0.22,
              curve: Curves.easeOut),
        ),
      ),
    );
    _cardSlides = List.generate(
      3,
      (i) => Tween<Offset>(
              begin: const Offset(0, 0.5), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _cardsCtrl,
          curve: Interval(i * 0.22, 0.55 + i * 0.22,
              curve: Curves.easeOutCubic),
        ),
      ),
    );

    // ── Progress card ─────────────────────────────────────────
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _progressFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _progressCtrl, curve: Curves.easeOutCubic));

    // ── Improvement rows ──────────────────────────────────────
    final rowCount = widget.improvements.length.clamp(1, 20);
    _rowsCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + rowCount * 80),
    );
    _rowFades = List.generate(rowCount, (i) {
      final start = (i / rowCount * 0.7).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _rowsCtrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });
    _rowSlides = List.generate(rowCount, (i) {
      final start = (i / rowCount * 0.7).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
              begin: const Offset(0.25, 0), end: Offset.zero)
          .animate(
        CurvedAnimation(
            parent: _rowsCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });

    // ── Bottom cards + button ─────────────────────────────────
    _bottomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _bottomFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOut));
    _bottomSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOutCubic));

    // ── Count-up numbers ──────────────────────────────────────
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exerciseCount = IntTween(begin: 0, end: widget.exercisesCompleted)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));
    _personalBestsCount = IntTween(begin: 0, end: widget.personalBests)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));
    _durationCount = IntTween(begin: 0, end: widget.durationMinutes)
        .animate(CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut));

    _runSequence();
    _checkWeeklyWeightTrigger();
    // Notify: daily workout done. Fire immediately when this screen appears.
    NotificationService.instance.showDailyWorkoutCompleteNotification();
    // Notify: weekly workout done only when this is the final day of a week (e.g. _d3).
    if (widget.workoutId.endsWith('_d3')) {
      NotificationService.instance.showWeeklyWorkoutCompleteNotification();
    }
  }

  void _checkWeeklyWeightTrigger() {
    if (widget.workoutId.endsWith('_d3')) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final apiService = ApiService();
          final response = await apiService.getProfile();
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final currentWeight = data['data']?['weight']?.toString() ?? '70.0';
            if (mounted) {
              await WeightUpdateModal.show(context, currentWeight);
            }
          }
        } catch (e) {
          debugPrint('Error getting profile for weekly weight update trigger: $e');
          if (mounted) {
            await WeightUpdateModal.show(context, '70.0');
          }
        }
      });
    }
  }

  Future<void> _playCelebrationSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('soundEffectsEnabled') ?? true;
      if (!soundEnabled) return;

      _audioController = VideoPlayerController.asset('assets/sound/celeberation.mp3');
      await _audioController!.initialize();
      await _audioController!.play();
    } catch (e) {
      debugPrint('Error playing celebration sound: $e');
    }
  }

  Future<void> _runSequence() async {
    _playCelebrationSound();
    await Future.delayed(const Duration(milliseconds: 120));
    _checkCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardsCtrl.forward();
    _countCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _progressCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _rowsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _bottomCtrl.forward();
  }

  @override
  void dispose() {
    _audioController?.dispose();
    _checkCtrl.dispose();
    _glowCtrl.dispose();
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    _progressCtrl.dispose();
    _rowsCtrl.dispose();
    _bottomCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleImprovements = widget.improvements;
    final improvementCount = widget.improvements.length;
    final completedCount =
        widget.exercisesCompleted > 0 ? widget.exercisesCompleted : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  children: [
                    _buildSuccessIcon(),
                    const SizedBox(height: 18),

                    // ── Header ──────────────────────────────────────
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Column(
                          children: [
                            const Text(
                              'Workout Complete!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Outstanding effort today!',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 38),

                    // ── Stat cards (staggered) ───────────────────────
                    _animatedCard(
                      index: 0,
                      child: AnimatedBuilder(
                        animation: _exerciseCount,
                        builder: (_, __) => _buildSummaryTile(
                          icon: Icons.fitness_center_rounded,
                          label: 'Exercises Completed',
                          value: '${_exerciseCount.value}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _animatedCard(
                      index: 1,
                      child: AnimatedBuilder(
                        animation: _personalBestsCount,
                        builder: (_, __) => _buildSummaryTile(
                          icon: Icons.emoji_events_outlined,
                          label: 'Personal Bests',
                          value: '${_personalBestsCount.value}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _animatedCard(
                      index: 2,
                      child: AnimatedBuilder(
                        animation: _durationCount,
                        builder: (_, __) => _buildSummaryTile(
                          icon: Icons.schedule_rounded,
                          label: 'Workout Duration',
                          value: '${_durationCount.value} min',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Progress card ───────────────────────────────
                    FadeTransition(
                      opacity: _progressFade,
                      child: SlideTransition(
                        position: _progressSlide,
                        child: _buildProgressCard(
                          completedCount: completedCount,
                          improvementCount: improvementCount,
                          improvements: visibleImprovements,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Quote & saved ───────────────────────────────
                    FadeTransition(
                      opacity: _bottomFade,
                      child: SlideTransition(
                        position: _bottomSlide,
                        child: Column(
                          children: [
                            _buildQuoteCard(),
                            const SizedBox(height: 12),
                            _buildSavedMessage(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Finish button ──────────────────────────────────────
            FadeTransition(
              opacity: _bottomFade,
              child: SlideTransition(
                position: _bottomSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: AppBounceAnimation(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  MainHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'FINISH WORKOUT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Animated card wrapper ────────────────────────────────────────────────
  Widget _animatedCard({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(
        position: _cardSlides[index],
        child: child,
      ),
    );
  }

  // ─── Check icon with bounce + pulsing glow ────────────────────────────────
  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_checkCtrl, _glowCtrl]),
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer glow ring
            Transform.scale(
              scale: _glowScale.value,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16D86E)
                          .withValues(alpha: _glowOpacity.value),
                      blurRadius: 28,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Bouncing icon
            Transform.scale(
              scale: _checkScale.value,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D4024),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFF16D86E),
                  size: 34,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int completedCount,
    required int improvementCount,
    required Map<String, String> improvements,
  }) {
    final entries = improvements.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3D23), Color(0xFF102719)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF16D86E).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF16D86E),
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Amazing Progress!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
              children: [
                const TextSpan(text: 'You improved on '),
                TextSpan(
                  text: '$improvementCount out of $completedCount',
                  style: const TextStyle(
                    color: Color(0xFF16D86E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' exercises'),
              ],
            ),
          ),
          if (improvements.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Staggered improvement rows
            ...List.generate(entries.length, (i) {
              final fade = i < _rowFades.length
                  ? _rowFades[i]
                  : const AlwaysStoppedAnimation(1.0);
              final slide = i < _rowSlides.length
                  ? _rowSlides[i]
                  : const AlwaysStoppedAnimation(Offset.zero);
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: _buildImprovementRow(entries[i]),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'Complete more workouts to track your personal bests and see improvements here!',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImprovementRow(MapEntry<String, String> entry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            entry.value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF16D86E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2910), Color(0xFF1A1510)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/icons/cup.png',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          const Text(
            '"Success is the sum of small\nefforts repeated day in and\nday out."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keep crushing it!',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.save_outlined, color: Color(0xFF16D86E), size: 34),
          SizedBox(height: 10),
          Text(
            'Progress Saved!',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Color(0xFF16D86E),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your results have been recorded',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
