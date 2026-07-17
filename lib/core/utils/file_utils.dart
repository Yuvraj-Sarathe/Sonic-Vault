import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String generateFileId(String filePath) {
    final bytes = utf8.encode(filePath);
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// Extract the last path segment (filename) from a file path or content URI.
  static String getFileName(String path) {
    if (path.startsWith('content://')) {
      final decoded = Uri.decodeComponent(Uri.parse(path).pathSegments.last);
      return decoded.split('/').last;
    }
    return path.split(RegExp(r'[/\\]')).last;
  }

  static String getFileExtension(String path) {
    if (path.startsWith('content://')) {
      final name = getFileName(path);
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex < 0 || dotIndex >= name.length - 1) return '';
      return name.substring(dotIndex).toLowerCase();
    }
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= path.length - 1) return '';
    return path.substring(dotIndex).toLowerCase();
  }

  static String getFileNameWithoutExtension(String path) {
    final name = getFileName(path);
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  static bool isAudioFile(String path) {
    final ext = getFileExtension(path);
    return AppConstants.supportedAudioFormats.contains(ext);
  }

  static bool isImageFile(String path) {
    final ext = getFileExtension(path);
    return AppConstants.supportedImageFormats.contains(ext);
  }

  static bool isLyricFile(String path) {
    final ext = getFileExtension(path);
    return AppConstants.supportedLyricFormats.contains(ext);
  }

  static Future<List<File>> scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    final audioFiles = <File>[];
    if (!await dir.exists()) return audioFiles;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && isAudioFile(entity.path)) {
        audioFiles.add(entity);
      }
    }
    return audioFiles;
  }

  static String sanitizeFileName(String name) {
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(invalidChars, '_');
  }
}
