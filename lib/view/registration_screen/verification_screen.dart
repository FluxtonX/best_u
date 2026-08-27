import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

/// Screen for students and gym members to submit ID verification
/// and get free access to the app.
class VerificationScreen extends StatefulWidget {
  final bool isFromOnboarding;

  const VerificationScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  String _selectedType = 'student';
  final TextEditingController _idController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _idController.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final idNumber = _idController.text.trim();
    if (idNumber.isEmpty) {
      AppSnackBar.show(context, 'Please enter your ID number',
          type: AppSnackType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService().submitVerificationRequest(
        type: _selectedType,
        idNumber: idNumber,
      );

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
      _checkCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.show(context, 'Submission failed: $e',
          type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 44)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Request Submitted!',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ID card has been submitted for review.\nOnce approved by our team, your 100% Free Best-U Pro access will be unlocked automatically! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Start My Transformation 🚀',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.isFromOnboarding) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (route) => false);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 16),
                ),
              ),
              if (widget.isFromOnboarding)
                GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Skip for Now ➔',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Header
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
              children: [
                TextSpan(
                    text: 'Claim Free\n',
                    style: TextStyle(color: AppColors.white)),
                TextSpan(
                    text: 'Access 🎓',
                    style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Students & partner gym members get the app completely free.',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Type selector
          _sectionLabel('I am a...'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _typeCard(
                  emoji: '🎓',
                  label: 'Student',
                  value: 'student',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _typeCard(
                  emoji: '🏋️',
                  label: 'Gym Member',
                  value: 'gym',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ID Number
          _sectionLabel(
            _selectedType == 'student'
                ? 'Student ID Number'
                : 'Membership ID Number',
          ),
          const SizedBox(height: 10),
          _inputField(
            controller: _idController,
            hint: _selectedType == 'student'
                ? 'e.g. STU-2024-0012'
                : 'e.g. GYM-00874',
          ),
          const SizedBox(height: 32),

          // Submit button
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Claim My Free Access',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          Center(
            child: Text(
              'Your information is private and secure.',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withValues(alpha: 0.25),
                fontSize: 12,
              ),
            ),
          ),
          if (widget.isFromOnboarding) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  'I am a Regular Member / Skip for Now ➔',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  Widget _typeCard({
    required String emoji,
    required String label,
    required String value,
  }) {
    final selected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: selected ? AppColors.primary : AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white.withValues(alpha: 0.25),
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
