import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/entitlement_service.dart';
import 'package:best_u/view/registration_screen/subscription_screen.dart';
import 'package:best_u/view/registration_screen/verification_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';

/// Professional modal that communicates access state and guides users
/// to submit verification for free complimentary Pro access.
class ProAccessModal extends StatelessWidget {
  final String? featureName;

  const ProAccessModal({super.key, this.featureName});

  /// Centralized helper to check Pro access.
  /// Returns `true` if user is verified (allowing execution to continue).
  /// Returns `false` and displays the modal if user is not verified.
  static Future<bool> checkAccess(BuildContext context,
      {String? featureName}) async {
    final entitlement = EntitlementService();
    if (!entitlement.isInitialized) {
      await entitlement.refreshStatus();
    }

    if (entitlement.hasProAccess) {
      return true;
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => ProAccessModal(featureName: featureName),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = EntitlementService();
    final state = entitlement.state;
    final note = entitlement.reviewNote;

    return AnimatedBuilder(
      animation: entitlement,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF14171A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF2A3238), width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Icon & Header based on State
              _buildHeaderIcon(state),
              const SizedBox(height: 18),

              // Title
              Text(
                _getTitle(state),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Feature Name Pill (if passed)
              if (featureName != null && featureName!.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '🔒 Pro Feature: $featureName',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Message Body
              Text(
                _getMessage(state),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),

              // Optional Admin Feedback Note (for rejected state)
              if (state == VerificationState.rejected &&
                  note != null &&
                  note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1515),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.redAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Review Feedback:',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Main CTA Action Button
              AppBounceAnimation(
                onTap: () => _handlePrimaryAction(context, state),
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getButtonText(state),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Dismiss / View Details Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withValues(alpha: 0.5),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderIcon(VerificationState state) {
    Color ringColor;
    IconData iconData;

    switch (state) {
      case VerificationState.pending:
        ringColor = const Color(0xFFF59E0B);
        iconData = Icons.hourglass_top_rounded;
        break;
      case VerificationState.rejected:
        ringColor = const Color(0xFFEF4444);
        iconData = Icons.error_outline_rounded;
        break;
      default:
        ringColor = AppColors.primary;
        iconData = Icons.lock_outline_rounded;
        break;
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: 0.12),
        border: Border.all(color: ringColor.withValues(alpha: 0.35), width: 2),
      ),
      child: Center(
        child: Icon(iconData, color: ringColor, size: 34),
      ),
    );
  }

  String _getTitle(VerificationState state) {
    switch (state) {
      case VerificationState.pending:
        return 'Verification Under Review';
      case VerificationState.rejected:
        return 'Verification Not Approved';
      default:
        return 'Best-U Pro Access Required';
    }
  }

  String _getMessage(VerificationState state) {
    switch (state) {
      case VerificationState.pending:
        return 'Your verification request has been submitted and is currently under review. Free access will be enabled once your request is approved by the Best-U Team.';
      case VerificationState.rejected:
        return 'Your verification request was not approved. Please review the feedback and submit your verification again.';
      default:
        return 'Students and participating gym members can get complimentary access. Submit your ID or membership card for verification.';
    }
  }

  String _getButtonText(VerificationState state) {
    switch (state) {
      case VerificationState.pending:
        return 'View Verification Status ➔';
      case VerificationState.rejected:
        return 'Re-submit ID Card ➔';
      default:
        return 'Claim Free Student / Gym Access 🎓';
    }
  }

  void _handlePrimaryAction(BuildContext context, VerificationState state) {
    Navigator.pop(context); // Close bottom sheet
    if (state == VerificationState.pending) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerificationScreen()),
      );
    }
  }
}
