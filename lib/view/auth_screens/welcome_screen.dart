import 'dart:ui';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/sign_up_screen.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _headlineOpacity;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _actionsOpacity;
  late final Animation<Offset> _actionsSlide;
  late VideoPlayerController _controller;

  bool _isCreating = false;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween(
      begin: const Offset(0, -0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _headlineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.28, 0.72, curve: Curves.easeOut),
      ),
    );
    _headlineSlide = Tween(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _actionsOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
      ),
    );
    _actionsSlide = Tween(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller =
        VideoPlayerController.asset('assets/video/excercise-video.mp4')
          ..initialize().then((_) {
            if (!mounted) return;
            _controller.play();
            _controller.setLooping(true);
            _controller.setVolume(0);
            setState(() {});
          });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundVideo(),
          _buildOverlay(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topGap =
                    (constraints.maxHeight * 0.12).clamp(72.0, 132.0);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: _buildLogo(),
                          ),
                        ),
                        const SizedBox(height: 56),
                        FadeTransition(
                          opacity: _headlineOpacity,
                          child: SlideTransition(
                            position: _headlineSlide,
                            child: _buildHeadline(),
                          ),
                        ),
                        const SizedBox(height: 56),
                        FadeTransition(
                          opacity: _actionsOpacity,
                          child: SlideTransition(
                            position: _actionsSlide,
                            child: _buildActions(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundVideo() {
    if (!_controller.value.isInitialized) {
      return const Positioned.fill(child: ColoredBox(color: Colors.black));
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.36),
                Colors.black.withValues(alpha: 0.66),
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 14,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/welcom-logo.png',
        width: 198,
        height: 191,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 41,
              height: 1.12,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
            children: [
              TextSpan(text: 'Become the\n'),
              TextSpan(
                text: 'Best Version',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: '\nof You'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Follow an 8-week blueprint to lose\nweight and increase strength.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.primary.withValues(alpha: 0.68),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF21D86D),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Transform in 8 weeks',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF21D86D),
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        AuthButton(
          text: 'Create Account',
          isLoading: _isCreating,
          onPressed: () async {
            setState(() => _isCreating = true);
            await Future.delayed(const Duration(milliseconds: 400));
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              ).then((_) => setState(() => _isCreating = false));
            }
          },
        ),
        const SizedBox(height: 16),
        AuthButton(
          text: 'Sign In',
          isPrimary: false,
          isLoading: _isSigning,
          onPressed: () async {
            setState(() => _isSigning = true);
            await Future.delayed(const Duration(milliseconds: 400));
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ).then((_) => setState(() => _isSigning = false));
            }
          },
        ),
        const SizedBox(height: 32),
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white.withValues(alpha: 0.58),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
