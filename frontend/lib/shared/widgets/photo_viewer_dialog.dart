import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/photo_save_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_formatter.dart';

/// Fullscreen or modal viewer for moment photos with pinch-to-zoom,
/// multi-photo swiping, and save-to-device capability.
class PhotoViewerDialog extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String? caption;

  PhotoViewerDialog({
    super.key,
    String? photoUrl,
    List<String>? photos,
    this.initialIndex = 0,
    this.caption,
  }) : photos = photos ?? (photoUrl != null && photoUrl.isNotEmpty ? [photoUrl] : const []);

  static void show(
    BuildContext context, {
    String? photoUrl,
    List<String>? photos,
    int initialIndex = 0,
    String? caption,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => PhotoViewerDialog(
        photoUrl: photoUrl,
        photos: photos,
        initialIndex: initialIndex,
        caption: caption,
      ),
    );
  }

  @override
  State<PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<PhotoViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;
  final Set<int> _savedIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.photos.isEmpty ? 0 : widget.photos.length - 1,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _currentPhotoUrl =>
      widget.photos.isNotEmpty ? widget.photos[_currentIndex] : '';

  Future<void> _savePhoto() async {
    if (_isSaving) return;
    if (_currentPhotoUrl.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final savedPath = await PhotoSaveService().savePhotoToDevice(
        photoUrl: _currentPhotoUrl,
        customPrefix: widget.caption,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedIndices.add(_currentIndex);
        });

        final filename = savedPath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo saved.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        filename,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(ErrorFormatter.format(e))),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildImage(String url) {
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          );
        },
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 48),
          SizedBox(height: 8),
          Text(
            'Photo file not found locally',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedCurrent = _savedIndices.contains(_currentIndex);
    final count = widget.photos.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top Bar: Save Button, Counter & Close Button ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Save button
              GestureDetector(
                onTap: _savePhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasSavedCurrent
                        ? const Color(0xFF2E7D32)
                        : AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          hasSavedCurrent
                              ? Icons.check_circle_outline_rounded
                              : Icons.file_download_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        hasSavedCurrent
                            ? 'Saved'
                            : (Platform.isWindows ? 'Save to PC' : 'Save Photo'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page counter (if multiple photos)
              if (count > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Close button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Zoomable photo view (or PageView for multiple) ────────
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: count <= 1
                    ? InteractiveViewer(
                        maxScale: 4.0,
                        minScale: 0.8,
                        child: _buildImage(_currentPhotoUrl),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: count,
                        onPageChanged: (idx) => setState(() => _currentIndex = idx),
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            maxScale: 4.0,
                            minScale: 0.8,
                            child: _buildImage(widget.photos[index]),
                          );
                        },
                      ),
              ),
            ),
          ),

          // ── Caption / Title Bar ────────────────────────────────
          if (widget.caption != null && widget.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.caption!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
