import 'dart:convert';
import 'dart:io';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGoal = 'Gain Strength';
  String _selectedExperience = 'Intermediate';
  String? _imagePath;
  bool _isLoading = false;
  bool _isFetching = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    setState(() {
      _imagePath = prefs.getString('profile_image_path_$uid');
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        final prefs = await SharedPreferences.getInstance();
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
        await prefs.setString('profile_image_path_$uid', image.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getProfile();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _heightController.text = data['bmi']?.toString() ?? '';
          _weightController.text = data['weight']?.toString() ?? '';
          _selectedGoal = data['goal'] ?? 'Gain Strength';
          _selectedExperience = data['fitnessLevel'] ?? 'Intermediate';
          _isFetching = false;
        });
      } else {
        setState(() => _isFetching = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => _isFetching = false);
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.updateProfile({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'bmi': double.tryParse(_heightController.text.trim()),
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'goal': _selectedGoal,
        'fitnessLevel': _selectedExperience,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        AppSnackBar.show(context, 'Profile updated successfully',
            type: AppSnackType.success);
        Navigator.pop(context);
      } else {
        AppSnackBar.show(context, 'Error updating profile: ${response.body}',
            type: AppSnackType.error);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error updating profile: $e',
          type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
                child: AppBounceAnimation(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF151515),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.05), width: 1),
                        ),
                        child: ClipOval(
                          child: _imagePath != null
                              ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                              : const Icon(Icons.person_outline_rounded,
                                  color: Colors.white24, size: 50),
                        ),
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
                              color: Color(0xFF151515), size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tap to change photo',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
  
              _buildSectionHeader('PERSONAL INFORMATION'),
              _buildInputField(
                label: 'Full Name',
                controller: _nameController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Age',
                      keyboardType: TextInputType.number,
                      controller: _ageController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputField(
                      label: 'BMI (If known)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _heightController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Current Weight (kg)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _weightController,
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
                  _buildGoalCard('Combo'),
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
              Row(
                children: [
                  Expanded(
                    child: AppBounceAnimation(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppBounceAnimation(
                      onTap: _isLoading ? null : _saveChanges,
                      isDisabled: _isLoading,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF151515), strokeWidth: 2.5))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_as_rounded,
                                        color: Color(0xFF151515), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: Color(0xFF151515),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
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
        style: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
                color: AppColors.primary,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(String title) {
    final isSelected = _selectedGoal == title;
    return AppBounceAnimation(
      onTap: () => setState(() => _selectedGoal = title),
      scaleFactor: 0.96,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildExpCard(String title) {
    final isSelected = _selectedExperience == title;
    return Expanded(
      child: AppBounceAnimation(
        onTap: () => setState(() => _selectedExperience = title),
        scaleFactor: 0.96,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isSelected ? Colors.white : Colors.white38,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
