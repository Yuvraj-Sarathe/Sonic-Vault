import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../providers/song_providers.dart';
import '../../../providers/playlist_providers.dart';
import '../../../providers/database_providers.dart';

/// Sort options matching the library view pattern.
enum _PickerSort { title, artist, dateAdded, duration }

/// A dialog that shows all songs with search, sort, and checkboxes to add to a playlist.
class AddSongsDialog extends ConsumerWidget {
  final String playlistId;

  const AddSongsDialog({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const AlertDialog(
        title: Text('Add Songs'),
        content: CircularProgressIndicator(),
      ),
      error: (err, _) => AlertDialog(
        title: const Text('Add Songs'),
        content: Text('Error loading songs: $err'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return AlertDialog(
            title: const Text('Add Songs'),
            content: const Text('No songs in your library. Scan music first.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        return _SongPicker(playlistId: playlistId, songs: songs);
      },
    );
  }
}

class _SongPicker extends ConsumerStatefulWidget {
  final String playlistId;
  final List<Song> songs;

  const _SongPicker({required this.playlistId, required this.songs});

  @override
  ConsumerState<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends ConsumerState<_SongPicker> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  _PickerSort _sort = _PickerSort.title;
  bool _sortAsc = true;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> get _filtered {
    var list = widget.songs;

    // Filter by search query
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            (s.artist?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sort
    final sorted = List<Song>.from(list);
    switch (_sort) {
      case _PickerSort.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case _PickerSort.artist:
        sorted.sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
      case _PickerSort.dateAdded:
        sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case _PickerSort.duration:
        sorted.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    }

    if (!_sortAsc) return sorted.reversed.toList();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return AlertDialog(
      title: const Text('Add Songs'),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),

            // Sort bar
            Row(
              children: [
                Text(
                  '${filtered.length} song${filtered.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(
                    _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                  ),
                  label: Text(_sortLabel(_sort)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _showSortSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Song list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isNotEmpty
                            ? 'No songs match "$_query"'
                            : 'No songs available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final song = filtered[index];
                        final isSelected = _selectedIds.contains(song.id);

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          dense: true,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(song.id);
                              } else {
                                _selectedIds.remove(song.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedIds.isEmpty ? null : () => _addSongs(context),
          child: Text('Add (${_selectedIds.length})'),
        ),
      ],
    );
  }

  void _showSortSheet(BuildContext context) {
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
                secondary: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                value: _sortAsc,
                onChanged: (v) {
                  setState(() => _sortAsc = v);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ..._PickerSort.values.map((sort) {
                return ListTile(
                  leading: Icon(
                    sort == _sort
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(_sortLabel(sort)),
                  onTap: () {
                    setState(() => _sort = sort);
                    Navigator.pop(ctx);
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

  String _sortLabel(_PickerSort sort) {
    switch (sort) {
      case _PickerSort.title:
        return 'Title';
      case _PickerSort.artist:
        return 'Artist';
      case _PickerSort.dateAdded:
        return 'Date Added';
      case _PickerSort.duration:
        return 'Duration';
    }
  }

  Future<void> _addSongs(BuildContext context) async {
    final dao = ref.read(playlistDaoProvider);
    final uuid = const Uuid();

    // Get current max sort order
    final currentEntries = await dao.getPlaylistEntries(widget.playlistId);
    var nextOrder = currentEntries.length;

    for (final songId in _selectedIds) {
      await dao.addSongToPlaylist(PlaylistEntriesCompanion(
        id: Value(uuid.v4()),
        playlistId: Value(widget.playlistId),
        songId: Value(songId),
        sortOrder: Value(nextOrder),
        dateAdded: Value(DateTime.now()),
      ));
      nextOrder++;
    }

    // Invalidate playlist songs provider to refresh UI
    ref.invalidate(playlistSongsProvider(widget.playlistId));
    ref.invalidate(allPlaylistsProvider);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedIds.length} song${_selectedIds.length == 1 ? '' : 's'} added'),
        ),
      );
    }
  }
}
