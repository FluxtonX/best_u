import 'dart:async';
import 'dart:math';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementScreen extends StatefulWidget {
  final String exerciseName;
  final String message;
  final Widget? nextScreen;
  final Duration autoContinueAfter;

  const AchievementScreen({
    super.key,
    this.exerciseName = 'NEW PERSONAL BEST!',
    this.message = 'You crushed it! Keep going!',
    this.nextScreen,
    this.autoContinueAfter = const Duration(milliseconds: 2600),
  });

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  Timer? _continueTimer;

  @override
  void initState() {
    super.initState();
    _playCelebrationEffects();
    if (widget.nextScreen != null) {
      _continueTimer = Timer(widget.autoContinueAfter, _continue);
    }
  }

  @override
  void dispose() {
    _continueTimer?.cancel();
    super.dispose();
  }

  Future<void> _playCelebrationEffects() async {
    final prefs = await SharedPreferences.getInstance();
    final isSoundEnabled = prefs.getBool('soundEffectsEnabled') ?? true;
    if (!isSoundEnabled) return;

    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  void _continue() {
    if (!mounted) return;
    if (widget.nextScreen == null) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextScreen!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          const Positioned.fill(child: _CelebrationParticles()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 82,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.65, 0.65),
                        end: const Offset(1, 1),
                        duration: 520.ms,
                        curve: Curves.elasticOut,
                      )
                      .shimmer(
                        delay: 360.ms,
                        duration: 900.ms,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                  const SizedBox(height: 18),
                  Text(
                    widget.exerciseName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.18, end: 0, duration: 360.ms),
                  const SizedBox(height: 16),
                  const Text(
                    '🎺',
                    style: TextStyle(fontSize: 34),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shake(
                        hz: 2,
                        rotation: 0.04,
                        duration: 900.ms,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: Color(0xFFFFB300),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(delay: 260.ms, duration: 420.ms),
                  const Spacer(flex: 4),
                  if (widget.nextScreen == null)
                    AppBounceAnimation(
                      onTap: _continue,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationParticles extends StatelessWidget {
  const _CelebrationParticles();

  @override
  Widget build(BuildContext context) {
    final random = Random(7);
    final colors = [
      AppColors.primary,
      const Color(0xFF16D86E),
      const Color(0xFFFFD166),
      Colors.white,
    ];

    return Stack(
      children: List.generate(34, (index) {
        final size = random.nextDouble() * 5 + 3;
        final left = random.nextDouble() * MediaQuery.of(context).size.width;
        final top = random.nextDouble() * MediaQuery.of(context).size.height;
        final color = colors[random.nextInt(colors.length)];

        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(2),
            ),
          )
              .animate(
                delay: Duration(milliseconds: index * 36),
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .fadeIn(duration: 260.ms)
              .moveY(
                begin: 8,
                end: -18 - random.nextDouble() * 22,
                duration: Duration(milliseconds: 1100 + random.nextInt(900)),
                curve: Curves.easeInOut,
              )
              .rotate(
                begin: -0.03,
                end: 0.04,
                duration: Duration(milliseconds: 900 + random.nextInt(800)),
              ),
        );
      }),
    );
  }
}
