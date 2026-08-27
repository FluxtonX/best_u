import 'dart:io';
import 'package:best_u/constant/app_theme_color.dart';
import 'package:best_u/services/api_service.dart';
import 'package:best_u/view/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shown when the user completes their 8-week program.
/// Prompts them to upload their "After" transformation photo.
class AfterPhotoPromptDialog extends StatefulWidget {
  final String? beforePhotoUrl;
  final VoidCallback? onComplete;

  const AfterPhotoPromptDialog({
    super.key,
    this.beforePhotoUrl,
    this.onComplete,
  });

  static Future<void> show(BuildContext context,
      {String? beforePhotoUrl, VoidCallback? onComplete}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => AfterPhotoPromptDialog(
        beforePhotoUrl: beforePhotoUrl,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<AfterPhotoPromptDialog> createState() => _AfterPhotoPromptDialogState();
}

class _AfterPhotoPromptDialogState extends State<AfterPhotoPromptDialog>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isUploading = false;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _sheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _sheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndClose() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);
    try {
      final res = await ApiService().uploadAfterPhoto(_selectedImage!);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw 'Failed to upload photo (${res.statusCode})';
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onComplete?.call();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Error saving photo: $e',
          type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _entryAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trophy icon + title
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 34)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "You finished the\n8-Week Program!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Upload your After photo to\ncomplete your transformation story.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Before / After side by side
                Row(
                  children: [
                    // Before
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.07)),
                              image: widget.beforePhotoUrl != null &&
                                      !widget.beforePhotoUrl!
                                          .startsWith('data:')
                                  ? DecorationImage(
                                      image:
                                          NetworkImage(widget.beforePhotoUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: widget.beforePhotoUrl == null
                                ? Center(
                                    child: Text('No before\nphoto',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          fontSize: 11,
                                        )))
                                : null,
                          ),
                          const SizedBox(height: 6),
                          const Text('BEFORE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // After upload area
                    Expanded(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showSourcePicker,
                            child: Container(
                              height: 130,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedImage != null
                                      ? AppColors.primary
                                      : AppColors.primary
                                          .withValues(alpha: 0.3),
                                  width: _selectedImage != null ? 2 : 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add_a_photo_rounded,
                                              color: AppColors.primary,
                                              size: 28),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tap to\nupload',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AFTER',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: _selectedImage != null
                                  ? AppColors.primary
                                  : AppColors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upload button
                if (_selectedImage != null)
                  GestureDetector(
                    onTap: _isUploading ? null : _uploadAndClose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFF8C42)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Save My Transformation 🔥',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Skip
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Text(
                      'Maybe later',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
