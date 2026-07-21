import 'dart:convert';
import 'dart:io';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/home_screen/edit_profile_screen.dart';
import 'package:best_u/view/home_screen/widgets/weight_update_modal.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:best_u/view/registration_screen/subscription_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _soundEffectsEnabled = true;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadLocalImage();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEffectsEnabled = prefs.getBool('soundEffectsEnabled') ?? true;
    });
  }

  Future<void> _updateSoundEffects(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEffectsEnabled', value);
    if (!mounted) return;
    setState(() {
      _soundEffectsEnabled = value;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getProfile();
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _profile = jsonDecode(response.body)['data'];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    setState(() {
      _imagePath = prefs.getString('profile_image_path_$uid');
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logout Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                // Text titles
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppBounceAnimation(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppBounceAnimation(
                        onTap: () {
                          Navigator.pop(dialogContext); // Close dialog
                          _authService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Log Out',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Color(0xFF151515),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Text titles
                  const Text(
                    'Delete Account?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action Buttons
                  isDeleting
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: AppBounceAnimation(
                                onTap: () => Navigator.pop(dialogContext),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppBounceAnimation(
                                onTap: () async {
                                  setState(() {
                                    isDeleting = true;
                                  });
                                  try {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .delete();
                                      await user.delete();
                                    }
                                    if (!context.mounted) return;
                                    Navigator.pop(dialogContext); // Close dialog
                                    _authService.logout();
                                    Navigator.pushReplacementNamed(context, '/login');
                                  } on FirebaseAuthException catch (e) {
                                    if (!context.mounted) return;
                                    setState(() {
                                      isDeleting = false;
                                    });
                                    Navigator.pop(dialogContext);
                                    if (e.code == 'requires-recent-login') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please log out and log back in before deleting your account.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.message}'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    setState(() {
                                      isDeleting = false;
                                    });
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('An error occurred: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      _profile = {
        'name': 'John Doe',
        'goal': 'Gain Strength',
        'experienceLevel': 'Intermediate',
        'age': 28,
        'weight': 78.5,
        'bmi': '22.5',
      };
    }

    if (!_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            "User data not found",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final String name = _profile!['name'] ?? 'User';
    final String goal = _profile!['goal'] ?? 'No goal set';
    final String experience = _profile!['experienceLevel'] ?? 'Beginner';
    final String age = _profile!['age']?.toString() ?? '24';
    final String weight = _profile!['weight']?.toString() ?? '65';
    final String bmi = _profile!['bmi']?.toString() ?? 'Not set';

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
            onRefresh: _fetchProfile,
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your account settings',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),

                // User Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC6934A).withValues(alpha: 0.15),
                        const Color(0xFF151515),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFC6934A).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              color: const Color(0xFF151515),
                            ),
                            child: ClipOval(
                              child: _imagePath != null
                                  ? Image.file(
                                      File(_imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.primary,
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '$experience • $goal',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Age', age),
                          _buildVerticalDivider(),
                          _buildStatItem('Weight', '$weight kg'),
                          _buildVerticalDivider(),
                          _buildStatItem('BMI', bmi),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // PROFILE Section
                _buildSectionLabel('PROFILE'),
                _buildMenuCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    _fetchProfile();
                    _loadLocalImage();
                  },
                ),
                _buildMenuCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Update Weight',
                  trailing: Text(
                    '$weight kg',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    await WeightUpdateModal.show(context, weight);
                    _fetchProfile();
                  },
                ),

                const SizedBox(height: 32),
                // APP SETTINGS Section
                _buildSectionLabel('APP SETTINGS'),
                _buildSwitchCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  value: true,
                  onChanged: (v) {},
                ),
                _buildSwitchCard(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound Effects',
                  subtitle: 'Celebration sounds',
                  value: _soundEffectsEnabled,
                  onChanged: _updateSoundEffects,
                ),

                const SizedBox(height: 32),
                // SUBSCRIPTION Section
                _buildSectionLabel('SUBSCRIPTION'),
                _buildMenuCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Manage Subscription',
                  subtitle: 'Premium Plan • \$9.99/week',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
                // Log Out Button
                AppBounceAnimation(
                  onTap: () => _showLogoutDialog(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                
                // Delete Account Button
                AppBounceAnimation(
                  onTap: () => _showDeleteAccountDialog(context),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.redAccent.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Best-U Version 1.0.0',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '© 2026 Best-U Fitness',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return AppBounceAnimation(
      onTap: onTap,
      scaleFactor: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(icon, color: AppColors.primary, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing:
              trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 24,
              ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFFC6934A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        trailing: CupertinoSwitch(
          activeTrackColor: AppColors.primary,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}
