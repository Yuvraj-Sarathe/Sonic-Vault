import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures Android media access (READ_MEDIA_AUDIO on API 33+,
/// READ_EXTERNAL_STORAGE below) is granted before scanning music.
///
/// Returns true when the caller may proceed. On first use Android shows its
/// own system permission dialog (the standard grey popup) — nothing in-app
/// can replace it, since only the OS can grant permissions. When the user
/// previously denied with "Don't ask again" (or after repeated denials),
/// Android refuses to show that dialog ever again and the permission can
/// only be granted from the app settings page; this helper offers exactly
/// that recovery path, and nothing else.
///
/// Callers should guard with [Platform.isAndroid] on platforms where this
/// permission does not exist.
Future<bool> ensureMediaPermission(BuildContext context) async {
  var status = await Permission.audio.status;

  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    if (context.mounted) await _showRecoveryDialog(context);
    return false;
  }

  // First request — the OS shows its permission dialog (the grey popup).
  status = await Permission.audio.request();

  if (status.isGranted) return true;
  if (!context.mounted) return false;

  if (status.isPermanentlyDenied) {
    await _showRecoveryDialog(context);
  } else {
    // Plain denial: the system dialog will reappear on the next attempt,
    // matching how other apps behave.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Media access needed'),
        content: const Text(
          'SonicVault needs permission to read your music files. '
          'Tap "Scan Music Folder" again and press Allow when the system '
          'dialog appears.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  return false;
}

Future<void> _showRecoveryDialog(BuildContext context) async {
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Media access needed'),
      content: const Text(
        'Android no longer shows the permission dialog for this app '
        '(it was denied with "Don\'t ask again" earlier). Tap "Open '
        'Settings" and allow "Music and audio" access, then come back '
        'and scan again.',
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
    await openAppSettings();
  }
}
