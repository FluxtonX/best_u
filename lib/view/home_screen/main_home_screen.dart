import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/home_screen/dashboard_screen.dart';
import 'package:best_u/view/home_screen/profile_screen.dart';
import 'package:best_u/view/home_screen/progress_screen.dart';
import 'package:best_u/view/home_screen/workout_plan_screen.dart';
import 'package:best_u/view/home_screen/nutrition_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

class MainHomeScreen extends StatefulWidget {
  /// Static key — assign this when creating the widget so external code can
  /// call [_MainHomeScreenState.switchToNutrition].
  static final GlobalKey<_MainHomeScreenState> mainKey =
      GlobalKey<_MainHomeScreenState>();

  MainHomeScreen({Key? key}) : super(key: key ?? mainKey);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  /// Switch bottom-nav to the Nutrition tab (index 2).
  void switchToNutrition() => setState(() => _currentIndex = 2);

  final List<Widget> _screens = [
    const DashboardScreen(),
    const WorkoutPlanScreen(),
    const NutritionScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            border: Border(
              top: BorderSide(
                color: AppColors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _BottomNavItem(
                iconBuilder: (isSelected) => Icon(
                  Icons.home_outlined,
                  color: isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25),
                  size: 25,
                ),
                label: 'Home',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomNavItem(
                iconBuilder: (isSelected) => Icon(
                  Icons.calendar_month_outlined,
                  color: isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25),
                  size: 25,
                ),
                label: 'Program',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _BottomNavItem(
                iconBuilder: (isSelected) => SvgPicture.asset(
                  'assets/icons/nutrition.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25),
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Nutrition',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _BottomNavItem(
                iconBuilder: (isSelected) => Icon(
                  Icons.trending_up_rounded,
                  color: isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25),
                  size: 24,
                ),
                label: 'Progress',
                isSelected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _BottomNavItem(
                iconBuilder: (isSelected) => Icon(
                  Icons.person_outline_rounded,
                  color: isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25),
                  size: 25,
                ),
                label: 'Profile',
                isSelected: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final Widget Function(bool isSelected) iconBuilder;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.iconBuilder,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFF2B84B) : const Color(0xFF805F25);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFFF2B84B).withOpacity(0.06),
        highlightColor: const Color(0xFFF2B84B).withOpacity(0.03),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBuilder(isSelected),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: color,
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
