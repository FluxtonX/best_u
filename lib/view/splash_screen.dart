import 'dart:async';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// SCREEN FADE
  late final AnimationController _screenFadeController;
  late final Animation<double> _screenFade;

  /// BREATHING BACKGROUND GLOW
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  /// BURST INTRO GLOW
  late final AnimationController _burstController;
  late final Animation<double> _burstScale;
  late final Animation<double> _burstOpacity;

  /// CONTENT ENTRANCE SEQUENCE
  late final AnimationController _contentController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoRotation;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _footerOpacity;

  /// CONTINUOUS PULSE
  late final AnimationController _pulseController;
  late final Animation<double> _logoPulse;

  /// DOT SHIMMER
  late final AnimationController _dotController;
  late final Animation<double> _dotShimmer;

  @override
  void initState() {
    super.initState();

    /// Screen fade
    _screenFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _screenFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _screenFadeController, curve: Curves.easeOut));
    _screenFadeController.forward();

    /// Breathing glow
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _glowScale = Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _glowOpacity = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    /// Burst glow
    _burstController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _burstScale = Tween(begin: 0.2, end: 1.8).animate(
        CurvedAnimation(parent: _burstController, curve: Curves.easeOutExpo));
    _burstOpacity = Tween(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _burstController, curve: Curves.easeOut));
    Future.delayed(
        const Duration(milliseconds: 200), () => _burstController.forward());

    /// Content entrance timeline
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _logoScale = Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut)));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut)));
    _logoSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOut)));
    _logoRotation = Tween(begin: -0.25, end: 0.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    _titleOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));
    _titleSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 0.75, curve: Curves.easeOut)));

    _dotsOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut)));

    _footerOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOut)));

    Future.delayed(
        const Duration(milliseconds: 120), () => _contentController.forward());

    /// Continuous pulse
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _logoPulse = Tween(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    /// Dot shimmer
    _dotController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _dotShimmer = Tween(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _dotController, curve: Curves.easeInOut));

    /// NAVIGATION (UNCHANGED)
    Timer(const Duration(seconds: 3), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists && doc.data()?['onboardingCompleted'] == true) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/registration');
          }
        } catch (_) {
          Navigator.pushReplacementNamed(context, '/registration');
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _screenFadeController.dispose();
    _glowController.dispose();
    _burstController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _screenFade,
        child: Stack(
          children: [
            /// Burst glow
            Center(
              child: AnimatedBuilder(
                animation: _burstController,
                builder: (_, __) => Transform.scale(
                  scale: _burstScale.value,
                  child: Opacity(
                    opacity: _burstOpacity.value,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.25),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Breathing glow
            Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Transform.scale(
                  scale: _glowScale.value,
                  child: Opacity(
                    opacity: _glowOpacity.value,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// MAIN CONTENT
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  /// LOGO
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_contentController, _pulseController]),
                    builder: (_, __) => FadeTransition(
                      opacity: _logoOpacity,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Transform.scale(
                            scale: _logoScale.value * _logoPulse.value,
                            child: _buildLogo(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                        position: _titleSlide, child: _buildTitle()),
                  ),

                  const SizedBox(height: 12),
                  FadeTransition(
                      opacity: _taglineOpacity, child: _buildTagline()),

                  const Spacer(flex: 4),
                  FadeTransition(opacity: _dotsOpacity, child: _buildDots()),
                  const SizedBox(height: 40),
                  FadeTransition(
                      opacity: _footerOpacity, child: _buildFooter()),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/app-logo.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      );

  Widget _buildTitle() => const Text.rich(
        TextSpan(
          style: TextStyle(
              fontFamily: 'Outfit', fontSize: 40, fontWeight: FontWeight.w800),
          children: [
            TextSpan(text: 'Best-', style: TextStyle(color: AppColors.white)),
            TextSpan(text: 'U', style: TextStyle(color: AppColors.primary)),
          ],
        ),
      );

  Widget _buildTagline() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✦',
              style: TextStyle(color: AppColors.primary.withOpacity(0.8))),
          const SizedBox(width: 10),
          Text('TRANSFORM YOUR BODY',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.9),
                  fontSize: 11,
                  letterSpacing: 2)),
          const SizedBox(width: 10),
          Text('✦',
              style: TextStyle(color: AppColors.primary.withOpacity(0.8))),
        ],
      );

  Widget _buildDots() => AnimatedBuilder(
        animation: _dotController,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(false),
            const SizedBox(width: 10),
            _dot(true, _dotShimmer.value),
            const SizedBox(width: 10),
            _dot(false),
          ],
        ),
      );

  Widget _dot(bool active, [double shimmer = 1]) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(shimmer)
              : AppColors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
      );

  Widget _buildFooter() => Text(
        '8 Week Transformation Program',
        style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white.withOpacity(0.4),
            fontSize: 12),
      );
}
