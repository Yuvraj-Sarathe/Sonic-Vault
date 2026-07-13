import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';

/// Shows a list of all genres derived from scanned songs.
/// Tapping a genre shows songs in that genre.
/// The genre field is comma-separated; the first genre is used for display.
class GenreSongsView extends ConsumerStatefulWidget {
  const GenreSongsView({super.key});

  @override
  ConsumerState<GenreSongsView> createState() => _GenreSongsViewState();
}

class _GenreSongsViewState extends ConsumerState<GenreSongsView> {
  String? _selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGenre ?? 'Genres'),
        leading: _selectedGenre != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedGenre = null),
              )
            : null,
        automaticallyImplyLeading: _selectedGenre == null,
      ),
      body: _selectedGenre != null
          ? _buildSongsForGenre()
          : _buildGenreList(),
    );
  }

  Widget _buildGenreList() {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (songs) {
        final genreSet = <String>{};
        int uncategorizedCount = 0;

        for (final song in songs) {
          if (song.genre == null || song.genre!.trim().isEmpty) {
            uncategorizedCount++;
          } else {
            // Take the first genre from comma-separated list
            final firstGenre = song.genre!.split(',').first.trim();
            if (firstGenre.isNotEmpty) {
              genreSet.add(firstGenre);
            }
          }
        }

        final genres = genreSet.toList()..sort();

        return ListView.builder(
          itemCount: genres.length + (uncategorizedCount > 0 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && uncategorizedCount > 0) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.amber.withValues(alpha: 0.2),
                  ),
                  child: const Icon(Icons.category, color: Colors.amber),
                ),
                title: const Text('Uncategorized'),
                subtitle: Text('$uncategorizedCount song${uncategorizedCount == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => _selectedGenre = ''),
              );
            }

            final genreIndex = uncategorizedCount > 0 ? index - 1 : index;
            final genre = genres[genreIndex];
            final count =
                songs.where((s) =>
                    s.genre != null &&
                    s.genre!.split(',').any((g) => g.trim() == genre))
                    .length;

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              title: Text(genre),
              subtitle: Text('$count song${count == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedGenre = genre),
            );
          },
        );
      },
    );
  }

  Widget _buildSongsForGenre() {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (songs) {
        final filtered = songs.where((s) {
          if (_selectedGenre == '') {
            // Uncategorized: no genre or empty genre
            return s.genre == null || s.genre!.trim().isEmpty;
          }
          return s.genre != null &&
              s.genre!.split(',').any((g) => g.trim() == _selectedGenre);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No songs found in this genre'));
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final song = filtered[index];
            return SongTile(
              song: song,
              onTap: () {
                final service = ref.read(audioServiceProvider);
                final refs = filtered.map((s) => s.toSongRef()).toList();
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
