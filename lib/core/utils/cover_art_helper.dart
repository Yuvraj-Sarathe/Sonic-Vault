import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

/// Helper class for managing cover art images: saving, loading, and caching.
class CoverArtHelper {
  static const String _coversDirName = 'covers';

  /// Get or create the application's covers directory.
  static Future<Directory> getCoversDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${appDir.path}/${_coversDirName}');
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  /// Generate a unique filename for a cover image based on a song/playlist ID.
  static String getCoverFileName(String id) => 'cover_$id.jpg';

  /// Get the full path for a cover image by ID.
  static Future<String> getCoverPath(String id) async {
    final dir = await getCoversDirectory();
    return '${dir.path}/${getCoverFileName(id)}';
  }

  /// Save image bytes to the covers directory keyed by [id].
  /// Returns the saved file path, or null on failure.
  static Future<String?> saveCoverImage(String id, Uint8List imageBytes) async {
    try {
      final path = await getCoverPath(id);
      await File(path).writeAsBytes(imageBytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Delete a cover image by [id].
  static Future<void> deleteCoverImage(String id) async {
    try {
      final path = await getCoverPath(id);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Generate a file hash from image bytes to detect duplicates.
  static String hashBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Check whether a cover file exists for the given [id].
  static Future<bool> hasCover(String id) async {
    final path = await getCoverPath(id);
    return File(path).exists();
  }

  /// Load a cover image as a flutter ImageProvider for a given database path
  /// or custom cover ID. [coverPath] can be a database coverArtPath value,
  /// or an app-covers-dir file path.
  static ImageProvider? imageProvider(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) return null;
    final file = File(coverPath);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }
}
