import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';

class AllPersonalBestsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> personalBests;

  const AllPersonalBestsScreen({
    super.key,
    required this.personalBests,
  });

  @override
  State<AllPersonalBestsScreen> createState() =>
      _AllPersonalBestsScreenState();
}

class _AllPersonalBestsScreenState extends State<AllPersonalBestsScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _glowPulse;

  List<Animation<double>> _cardFades = [];
  List<Animation<Offset>> _cardSlides = [];

  @override
  void initState() {
    super.initState();

    // Header
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    // Cards stagger
    final count = widget.personalBests.length;
    _cardsCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350 + count * 90));
    _cardFades = List.generate(count, (i) {
      final start = (i / count.clamp(1, 999) * 0.65).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _cardsCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });
    _cardSlides = List.generate(count, (i) {
      final start = (i / count.clamp(1, 999) * 0.65).clamp(0.0, 1.0);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _cardsCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));
    });

    // Trophy glow
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.15, end: 0.5).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 220));
    _cardsCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bests = widget.personalBests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: const Column(
              children: [
                Text(
                  'ALL RECORDS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  'Personal Bests',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: bests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              itemCount: bests.length + 1, // +1 for the trophy header
              itemBuilder: (context, index) {
                if (index == 0) return _buildTrophyHeader();
                final i = index - 1;
                final item = bests[i];
                final fade = i < _cardFades.length
                    ? _cardFades[i]
                    : const AlwaysStoppedAnimation(1.0);
                final slide = i < _cardSlides.length
                    ? _cardSlides[i]
                    : const AlwaysStoppedAnimation(Offset.zero);
                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: _buildRecordCard(item, i),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTrophyHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 4),
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1A10), Color(0xFF111008)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withValues(alpha: _glowPulse.value),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppColors.primary, size: 48),
              const SizedBox(height: 10),
              Text(
                '${widget.personalBests.length} Personal Records',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your all-time best performances',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> item, int index) {
    final rating = item['rating'] as int? ?? 0;
    final value = item['value']?.toString() ?? '--';
    final exercise = item['exercise']?.toString() ?? '';
    final date = item['date']?.toString() ?? '';
    final isTop = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFF1A1A10) : const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTop
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: isTop ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : const Color(0xFF26272C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: index < 3
                ? Icon(
                    [
                      Icons.emoji_events_rounded,
                      Icons.workspace_premium_rounded,
                      Icons.military_tech_rounded,
                    ][index],
                    color: [
                      AppColors.primary,
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
                    ][index],
                    size: 22,
                  )
                : Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),

          // Name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isTop ? Colors.white : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Value + dots
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isTop ? AppColors.primary : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: i < rating
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              color: Colors.white.withValues(alpha: 0.15), size: 64),
          const SizedBox(height: 16),
          Text(
            'No records yet',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete workouts to start\ntracking personal bests',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
