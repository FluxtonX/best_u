import 'dart:io';

import 'package:best_u/constant/app_theme_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// A tappable banner card that copies the bundled Best-U PDF from
/// Flutter assets to the device's documents folder, then opens it
/// with the system PDF viewer. Can be placed on any screen.
class BookDownloadButton extends StatefulWidget {
  const BookDownloadButton({super.key});

  @override
  State<BookDownloadButton> createState() => _BookDownloadButtonState();
}

class _BookDownloadButtonState extends State<BookDownloadButton> {
  bool _isLoading = false;

  static const String _assetPath = 'assets/book/Best-U Book_v10 (1).pdf';
  static const String _fileName = 'Best-U_Book.pdf';

  Future<void> _openBook() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$_fileName';
      final file = File(filePath);

      // Copy from assets if not already extracted
      if (!await file.exists()) {
        final data = await rootBundle.load(_assetPath);
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      }

      final result = await OpenFilex.open(filePath);
      if (mounted && result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open the book. Please install a PDF viewer.',
              style: TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('BookDownloadButton error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error opening book: $e',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openBook,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Book icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free Best-U Book',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to read your complete guide',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Action indicator
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(
                    Icons.file_open_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ],
        ),
      ),
    );
  }
}
