import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/playlist_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'create_playlist_dialog.dart';
import 'playlist_detail_view.dart';
import 'playlist_dialogs.dart';
import 'rename_playlist_dialog.dart';

class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
            tooltip: 'New Playlist',
          ),
        ],
      ),
      body: playlistsAsync.when(
        loading: () => const SongListSkeleton(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Error: $err'),
          ),
        ),
        data: (playlists) {
          if (playlists.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlaylistTile(
                  playlist: playlist,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailView(
                          playlistId: playlist.id,
                        ),
                      ),
                    );
                  },
                  onLongPress: () =>
                      _showPlaylistMenu(context, ref, playlist),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlaylistDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Playlists Yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a playlist to organize your music',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const CreatePlaylistDialog(),
    );
  }

  void _showPlaylistMenu(BuildContext context, WidgetRef ref, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => RenamePlaylistDialog(playlist: playlist),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                confirmDeletePlaylist(context, ref, playlist);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single playlist card with its song count loaded reactively.
class _PlaylistTile extends ConsumerWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(playlistSongsProvider(playlist.id));
    final songCount = songsAsync.maybeWhen(
      data: (songs) => songs.length,
      orElse: () => 0,
    );

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.playlist_play,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(playlist.name),
        subtitle: Text('$songCount song${songCount == 1 ? '' : 's'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
