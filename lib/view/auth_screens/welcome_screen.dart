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

class _WelcomeScreenState extends State<WelcomeScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset('assets/video/excercise-video.mp4')
          ..initialize().then((_) {
            _controller.play();
            _controller.setLooping(true);
            _controller.setVolume(0);
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Video
          if (_controller.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            // Fallback to dark background while initializing
            Positioned.fill(child: Container(color: Colors.black)),

          // Dark Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo Section
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border:
                              Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app-logo.png',
                            width: 90,
                            height: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Best-',
                              style: TextStyle(color: AppColors.white),
                            ),
                            TextSpan(
                              text: 'U',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Headline Section
                  Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 46,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
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
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Transform in 8 weeks',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: AppColors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.primary, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  // Buttons Section
                  Column(
                    children: [
                      AuthButton(
                        text: 'Create Account',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthButton(
                        text: 'Sign In',
                        isPrimary: false,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'By continuing, you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
