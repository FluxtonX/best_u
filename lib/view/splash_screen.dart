import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/auth_screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _screenController;
  late final AnimationController _logoController;
  late final AnimationController _pulseController;
  late final AnimationController _dotController;
  late final Animation<double> _screenOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _footerOpacity;
  late final Animation<double> _logoPulse;
  late VideoPlayerController _videoController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset('assets/video/excercise-video.mp4')
          ..initialize().then((_) {
            if (!mounted) return;
            _videoController
              ..setVolume(0)
              ..setLooping(true)
              ..play();
            setState(() {});
          });

    _screenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _screenOpacity = CurvedAnimation(
      parent: _screenController,
      curve: Curves.easeOut,
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.56, curve: Curves.easeOutBack),
      ),
    );
    _logoSlide = Tween(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.56, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.38, 0.72, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.38, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _footerOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _logoPulse = Tween(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();

    _screenController.forward();
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _logoController.forward();
    });

    _navigationTimer = Timer(const Duration(seconds: 3), _routeAfterSplash);
  }

  Future<void> _routeAfterSplash() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final apiService = ApiService();
        final response = await apiService.getProfile();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          if (data != null && data['onboardingCompleted'] == true) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/registration');
          }
        } else {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/registration');
        }
      } catch (_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/registration');
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _screenController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _screenOpacity,
        child: Stack(
          children: [
            _buildVideoBackground(),
            _buildOverlay(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 19),
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [_logoController, _pulseController],
                      ),
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoOpacity,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: Transform.scale(
                              scale: _logoScale.value * _logoPulse.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _buildLogoCard(),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: _buildTagline(),
                      ),
                    ),
                    const Spacer(flex: 25),
                    FadeTransition(
                      opacity: _footerOpacity,
                      child: Column(
                        children: [
                          _buildDots(),
                          const SizedBox(height: 18),
                          _buildFooter(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    if (!_videoController.value.isInitialized) {
      return const Positioned.fill(child: ColoredBox(color: Colors.black));
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = 0.12 + (_pulseController.value * 0.1);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glow),
                blurRadius: 14,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/welcom-logo.png',
        width: 146,
        height: 141,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTagline() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 13),
        const SizedBox(width: 5),
        Text(
          'Transform Your Body',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.primary.withValues(alpha: 0.78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 13),
      ],
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(0),
            const SizedBox(width: 8),
            _dot(1),
            const SizedBox(width: 8),
            _dot(2),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    final phase = (_dotController.value + index / 3) % 1.0;
    final active = phase < 0.34;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: active ? 7 : 5,
      height: active ? 7 : 5,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.24),
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.42),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '8 Week Transformation Program',
      style: TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.primary.withValues(alpha: 0.86),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
