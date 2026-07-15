import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/cover_art_helper.dart';
import 'dart:io';
import '../../../providers/playlist_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../providers/database_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import 'playlist_dialogs.dart';
import 'rename_playlist_dialog.dart';
import 'add_songs_dialog.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';

/// Shows songs within a single playlist and provides management actions.
class PlaylistDetailView extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailView({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final songsAsync = ref.watch(playlistSongsProvider(playlistId));

    return playlistsAsync.when(
      loading: () => const Scaffold(body: SongListSkeleton()),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (playlists) {
        final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
        final name = playlist?.name ?? 'Unknown Playlist';

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Add Songs',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AddSongsDialog(playlistId: playlistId),
                ),
              ),
              if (playlist != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',
                  onSelected: (value) async {
                    if (value == 'rename') {
                      showDialog(
                        context: context,
                        builder: (_) => RenamePlaylistDialog(playlist: playlist),
                      );
                    } else if (value == 'cover') {
                      await _pickCover(context, ref, playlist);
                    } else if (value == 'remove_cover' && context.mounted) {
                      await ref.read(playlistDaoProvider).updatePlaylist(
                        PlaylistsCompanion(
                          id: Value(playlist.id),
                          coverArtPath: const Value(null),
                        ),
                      );
                      ref.invalidate(allPlaylistsProvider);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, playlist);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Rename'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cover',
                      child: ListTile(
                        leading: Icon(Icons.image_outlined),
                        title: Text('Change Cover'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (playlist.coverArtPath != null)
                      const PopupMenuItem(
                        value: 'remove_cover',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Remove Cover'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: songsAsync.when(
            loading: () => const SongListSkeleton(),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (songs) {
              if (songs.isEmpty) {
                return EmptyState(
                  icon: Icons.playlist_play,
                  title: 'This playlist is empty',
                  subtitle: 'Add songs to get started',
                  actionLabel: 'Add Songs',
                  onAction: () => showDialog(
                    context: context,
                    builder: (_) => AddSongsDialog(playlistId: playlistId),
                  ),
                );
              }
              return ListView.builder(
                itemCount: songs.length + 1, // +1 for cover header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCoverHeader(context, theme, playlist, ref);
                  }
                  final song = songs[index - 1];
                  return SongTile(
                    song: song,
                    onTap: () {
                      final service = ref.read(audioServiceProvider);
                      final allSongRefs = songs.map((s) => s.toSongRef()).toList();
                      final tappedIndex = songs.indexOf(song);
                      service.setQueue(allSongRefs, startIndex: tappedIndex);
                      context.go('/player');
                    },
                    onCoverTap: () => _pickSongCover(context, ref, song),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCoverHeader(BuildContext context, ThemeData theme, Playlist? playlist, WidgetRef ref) {
    final coverPath = playlist?.coverArtPath;
    final hasCover = coverPath != null && File(coverPath).existsSync();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasCover
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(coverPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _defaultCoverPlaceholder(theme),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _pickCover(context, ref, playlist),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                _defaultCoverPlaceholder(theme),
                Center(
                  child: Icon(
                    Icons.playlist_play,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _pickCover(context, ref, playlist),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Add Cover', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _defaultCoverPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    );
  }

  Future<void> _pickSongCover(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final bytes = await File(filePath).readAsBytes();
      final savedPath = await CoverArtHelper.saveCoverImage(song.id, bytes);
      if (savedPath != null && context.mounted) {
        _updateSongCover(ref, song, savedPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set cover: $e')),
        );
      }
    }
  }

  Future<void> _updateSongCover(WidgetRef ref, Song song, String coverPath) async {
    try {
      final dao = ref.read(songDaoProvider);
      final hasCover = coverPath.isNotEmpty;
      await dao.updateSong(SongsCompanion(
        id: Value(song.id),
        coverArtPath: Value(hasCover ? coverPath : null),
        hasCoverArt: Value(hasCover),
      ));
      ref.invalidate(allPlaylistsProvider);
    } catch (e) {
      debugPrint('_updateSongCover error: $e');
    }
  }

  Future<void> _pickCover(
    BuildContext context,
    WidgetRef ref,
    Playlist? playlist,
  ) async {
    if (playlist == null) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final bytes = await File(filePath).readAsBytes();
      final savedPath = await CoverArtHelper.saveCoverImage(playlist.id, bytes);
      if (savedPath != null && context.mounted) {
        await ref.read(playlistDaoProvider).updatePlaylist(
          PlaylistsCompanion(
            id: Value(playlist.id),
            coverArtPath: Value(savedPath),
          ),
        );
        ref.invalidate(allPlaylistsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set cover: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Playlist playlist) {
    confirmDeletePlaylist(context, ref, playlist).then((deleted) {
      if (deleted && context.mounted) Navigator.pop(context);
    });
  }
}
