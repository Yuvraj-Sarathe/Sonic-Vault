import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'file_utils.dart';

/// Scans for audio files using platform-specific APIs.
///
/// On Android 11+, uses [MediaStore] API via a method channel because
/// [Directory.list]() cannot access shared storage on modern Android.
/// On other platforms (Windows, macOS, Linux), falls back to [FileUtils.scanDirectory].
class MediaScanner {
  static const _channel = MethodChannel('com.sonicvault/scanner');

  /// Scan a directory (or the whole device) for audio files.
  ///
  /// On Android, ignores [dirPath] and uses [MediaStore] to find all
  /// audio files on the device. On other platforms, scans [dirPath]
  /// recursively using [FileUtils.scanDirectory].
  static Future<List<File>> scanAudioFiles(String dirPath) async {
    // Android: use MediaStore API via method channel
    if (Platform.isAndroid) {
      return _scanAndroid();
    }

    // Other platforms: use dart:io file scanning
    return FileUtils.scanDirectory(dirPath);
  }

  /// Android-specific scanner using the MediaStore content provider.
  /// This is the only reliable way to access audio files on Android 11+.
  static Future<List<File>> _scanAndroid() async {
    try {
      final paths = await _channel.invokeListMethod<String>('scanMusic');
      if (paths == null || paths.isEmpty) return [];

      return paths
          .where((p) => p.isNotEmpty)
          .map((p) => File(p))
          .toList();
    } on MissingPluginException {
      // No platform implementation — return empty
      return [];
    } catch (e) {
      debugPrint('SonicVault: MediaStore scan failed: $e');
      return [];
    }
  }
}
