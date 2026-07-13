import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/cover_art_helper.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/song_tile.dart';
import '../../../core/database/daos/song_dao.dart';
import '../../../providers/database_providers.dart';

/// Sort options for the library song list.
enum SongSort { title, artist, dateAdded, duration }

/// Provider for whether search mode is active.
final _searchActiveProvider = StateProvider<bool>((ref) => false);

/// Provider for the current search query.
final _searchQueryProvider = StateProvider<String>((ref) => '');

/// Library view showing all scanned songs with scan, search, and sort.
class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);
    final scanState = ref.watch(libraryScanProvider);
    final searchActive = ref.watch(_searchActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: searchActive
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search songs...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
              )
            : const Text('Library'),
        actions: [
          IconButton(
            icon: Icon(searchActive ? Icons.close : Icons.search),
            onPressed: () {
              final active = ref.read(_searchActiveProvider.notifier);
              active.state = !active.state;
              if (!active.state) {
                ref.read(_searchQueryProvider.notifier).state = '';
              }
            },
            tooltip: searchActive ? 'Close search' : 'Search',
          ),
          if (!searchActive)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortSheet(context, ref),
              tooltip: 'Sort',
            ),
        ],
      ),
      body: _buildBody(context, ref, songsAsync, scanState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Song>> songsAsync,
    LibraryScanState scanState,
  ) {
    final theme = Theme.of(context);

    // Show scanning progress if active
    if (scanState.isScanning) {
      return _buildScanningState(context, scanState);
    }

    return songsAsync.when(
      loading: () => const SongListSkeleton(),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load songs',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => ref.invalidate(allSongsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        return _buildSongList(context, ref, songs);
      },
    );
  }

  Widget _buildScanningState(BuildContext context, LibraryScanState scanState) {
    final theme = Theme.of(context);
    final progress = scanState.totalFiles > 0
        ? scanState.scannedFiles / scanState.totalFiles
        : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: scanState.totalFiles > 0 ? progress : null,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning Music...',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              scanState.totalFiles > 0
                  ? '${scanState.scannedFiles} of ${scanState.totalFiles} files processed'
                  : 'Searching for audio files...',
              style: theme.textTheme.bodyMedium,
            ),
            if (scanState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                scanState.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Show scan error if present
    final scanState = ref.watch(libraryScanProvider);
    if (scanState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                scanState.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => _pickAndScanFolder(context, ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return EmptyState(
      icon: Icons.library_music_outlined,
      title: 'Your Library is Empty',
      subtitle: 'Add your music folder to start listening',
      actionLabel: 'Scan Music Folder',
      onAction: () => _pickAndScanFolder(context, ref),
    );
  }

  Widget _buildSongList(
    BuildContext context,
    WidgetRef ref,
    List<Song> songs,
  ) {
    // Apply search filter
    final query = ref.watch(_searchQueryProvider);
    var filtered = songs;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = songs.where((s) {
        return s.title.toLowerCase().contains(q) ||
            (s.artist?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Apply current sort
    final sort = ref.watch(_songSortProvider);
    final sortAsc = ref.watch(_sortAscProvider);
    final sorted = _applySort(filtered, sort, sortAsc);

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                query.isNotEmpty
                    ? 'No songs match "$query"'
                    : 'No songs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allSongsProvider);
      },
      child: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final song = sorted[index];
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
      ),
    );
  }

  List<Song> _applySort(List<Song> songs, SongSort sort, bool ascending) {
    final sorted = List<Song>.from(songs);
    switch (sort) {
      case SongSort.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SongSort.artist:
        sorted.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      case SongSort.dateAdded:
        sorted.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
      case SongSort.duration:
        sorted.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    }
    if (!ascending) return sorted.reversed.toList();
    return sorted;
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
      ref.invalidate(allSongsProvider);
    } catch (e) {
      debugPrint('_updateSongCover error: $e');
    }
  }

  Future<void> _pickAndScanFolder(BuildContext context, WidgetRef ref) async {
    try {
      final dirPath = await FilePicker.getDirectoryPath();
      if (dirPath == null) return; // User cancelled

      await ref.read(libraryScanProvider.notifier).scanFolder(dirPath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick folder: $e')),
        );
      }
    }
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(_songSortProvider);
    final sortAsc = ref.read(_sortAscProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Sort by',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              // Sort direction toggle
              SwitchListTile(
                title: const Text('Ascending'),
                secondary: Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                value: sortAsc,
                onChanged: (v) {
                  ref.read(_sortAscProvider.notifier).state = v;
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ...SongSort.values.map((sort) {
                return ListTile(
                  leading: Icon(
                    sort == currentSort
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(_sortLabel(sort)),
                  onTap: () {
                    ref.read(_songSortProvider.notifier).state = sort;
                    Navigator.of(ctx).pop();
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(SongSort sort) {
    switch (sort) {
      case SongSort.title:
        return 'Title';
      case SongSort.artist:
        return 'Artist';
      case SongSort.dateAdded:
        return 'Date Added';
      case SongSort.duration:
        return 'Duration';
    }
  }
}

/// Simple state provider for the current sort selection.
final _songSortProvider = StateProvider<SongSort>((ref) => SongSort.title);

/// State provider for sort direction (ascending/descending).
final _sortAscProvider = StateProvider<bool>((ref) => true);
