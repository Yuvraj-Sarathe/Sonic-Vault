import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/lrc_parser.dart';
import '../../../providers/audio_providers.dart';
import '../../../providers/song_providers.dart';

class PlayerView extends ConsumerWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSong = ref.watch(currentSongProvider).asData?.value;
    final hasSong = currentSong != null;

    final positionVal = ref.watch(playbackPositionProvider).asData?.value ?? 0.0;
    final durationVal = ref.watch(playbackDurationProvider).asData?.value ?? 0.0;
    final isPlaying = ref.watch(isPlayingProvider).asData?.value ?? false;
    final isShuffled = ref.watch(isShuffledProvider).asData?.value ?? false;
    final repeatMode = ref.watch(repeatModeProvider).asData?.value ?? RepeatMode.off;
    final songsAsync = ref.watch(allSongsProvider);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space):
            () => ref.read(audioServiceProvider).togglePlayPause(),
        const SingleActivator(LogicalKeyboardKey.keyN):
            () => ref.read(audioServiceProvider).next(),
        const SingleActivator(LogicalKeyboardKey.keyP):
            () => ref.read(audioServiceProvider).previous(),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            () => ref.read(audioServiceProvider).seekRelative(const Duration(seconds: 5)),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            () => ref.read(audioServiceProvider).seekRelative(const Duration(seconds: -5)),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/library'),
          tooltip: 'Back',
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () => context.go('/library'),
            tooltip: 'Queue',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Album art
            _AlbumArt(theme: theme, coverArtPath: currentSong?.coverArtPath),
            const SizedBox(height: 24),
            // Song info
            Text(
              currentSong?.title ?? 'No Track Selected',
              style: theme.textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              currentSong?.artist ?? 'Select a song to start playing',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            // LRC lyrics display
            hasSong ? _LyricsDisplay(
              positionMs: positionVal.round(),
            ) : const SizedBox.shrink(),
            const SizedBox(height: 24),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Slider(
                    value: hasSong ? positionVal.clamp(0.0, durationVal > 0 ? durationVal : 1.0) : 0,
                    min: 0,
                    max: hasSong && durationVal > 0 ? durationVal : 1.0,
                    onChanged: hasSong
                        ? (v) => ref.read(audioServiceProvider).seek(
                              Duration(milliseconds: v.round()),
                            )
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasSong
                              ? FileUtils.formatDuration(
                                  Duration(milliseconds: positionVal.round()),
                                )
                              : '0:00',
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          hasSong
                              ? FileUtils.formatDuration(
                                  Duration(milliseconds: durationVal.round()),
                                )
                              : '0:00',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Transport controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  iconSize: 28,
                  color: isShuffled ? theme.colorScheme.primary : null,
                  onPressed: hasSong
                      ? () => ref.read(audioServiceProvider).toggleShuffle()
                      : null,
                  tooltip: 'Shuffle Mode',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  iconSize: 24,
                  onPressed: () {
                    final service = ref.read(audioServiceProvider);
                    if (service.queue.isEmpty) {
                      final songs = songsAsync.asData?.value;
                      if (songs != null && songs.isNotEmpty) {
                        final refs = songs.map((s) => s.toSongRef()).toList();
                        final r = Random().nextInt(refs.length);
                        service.setQueue(refs, startIndex: r);
                      }
                    } else {
                      service.playRandom();
                    }
                  },
                  tooltip: 'Play Random',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                  onPressed: hasSong
                      ? () => ref.read(audioServiceProvider).previous()
                      : null,
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: hasSong
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                    ),
                    onPressed: hasSong
                        ? () => ref.read(audioServiceProvider).togglePlayPause()
                        : null,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36,
                  onPressed: hasSong
                      ? () => ref.read(audioServiceProvider).next()
                      : null,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: _repeatIcon(repeatMode),
                  iconSize: 28,
                  color: repeatMode != RepeatMode.off
                      ? theme.colorScheme.primary
                      : null,
                  onPressed: hasSong
                      ? () => ref.read(audioServiceProvider).cycleRepeatMode()
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Icon _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return const Icon(Icons.repeat);
      case RepeatMode.all:
        return const Icon(Icons.repeat);
      case RepeatMode.one:
        return const Icon(Icons.repeat_one);
    }
  }
}

/// Synced lyrics display widget — shows current and upcoming LRC lines.
class _LyricsDisplay extends ConsumerWidget {
  final int positionMs;

  const _LyricsDisplay({required this.positionMs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lyricsAsync = ref.watch(lyricsProvider);

    return lyricsAsync.when(
      loading: ()=> const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) return const SizedBox.shrink();

        final position = Duration(milliseconds: positionMs);
        final activeIndex = LrcParser.getActiveLineIndex(position, lyrics);

        return Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView.builder(
            itemCount: lyrics.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final line = lyrics[index];
              final isActive = index == activeIndex;
              final isPast = index < activeIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isActive ? 15 : 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.primary
                        : isPast
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Album art widget — shows file image or placeholder.
class _AlbumArt extends StatelessWidget {
  final ThemeData theme;
  final String? coverArtPath;

  const _AlbumArt({required this.theme, this.coverArtPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverArtPath != null
          ? Image.file(
              File(coverArtPath!),
              width: 280,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholderIcon(),
            )
          : _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return Icon(
      Icons.music_note,
      size: 80,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
    );
  }
}
