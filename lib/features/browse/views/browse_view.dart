import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';
import 'album_songs_view.dart';
import 'artist_songs_view.dart';
import 'genre_songs_view.dart';

class BrowseView extends ConsumerWidget {
  const BrowseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BrowseCard(
            icon: Icons.album_outlined,
            title: 'Albums',
            subtitle: 'Browse by album',
            color: theme.colorScheme.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlbumSongsView()),
            ),
          ),
          const SizedBox(height: 12),
          _BrowseCard(
            icon: Icons.person_outline,
            title: 'Artists',
            subtitle: 'Browse by artist',
            color: theme.colorScheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistSongsView()),
            ),
          ),
          const SizedBox(height: 12),
          _BrowseCard(
            icon: Icons.music_note_outlined,
            title: 'Songs',
            subtitle: 'All tracks',
            color: theme.colorScheme.tertiary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AllSongsView()),
            ),
          ),
          const SizedBox(height: 12),
          _BrowseCard(
            icon: Icons.category_outlined,
            title: 'Genres',
            subtitle: 'Browse by genre',
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GenreSongsView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BrowseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Displays all songs in a simple read-only list.
class _AllSongsView extends ConsumerWidget {
  const _AllSongsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Songs')),
      body: songsAsync.when(
        loading: () => const SongListSkeleton(),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (songs) {
          if (songs.isEmpty) {
            return const EmptyState(
              icon: Icons.library_music_outlined,
              title: 'No songs found',
              subtitle: 'Add music to your library first',
            );
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
      ),
    );
  }
}
