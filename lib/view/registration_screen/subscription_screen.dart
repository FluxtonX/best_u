import 'dart:convert';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
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
  bool _isLoading = false;
  bool _isCheckingStatus = true;

  // Active plan after purchase (null = no plan yet)
  Map<String, dynamic>? _activePlan;

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
        'Exercise guidance and form tips',
        'Personal best celebrations',
        'Weekly progress reports',
      ],
    },
    {
      'title': 'Best-U Gain Weight',
      'price': '9.99',
      'period': 'month',
      'priceId': 'price_gain_weight_monthly',
      'features': [
        'Mass building workout protocols',
        'Strength progression tracking',
        'Nutrition guidelines for bulking',
        'Exercise form analysis',
        'Weekly weight tracking',
        'Community support access',
      ],
    },
    {
      'title': 'Best-U Combo',
      'price': '14.99',
      'period': 'month',
      'priceId': 'price_combo_monthly',
      'features': [
        'Full access to all programs',
        'Advanced analytics dashboard',
        'Priority coach support',
        'Exclusive nutrition plans',
        'Custom workout generator',
        'Offline mode access',
      ],
    },
  ];

  // Reverse lookup: priceId → plan data
  Map<String, dynamic>? _planByPriceId(String priceId) {
    try {
      return _plans.firstWhere((p) => p['priceId'] == priceId);
    } catch (_) {
      return null;
    }
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checkExistingSubscription();
  }

  /// Check Firestore for an existing active plan on screen open.
  Future<void> _checkExistingSubscription() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getSubscriptionStatus();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isActive = data['data']?['isActive'] == true;
        final priceId = data['data']?['priceId'] as String?;
        if (isActive && priceId != null) {
          final plan = _planByPriceId(priceId);
          if (mounted) {
            setState(() {
              _activePlan = plan;
              _isCheckingStatus = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Subscription check error: $e');
    }
    if (mounted) setState(() => _isCheckingStatus = false);
  }

  // ─── Payment helpers ──────────────────────────────────────────────────────

  Future<void> _showPaymentSheet(Map<String, dynamic> plan) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentSheet(plan: plan),
    );

    if (confirmed == true) {
      await _processPayment(plan['priceId'] as String, plan);
    }
  }

  /// Saves subscription to Firebase and updates UI to show the active plan card.
  Future<void> _processPayment(
      String priceId, Map<String, dynamic> plan) async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.checkout(priceId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        setState(() {
          _activePlan = plan;
          _isLoading = false;
        });
        _showSuccessSnackbar(plan['title'] as String);
      } else {
        throw 'Payment failed. Please try again.';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String planTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "$planTitle" activated successfully!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCheckingStatus
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _activePlan != null
              ? _buildActivePlanView(_activePlan!)
              : _buildPlanSelector(),
    );
  }

  // ─── Active Plan View (shown after purchase) ──────────────────────────────

  Widget _buildActivePlanView(Map<String, dynamic> plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ACTIVE PLAN',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Crown icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),

          // Plan title
          Text(
            plan['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '8 Week Transformation Program',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.primary.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // Price card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '/${plan['period']}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.primary.withOpacity(0.5),
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cancel anytime, no commitment',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.white.withOpacity(0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What's Included",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ...(plan['features'] as List<String>)
                    .map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cancel info note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.white.withOpacity(0.4), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To cancel or change your plan, contact support.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Plan Selector (no active plan) ──────────────────────────────────────

  Widget _buildPlanSelector() {
    return Column(
      children: [
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
        const SizedBox(height: 20),
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
                    : AppColors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Crown Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              plan['title'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '8 Week Transformation Program',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            // Pricing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
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
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '/${plan['period']}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.primary.withOpacity(0.5),
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancel anytime, no commitment',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.primary.withOpacity(0.4),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Start Monthly Plan button → opens payment sheet ────────────
            AppBounceAnimation(
              onTap: _isLoading ? () {} : () => _showPaymentSheet(plan),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        )
                      : const Text(
                          'Start Monthly Plan',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Features
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.03),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(plan['features'] as List<String>)
                      .map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'By subscribing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.primary.withOpacity(0.4),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Confirmation Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> plan;

  const _PaymentSheet({required this.plan});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Secure Payment',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Order summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '\$${plan['price']}/${plan['period']}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.07)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total today',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${plan['price']}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Colors.green.shade400, size: 15),
              const SizedBox(width: 6),
              Text(
                '256-bit SSL encryption • Cancel anytime',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Confirm Pay button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() => _isProcessing = true);
                      Navigator.pop(context, true); // return confirmed = true
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                  : Text(
                      'Pay \$${plan['price']}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
