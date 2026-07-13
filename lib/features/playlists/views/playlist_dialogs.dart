import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/playlist_providers.dart';

/// Shows a confirmation dialog and deletes the playlist if confirmed.
/// Returns true if the playlist was deleted, false if cancelled.
Future<bool> confirmDeletePlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Playlist'),
      content: Text('Delete "${playlist.name}" and all its songs?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await ref.read(playlistDaoProvider).deletePlaylist(playlist.id);
            ref.invalidate(allPlaylistsProvider);
            if (ctx.mounted) Navigator.pop(ctx, true);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
