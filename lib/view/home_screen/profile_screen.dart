import 'dart:io';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/home_screen/edit_profile_screen.dart';
import 'package:best_u/view/home_screen/widgets/weight_update_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString('profile_image_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Not logged in")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              body: Center(child: Text("User data not found")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String name = data['name'] ?? 'User';
        final String goal = data['goal'] ?? 'No goal set';
        final String experience = data['experienceLevel'] ?? 'Beginner';
        final String age = data['age']?.toString() ?? '24';
        final String weight = data['weight']?.toString() ?? '65';
        final String height = data['height']?.toString() ?? '170';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                          const Color(0xFFC6934A).withOpacity(0.15),
                          const Color(0xFF151515),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFC6934A).withOpacity(0.1),
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
                                    color: AppColors.primary, width: 2),
                                color: const Color(0xFF151515),
                              ),
                              child: ClipOval(
                                child: _imagePath != null
                                    ? Image.file(File(_imagePath!),
                                        fit: BoxFit.cover)
                                    : const Icon(Icons.person_outline_rounded,
                                        color: AppColors.primary, size: 40),
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
                                      color: AppColors.primary.withOpacity(0.8),
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
                            _buildStatItem('Height', '$height cm'),
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
                            builder: (context) => const EditProfileScreen()),
                      );
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
                    onTap: () => WeightUpdateModal.show(context, weight),
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
                    value: true,
                    onChanged: (v) {},
                  ),

                  const SizedBox(height: 32),
                  // SUBSCRIPTION Section
                  _buildSectionLabel('SUBSCRIPTION'),
                  _buildMenuCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Manage Subscription',
                    subtitle: 'Premium Plan • \$9.99/week',
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),
                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _authService.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: AppColors.primary, size: 20),
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

                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Best-U Version 1.0.0',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '© 2026 Best-U Fitness',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white.withOpacity(0.2),
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
        );
      },
    );
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
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
                  color: Colors.white38,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 24),
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
          activeColor: AppColors.primary,
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
      color: Colors.white.withOpacity(0.05),
    );
  }
}
