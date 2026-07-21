import 'package:best_u/services/notification_service.dart';
import 'package:best_u/services/password_reset_link_service.dart';
import 'package:best_u/view/auth_screens/login_screen.dart';
import 'package:best_u/view/auth_screens/welcome_screen.dart';
import 'package:best_u/view/home_screen/main_home_screen.dart';
import 'package:best_u/view/registration_screen/onboarding_screen.dart';
import 'package:best_u/view/splash_screen.dart';
import 'package:best_u/view/workout_screens/workout_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PasswordResetLinkService.instance.initialize(appNavigatorKey);
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: appNavigatorKey,
        theme: ThemeData(
          fontFamily: 'Outfit',
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const SplashScreen(),
          '/registration': (context) => const OnboardingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) =>  MainHomeScreen(),
          '/workout': (context) => const WorkoutListScreen(),
        });
  }
}
