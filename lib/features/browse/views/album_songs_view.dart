import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';

/// Shows a list of all albums derived from scanned songs.
/// Tapping an album shows its songs.
class AlbumSongsView extends ConsumerStatefulWidget {
  const AlbumSongsView({super.key});

  @override
  ConsumerState<AlbumSongsView> createState() => _AlbumSongsViewState();
}

class _AlbumSongsViewState extends ConsumerState<AlbumSongsView> {
  String? _selectedAlbum;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedAlbum ?? 'Albums'),
        leading: _selectedAlbum != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedAlbum = null),
              )
            : null,
        automaticallyImplyLeading: _selectedAlbum == null,
      ),
      body: _selectedAlbum != null
          ? _buildSongsForAlbum()
          : _buildAlbumList(),
    );
  }

  Widget _buildAlbumList() {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (songs) {
        final albumSet = <String>{};
        final albumSongCount = <String, int>{};

        for (final song in songs) {
          final album = song.album ?? 'Unknown Album';
          albumSet.add(album);
          albumSongCount[album] = (albumSongCount[album] ?? 0) + 1;
        }

        final albums = albumSet.toList()..sort();

        if (albums.isEmpty) {
          return const Center(child: Text('No albums found'));
        }

        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final count = albumSongCount[album] ?? 0;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.album,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(album),
              subtitle: Text('$count song${count == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedAlbum = album),
            );
          },
        );
      },
    );
  }

  Widget _buildSongsForAlbum() {
    final songsAsync = ref.watch(songsByAlbumProvider(_selectedAlbum!));

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('No songs found in this album'));
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongTile(
              song: song,
              onTap: () {
                final service = ref.read(audioServiceProvider);
                final refs = songs.map((s) => s.toSongRef()).toList();
                service.setQueue(refs, startIndex: index);
                context.go('/player');
              },
            );
          },
        );
      },
    );
  }
}
