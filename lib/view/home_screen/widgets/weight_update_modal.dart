import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_bounce_animation.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

class WeightUpdateModal extends StatefulWidget {
  final String currentWeight;
  const WeightUpdateModal({super.key, required this.currentWeight});

  static Future<void> show(BuildContext context, String currentWeight) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => WeightUpdateModal(currentWeight: currentWeight),
    );
  }

  @override
  State<WeightUpdateModal> createState() => _WeightUpdateModalState();
}

class _WeightUpdateModalState extends State<WeightUpdateModal> {
  late TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.currentWeight);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _updateWeight() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
      
      final results = await Future.wait([
        apiService.updateProfile({'weight': weight}),
        apiService.logWeight(weight, DateTime.now().toIso8601String()),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200) {
        Navigator.pop(context);
      } else {
        AppSnackBar.show(context, 'Error updating weight: ${results[0].body}',
            type: AppSnackType.error);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error: $e', type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  'Update Weight',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppBounceAnimation(
                  onTap: () => Navigator.pop(context),
                  scaleFactor: 0.88,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep your weight updated to track\nprogress accurately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Input Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Current Weight (kg)',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: TextField(
                style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            AppBounceAnimation(
              onTap: _isLoading ? null : _updateWeight,
              isDisabled: _isLoading,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: _isLoading ? 56 : constraints.maxWidth,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(_isLoading ? 28 : 16),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF151515),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Update Weight',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Color(0xFF151515),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
