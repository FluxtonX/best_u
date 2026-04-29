import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/registration_screen/widgets/option_card.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _selectedGoal = 'Gain Strength';
  String _selectedExperience = 'Intermediate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Edit
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.darkGrey,
                    child: Icon(Icons.person_outline_rounded,
                        color: AppColors.white, size: 50),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: AppColors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionHeader('PERSONAL INFORMATION'),
            const AuthTextField(
              label: 'Full Name',
              hintText: 'Enter your name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    label: 'Age',
                    hintText: 'Age',
                    prefixIcon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: AuthTextField(
                    label: 'Height (cm)',
                    hintText: 'Height',
                    prefixIcon: Icons.height_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const AuthTextField(
              label: 'Current Weight (kg)',
              hintText: 'Weight',
              prefixIcon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('FITNESS GOAL'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildGoalCard('Lose Weight'),
                _buildGoalCard('Gain Strength'),
                _buildGoalCard('Build Muscle'),
                _buildGoalCard('Improve Endurance'),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('EXPERIENCE LEVEL'),
            Row(
              children: [
                _buildExpCard('Beginner'),
                const SizedBox(width: 8),
                _buildExpCard('Intermediate'),
                const SizedBox(width: 8),
                _buildExpCard('Advanced'),
              ],
            ),

            const SizedBox(height: 48),
            AuthButton(
              text: 'Save Changes',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 40),
          ],
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

  Widget _buildGoalCard(String title) {
    final isSelected = _selectedGoal == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = title),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.darkGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.white.withOpacity(0.05),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isSelected
                ? AppColors.primary
                : AppColors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildExpCard(String title) {
    final isSelected = _selectedExperience == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedExperience = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.darkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.white.withOpacity(0.05),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isSelected
                  ? AppColors.primary
                  : AppColors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
