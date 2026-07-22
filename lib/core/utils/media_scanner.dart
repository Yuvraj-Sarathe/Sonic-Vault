import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'file_utils.dart';

/// Scans for audio files using platform-specific APIs.
///
/// On Android 11+ with a user-picked SAF folder, uses [DocumentsContract]
/// via a method channel to walk the selected tree. Falls back to [MediaStore]
/// query when no SAF folder has been selected.
/// On other platforms (Windows, macOS, Linux), falls back to [FileUtils.scanDirectory].
class MediaScanner {
  static const _channel = MethodChannel('com.sonicvault/scanner');

  /// Pick a folder using the native SAF folder picker (Android).
  ///
  /// Returns the raw `content://` tree URI, or `null` if the user cancelled.
  /// Unlike `file_picker.getDirectoryPath()`, this does NOT convert the URI
  /// to a filesystem path — it returns the SAF content URI directly so the
  /// tree walker can use it.
  static Future<String?> pickFolder() async {
    if (Platform.isAndroid) {
      try {
        final uri = await _channel.invokeMethod<String>('pickFolder');
        return uri;
      } on MissingPluginException {
        return null;
      } on PlatformException catch (e) {
        debugPrint('SonicVault: pickFolder error [${e.code}]: ${e.message}');
        return null;
      }
    }
    return null;
  }

  /// Persist the SAF tree URI permission so it survives app restarts.
  static Future<void> persistFolderPermission(String treeUri) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod(
          'takePersistableUriPermission',
          {'uri': treeUri},
        );
      } catch (_) {
        // Non-fatal — permission may already be held
      }
    }
  }

  /// Scan a directory (or SAF tree) for audio files.
  ///
  /// On Android, [dirPath] is a SAF tree URI (content://...) from the folder
  /// picker. The method channel walks the document tree recursively.
  /// On other platforms, scans [dirPath] recursively using [FileUtils.scanDirectory].
  ///
  /// Returns a list of file paths (desktop) or content URIs (Android SAF).
  static Future<List<String>> scanAudioFiles(String dirPath) async {
    // Android: use SAF tree walker via method channel
    if (Platform.isAndroid) {
      return _scanAndroid(dirPath);
    }

    // Other platforms: use dart:io file scanning
    final files = await FileUtils.scanDirectory(dirPath);
    return files.map((f) => f.path).toList();
  }

  /// Android-specific scanner.
  ///
  /// If [dirPath] is a SAF tree URI, uses [DocumentsContract] to walk the
  /// user-picked folder tree. Otherwise falls back to the legacy [MediaStore]
  /// device-wide query.
  static Future<List<String>> _scanAndroid(String dirPath) async {
    final isTreeUri = dirPath.startsWith('content://');

    if (isTreeUri) {
      try {
        final paths = await _channel.invokeListMethod<String>(
          'scanFolder',
          {'treeUri': dirPath},
        );
        return paths ?? [];
      } on MissingPluginException {
        return [];
      } on PlatformException catch (e) {
        debugPrint('SonicVault: SAF tree scan error [${e.code}]: ${e.message}');
        return [];
      } catch (e) {
        debugPrint('SonicVault: SAF tree scan failed: $e');
        return [];
      }
    }

    // Fallback to legacy MediaStore scan for backward compatibility
    try {
      final paths = await _channel.invokeListMethod<String>('scanMusic');
      if (paths == null || paths.isEmpty) return [];

      return paths.where((p) => p.isNotEmpty).toList();
    } on MissingPluginException {
      return [];
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint('SonicVault: Permission denied for MediaStore scan');
      } else {
        debugPrint(
          'SonicVault: MediaStore scan error [${e.code}]: ${e.message}',
        );
      }
      return [];
    } catch (e) {
      debugPrint('SonicVault: MediaStore scan failed: $e');
      return [];
    }
  }
}
