import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/home_screen/edit_profile_screen.dart';
import 'package:best_u/view/home_screen/widgets/weight_update_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  final AuthService _authService = AuthService();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your account settings',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person_outline_rounded,
                          color: AppColors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rahmat',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Intermediate • Build Strength',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ProfileStat(label: 'Age', value: '24'),
                        _ProfileStat(label: 'Weight', value: '65 kg'),
                        _ProfileStat(label: 'Height', value: '170 cm'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Settings Groups
              _buildSectionHeader('PROFILE'),
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.monitor_weight_outlined,
                title: 'Update Weight',
                trailing: Text(
                  '65 kg',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                onTap: () => WeightUpdateModal.show(context),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('APP SETTINGS'),
              _buildSwitchItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                value: true,
                onChanged: (v) {},
              ),
              _buildSwitchItem(
                icon: Icons.volume_up_outlined,
                title: 'Sound Effects',
                value: true,
                onChanged: (v) {},
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('SUBSCRIPTION'),
              _buildMenuItem(
                icon: Icons.workspace_premium_outlined,
                title: 'Manage Subscription',
                subtitle: 'Premium Plan • \$9.99/week',
                onTap: () {},
              ),

              const SizedBox(height: 48),
              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    _authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Best-U Version 1.0.0',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.2),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '© 2024 Best-U Fitness',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.2),
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
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                color: AppColors.white.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: CupertinoSwitch(
          activeColor: AppColors.primary,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
