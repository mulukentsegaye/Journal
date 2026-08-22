import 'dart:io';
import 'package:flutter/material.dart';

/// Fullscreen or modal viewer for a daily moment photo.
class PhotoViewerDialog extends StatelessWidget {
  final String photoUrl;
  final String? caption;

  const PhotoViewerDialog({
    super.key,
    required this.photoUrl,
    this.caption,
  });

  static void show(BuildContext context, {required String photoUrl, String? caption}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => PhotoViewerDialog(photoUrl: photoUrl, caption: caption),
    );
  }

  Widget _buildImage() {
    final isNetwork = photoUrl.startsWith('http://') || photoUrl.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        photoUrl,
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

    final file = File(photoUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }

    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar with close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),

          // Zoomable photo view
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.8,
                  child: _buildImage(),
                ),
              ),
            ),
          ),

          if (caption != null && caption!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                caption!,
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
