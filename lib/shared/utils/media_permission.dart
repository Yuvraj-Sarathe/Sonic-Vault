import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures Android media access (READ_MEDIA_AUDIO on API 33+,
/// READ_EXTERNAL_STORAGE below) is granted before scanning music.
///
/// Returns true when the caller may proceed. On denial the system dialog
/// often cannot be re-shown (after "Don't ask again" or a couple of denials),
/// so the user is offered an "Open Settings" action to enable
/// "Music and audio" access manually.
///
/// Callers should guard with [Platform.isAndroid] on platforms where this
/// permission does not exist.
Future<bool> ensureMediaPermission(BuildContext context) async {
  final status = await Permission.audio.request();
  if (status.isGranted) return true;

  if (!context.mounted) return false;
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Media access needed'),
      content: const Text(
        'SonicVault needs permission to read your music files before '
        'scanning. Tap "Open Settings" and allow "Music and audio" access.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );

  if (openSettings == true) {
    await Permission.openAppSettings();
  }
  return false;
}
