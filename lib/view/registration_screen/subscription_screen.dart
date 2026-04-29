import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/view/home_screen/main_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:google_fonts/google_fonts.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/premium screen icon.svg',
                    width: 60,
                    height: 60,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header Titles
              Text(
                'Best-U Premium',
                style: TextStyle(fontFamily: 'Outfit', 
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '8 Week Transformation Program',
                style: TextStyle(fontFamily: 'Outfit', 
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),

              // Features Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's Included",
                      style: TextStyle(fontFamily: 'Outfit', 
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureRow('Structured 8-week workout plan'),
                    _buildFeatureRow('Performance tracking for every exercise'),
                    _buildFeatureRow('Progress analytics and insights'),
                    _buildFeatureRow('Exercise guidance and form tips'),
                    _buildFeatureRow('Personal best celebrations'),
                    _buildFeatureRow('Weekly progress reports'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Price Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\$9.99',
                            style: TextStyle(fontFamily: 'Outfit', 
                              color: AppColors.primary,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '/week',
                            style: TextStyle(fontFamily: 'Outfit', 
                              color: AppColors.white.withOpacity(0.5),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cancel anytime, no commitment',
                      style: TextStyle(fontFamily: 'Outfit', 
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              // Start Weekly Plan
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainHomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start Weekly Plan',
                    style: TextStyle(fontFamily: 'Outfit', 
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Pay Buttons
              Row(
                children: [
                  Expanded(child: _buildPayButton('Apple Pay', Icons.apple)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPayButton('Google Pay', Icons.payment)),
                ],
              ),

              const SizedBox(height: 32),

              // Legal Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'By subscribing, you agree to our Terms of Service\nand Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Outfit', 
                    color: AppColors.white.withOpacity(0.4),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(fontFamily: 'Outfit', 
                color: AppColors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(String text, IconData icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontFamily: 'Outfit', 
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
