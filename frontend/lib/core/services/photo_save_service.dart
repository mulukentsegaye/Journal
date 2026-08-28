import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Cross-platform service to save and export reflection photos to local device storage (Android, Windows, iOS, macOS).
class PhotoSaveService {
  static final PhotoSaveService _instance = PhotoSaveService._internal();
  factory PhotoSaveService() => _instance;
  PhotoSaveService._internal();

  /// Downloads or reads the photo bytes and saves it to the user's local Pictures or Downloads directory.
  /// Returns the saved absolute file path on success, or throws an error message.
  Future<String> savePhotoToDevice({
    required String photoUrl,
    String? customPrefix,
  }) async {
    if (photoUrl.isEmpty) {
      throw 'No valid photo to save.';
    }

    try {
      Uint8List bytes;

      // 1. Obtain image bytes (from Network URL or local File)
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        final uri = Uri.parse(photoUrl);
        final response = await http.get(uri).timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          throw 'Failed to download photo from cloud (HTTP ${response.statusCode}).';
        }
        bytes = response.bodyBytes;
      } else {
        final file = File(photoUrl);
        if (!await file.exists()) {
          throw 'Local photo file not found on this device.';
        }
        bytes = await file.readAsBytes();
      }

      if (bytes.isEmpty) {
        throw 'Image data is empty.';
      }

      // 2. Determine target save directory based on platform
      Directory? targetDir;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final prefix = customPrefix?.trim().isNotEmpty == true
          ? customPrefix!.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_')
          : 'DailyReflection';
      final filename = '${prefix}_$timestamp.jpg';

      if (Platform.isWindows) {
        // Try user Pictures directory first, then Downloads, then App Documents
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final picturesDir = Directory('$userProfile\\Pictures');
          if (picturesDir.existsSync()) {
            targetDir = picturesDir;
          } else {
            final downloadsDir = Directory('$userProfile\\Downloads');
            if (downloadsDir.existsSync()) {
              targetDir = downloadsDir;
            }
          }
        }
        targetDir ??= await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // Try public Download folder, then Pictures folder
        const publicDownloadPath = '/storage/emulated/0/Download';
        const publicPicturesPath = '/storage/emulated/0/Pictures';

        if (Directory(publicDownloadPath).existsSync()) {
          targetDir = Directory(publicDownloadPath);
        } else if (Directory(publicPicturesPath).existsSync()) {
          targetDir = Directory(publicPicturesPath);
        } else {
          targetDir = await getExternalStorageDirectory() ??
              await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS / macOS / Linux
        targetDir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      // 3. Write bytes to destination file
      final sep = Platform.pathSeparator;
      final destPath = '${targetDir.path}$sep$filename';
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes, flush: true);

      debugPrint('[PhotoSaveService] ✓ Successfully saved photo to: $destPath');
      return destPath;
    } catch (e) {
      debugPrint('[PhotoSaveService] ✗ Failed to save photo: $e');
      rethrow;
    }
  }
}
