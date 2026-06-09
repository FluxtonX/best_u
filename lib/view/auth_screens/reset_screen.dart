import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/auth_screens/auth_services.dart';
import 'package:best_u/view/auth_screens/widgets/auth_button.dart';
import 'package:best_u/view/auth_screens/widgets/auth_text_field.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

class ResetScreen extends StatefulWidget {
  final String oobCode;

  const ResetScreen({super.key, required this.oobCode});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isVerifying = true;
  bool _isResetting = false;
  String? _verifiedEmail;
  String? _linkError;

  bool get _hasMinLength => _passwordController.text.trim().length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _isPasswordValid => _hasMinLength && _hasNumber && _hasUppercase;

  @override
  void initState() {
    super.initState();
    _verifyResetLink();
    _passwordController.addListener(_refreshPasswordState);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordState);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _refreshPasswordState() {
    if (mounted) setState(() {});
  }

  Future<void> _verifyResetLink() async {
    try {
      final email =
          await _authService.verifyPasswordResetCode(widget.oobCode.trim());
      if (!mounted) return;
      setState(() {
        _verifiedEmail = email;
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _linkError = e.toString();
        _isVerifying = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isPasswordValid) {
      AppSnackBar.show(
        context,
        'Password must meet all requirements.',
        type: AppSnackType.warning,
      );
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.show(
        context,
        'Passwords do not match.',
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      await _authService.confirmPasswordReset(
        code: widget.oobCode.trim(),
        newPassword: password,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Password updated. Please sign in again.',
        type: AppSnackType.success,
      );
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.05),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: AppColors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Reset Password',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isVerifying) {
      return Column(
        children: [
          Text(
            'Verifying your Firebase reset link...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      );
    }

    if (_linkError != null) {
      return Column(
        children: [
          Text(
            _linkError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white.withValues(alpha: 0.5),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          AuthButton(
            text: 'Back to Sign In',
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Verified for ${_verifiedEmail ?? 'your account'}. Create a new secure password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        AuthTextField(
          controller: _passwordController,
          label: 'New Password',
          hintText: 'Create a strong password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PASSWORD REQUIREMENTS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildRequirement('Minimum 8 characters', _hasMinLength),
              _buildRequirement('One number', _hasNumber),
              _buildRequirement('One uppercase letter', _hasUppercase),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AuthTextField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hintText: 'Re-enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 48),
        AuthButton(
          text: 'Update Password',
          isLoading: _isResetting,
          onPressed: _resetPassword,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.close_rounded,
            color:
                isMet ? Colors.green : AppColors.white.withValues(alpha: 0.3),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              color:
                  isMet ? Colors.green : AppColors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
