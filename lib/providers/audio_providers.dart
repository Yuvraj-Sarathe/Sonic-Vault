import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../core/audio/audio_service.dart';
import '../core/database/app_database.dart';
import '../core/utils/lrc_parser.dart';

/// Reactive Riverpod providers wrapping AudioService state streams.

/// Current playback position in milliseconds.
final playbackPositionProvider = StreamProvider<double>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.positionStream.map((d) => d.inMilliseconds.toDouble());
});

/// Track duration in milliseconds.
final playbackDurationProvider = StreamProvider<double>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.durationStream.map((d) => (d ?? Duration.zero).inMilliseconds.toDouble());
});

/// Whether audio is currently playing.
final isPlayingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playerStateStream.map((state) => state.playing);
});

/// Current playback processing state (idle/loading/ready/completed).
final processingStateProvider = StreamProvider<ProcessingState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playerStateStream.map((state) => state.processingState);
});

/// Current song being played (nullable).
final currentSongProvider = StreamProvider<SongRef?>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.currentSongStream;
});

/// Shuffle mode toggle state.
final isShuffledProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.shuffleStream;
});

/// Repeat mode.
final repeatModeProvider = StreamProvider<RepeatMode>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.repeatModeStream;
});

/// Volume (0.0–1.0).
final volumeProvider = StreamProvider<double>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.volumeStream;
});

/// Combined provider for player bar: (currentSong, isPlaying, position, duration).
final playerBarStateProvider = StreamProvider<PlayerBarState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playerBarStateStream;
});

/// Extension on Song to convert to SongRef.
extension SongToSongRef on Song {
  SongRef toSongRef() => SongRef(
        id: id,
        title: title,
        artist: artist,
        album: album,
        durationMs: durationMs,
        filePath: filePath,
        coverArtPath: coverArtPath,
      );
}

/// Provider that parses and supplies LRC lyrics for the current song.
final lyricsProvider = FutureProvider<List<LrcLine>?>((ref) async {
  final song = ref.watch(currentSongProvider).asData?.value;
  if (song == null) return null;
  final lrcPath = LrcParser.findLrcFile(song.filePath);
  if (lrcPath == null) return null;
  return LrcParser.parseFile(lrcPath);
});