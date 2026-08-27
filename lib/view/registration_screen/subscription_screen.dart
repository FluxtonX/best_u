import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/entitlement_service.dart';
import 'package:best_u/view/registration_screen/verification_screen.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  bool _isCheckingStatus = true;

  // ─── Plan definitions ─────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Best-U Lose Weight',
      'price': '9.99',
      'period': 'month',
      'priceId': 'price_lose_weight_monthly',
      'features': [
        'Structured 8-week workout plan',
        'Performance tracking for every exercise',
        'Progress analytics and insights',
        'Exercise guidance and video demos',
        'Personal best celebrations',
        'Nutrition & fasting guidelines',
      ],
    },
    {
      'title': 'Best-U Gain Strength',
      'price': '9.99',
      'period': 'month',
      'priceId': 'price_gain_weight_monthly',
      'features': [
        'Mass building workout protocols',
        'Strength progression tracking',
        'Exercise form & technique guide',
        'Hypertrophy nutrition protocols',
        'Personal record analytics',
        'Coach milestone tracking',
      ],
    },
    {
      'title': 'Best-U Combo',
      'price': '14.99',
      'period': 'month',
      'priceId': 'price_combo_monthly',
      'features': [
        'Full access to all workout programs',
        'Advanced body composition tracker',
        'Custom meal ideas & macro plans',
        'Video exercises & audio cues',
        'Priority feature updates',
        'Full transformation suite',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final entitlement = EntitlementService();
    await entitlement.refreshStatus();
    if (mounted) {
      setState(() => _isCheckingStatus = false);
    }
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '💳 Paid subscriptions are coming soon! Students and gym members get 100% free access via verification.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = EntitlementService();

    return AnimatedBuilder(
      animation: entitlement,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Best-U Membership',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: _isCheckingStatus
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : entitlement.isVerified
                  ? _buildVerifiedActiveView(entitlement)
                  : _buildPlanSelector(entitlement),
        );
      },
    );
  }

  // ─── Active Verified View (Shown when Admin has approved user) ────────────
  Widget _buildVerifiedActiveView(EntitlementService entitlement) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Active Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                SizedBox(width: 8),
                Text(
                  'COMPLIMENTARY ACCESS ACTIVE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF22C55E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Crown icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Best-U Pro Activated',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${entitlement.verificationType == 'student' ? 'Student' : 'Gym Partner'} Verification Approved ✓',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),

          // Verification Info Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                if (entitlement.idNumber != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified ID Number',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entitlement.idNumber!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Access Entitlement',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      '100% Free Pro Tier',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Included with Best-U Pro",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _featureRow('All 8-week guided workout programs'),
                _featureRow('All HD exercise videos & audio coaching'),
                _featureRow('Custom meal plans & nutrition tools'),
                _featureRow('Performance analytics & personal bests'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Continue button
          AppBounceAnimation(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 56,
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
              child: const Center(
                child: Text(
                  'Continue Training 🚀',
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.primary, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Plan Selector View (Shown when user is not verified) ─────────────────
  Widget _buildPlanSelector(EntitlementService entitlement) {
    return Column(
      children: [
        // Top Status Alert Bar based on Verification State
        _buildVerificationStatusBanner(entitlement),

        // Carousel of Plans
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
              return _buildPlanCard(plan);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _plans.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Student / Gym Member verification CTA Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerificationScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      entitlement.isPending
                          ? 'ID Verification In Review (Tap to Update)'
                          : entitlement.isRejected
                              ? 'Verification Not Approved (Tap to Re-submit)'
                              : 'Student or Gym Member? Claim Free Access',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVerificationStatusBanner(EntitlementService entitlement) {
    if (entitlement.isPending) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your verification request is currently under review by the Best-U Team.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFFF59E0B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (entitlement.isRejected) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verification was not approved. Please tap below to re-submit your ID card.',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFFEF4444),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Crown Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              plan['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '8 Week Transformation Program',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            // Pricing Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$${plan['price']}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '/${plan['period']}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary.withValues(alpha: 0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancel anytime • No commitment',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start Monthly Plan button → Shows Coming Soon
            AppBounceAnimation(
              onTap: _showComingSoonSnackbar,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Select Plan (Coming Soon)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features List
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.03),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's Included",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...(plan['features'] as List<String>)
                      .map((feature) => _featureRow(feature)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
