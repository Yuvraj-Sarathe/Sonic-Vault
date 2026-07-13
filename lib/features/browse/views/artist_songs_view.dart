import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';

/// Shows a list of all artists. Tapping an artist shows their songs.
class ArtistSongsView extends ConsumerStatefulWidget {
  const ArtistSongsView({super.key});

  @override
  ConsumerState<ArtistSongsView> createState() => _ArtistSongsViewState();
}

class _ArtistSongsViewState extends ConsumerState<ArtistSongsView> {
  String? _selectedArtist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedArtist ?? 'Artists'),
        leading: _selectedArtist != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedArtist = null),
              )
            : null,
        automaticallyImplyLeading: _selectedArtist == null,
      ),
      body: _selectedArtist != null
          ? _buildSongsForArtist()
          : _buildArtistList(),
    );
  }

  Widget _buildArtistList() {
    final artistsAsync = ref.watch(allArtistsProvider);

    return artistsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(
        child: Text('Error: $err'),
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(child: Text('No artists found'));
        }

        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: Text(artist),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedArtist = artist),
            );
          },
        );
      },
    );
  }

  Widget _buildSongsForArtist() {
    final songsAsync = ref.watch(songsByArtistProvider(_selectedArtist!));

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(child: Text('No songs found for this artist'));
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
