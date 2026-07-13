import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton audio player service wrapping just_audio.
class AudioService {
  final AudioPlayer? _player;
  final List<SongRef> _queue = [];
  int _currentIndex = -1;
  bool _isShuffled = false;
  List<int> _shuffleOrder = [];
  RepeatMode _repeatMode = RepeatMode.off;
  final _stateController = StreamController<void>.broadcast();
  StreamSubscription<PlayerState>? _completionSubscription;

  AudioService()
      : _player = AudioPlayer()
          ..setVolume(0.8)
          ..setSpeed(1.0) {
    // Auto-advance to next track when current song completes
    _completionSubscription = _player?.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  /// Testing constructor: no real [AudioPlayer] is created.
  /// Queue-management methods (setQueue, next, previous, etc.) work fully;
  /// playback-control methods (seek, setVolume, togglePlayPause) are no-ops.
  AudioService.testing() : _player = null;

  /// The underlying player, or `null` in testing mode.
  AudioPlayer? get player => _player;
  List<SongRef> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  SongRef? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;
  bool get isShuffled => _isShuffled;
  RepeatMode get repeatMode => _repeatMode;

  Stream<Duration> get positionStream =>
      _player?.positionStream ?? const Stream.empty();
  Stream<Duration?> get durationStream =>
      _player?.durationStream ?? const Stream.empty();
  Stream<PlayerState> get playerStateStream =>
      _player?.playerStateStream ?? const Stream.empty();
  Stream<double> get volumeStream =>
      _player?.volumeStream ?? const Stream.empty();
  Stream<double> get speedStream =>
      _player?.speedStream ?? const Stream.empty();

  // --- Reactive state streams (CR-01 fix) ---

  Stream<SongRef?> get currentSongStream async* {
    yield currentSong;
    await for (final _ in _stateController.stream) {
      yield currentSong;
    }
  }

  Stream<bool> get shuffleStream async* {
    yield _isShuffled;
    await for (final _ in _stateController.stream) {
      yield _isShuffled;
    }
  }

  Stream<RepeatMode> get repeatModeStream async* {
    yield _repeatMode;
    await for (final _ in _stateController.stream) {
      yield _repeatMode;
    }
  }

  Stream<PlayerBarState> get playerBarStateStream async* {
    yield _buildPlayerBarState();
    await for (final _ in _stateController.stream) {
      yield _buildPlayerBarState();
    }
  }

  Future<void> setQueue(List<SongRef> songs, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(songs);
    _currentIndex = startIndex;
    _generateShuffleOrder();
    await _loadCurrent();
    _emitState();
  }

  Future<void> playSong(SongRef song) async {
    final index = _queue.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      _currentIndex = index;
      await _loadCurrent();
      _emitState();
    }
  }

  Future<void> playFromIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _loadCurrent();
      _emitState();
    }
  }

  Future<void> togglePlayPause() async {
    final p = _player;
    if (p == null) return;
    if (p.playing) {
      await p.pause();
    } else {
      await p.play();
    }
    _emitState();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    final p = _player;
    if (_repeatMode == RepeatMode.one && p != null) {
      await p.seek(Duration.zero);
      await p.play();
      _emitState();
      return;
    }
    final nextIndex = _getNextIndex();
    if (nextIndex < 0) return;
    _currentIndex = nextIndex;
    await _loadCurrent();
    _emitState();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    final p = _player;
    if (p != null) {
      final pos = p.position;
      if (pos.inSeconds > 3) {
        await p.seek(Duration.zero);
        _emitState();
        return;
      }
    }
    final prevIndex = _getPreviousIndex();
    if (prevIndex < 0) return;
    _currentIndex = prevIndex;
    await _loadCurrent();
    _emitState();
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _player?.setSpeed(speed.clamp(0.5, 2.0));
  }

  void setShuffle(bool enabled) {
    _isShuffled = enabled;
    if (enabled) _generateShuffleOrder();
    _emitState();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _emitState();
  }

  void toggleShuffle() => setShuffle(!_isShuffled);

  RepeatMode cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
    }
    _emitState();
    return _repeatMode;
  }

  Future<void> stop() async {
    await _player?.stop();
    _queue.clear();
    _currentIndex = -1;
    _emitState();
  }

  Future<void> dispose() async {
    await _completionSubscription?.cancel();
    await _stateController.close();
    await _player?.dispose();
  }

  PlayerBarState _buildPlayerBarState() {
    return PlayerBarState(
      currentSong: currentSong,
      isPlaying: _player?.playing ?? false,
      position: _player?.position ?? Duration.zero,
      duration: _player?.duration ?? Duration.zero,
      isShuffled: _isShuffled,
      repeatMode: _repeatMode,
    );
  }

  void _emitState() => _stateController.add(null);

  // --- private helpers ---

  Future<void> _loadCurrent() async {
    final song = currentSong;
    final p = _player;
    if (song == null || p == null) return;
    try {
      await p.setFilePath(song.filePath);
      await p.play();
    } catch (e) {
      debugPrint('AudioService._loadCurrent: Failed to load "${song.filePath}": $e');
    }
  }

  int _getNextIndex() {
    if (_isShuffled && _shuffleOrder.isNotEmpty) {
      final currentPos = _shuffleOrder.indexOf(_currentIndex);
      final nextPos = currentPos + 1;
      if (nextPos < _shuffleOrder.length) return _shuffleOrder[nextPos];
      if (_repeatMode == RepeatMode.all) return _shuffleOrder.first;
      return -1;
    }
    final next = _currentIndex + 1;
    if (next < _queue.length) return next;
    if (_repeatMode == RepeatMode.all) return 0;
    return -1;
  }

  int _getPreviousIndex() {
    if (_isShuffled && _shuffleOrder.isNotEmpty) {
      final currentPos = _shuffleOrder.indexOf(_currentIndex);
      final prevPos = currentPos - 1;
      if (prevPos >= 0) return _shuffleOrder[prevPos];
      if (_repeatMode == RepeatMode.all) return _shuffleOrder.last;
      return -1;
    }
    final prev = _currentIndex - 1;
    if (prev >= 0) return prev;
    if (_repeatMode == RepeatMode.all) return _queue.length - 1;
    return -1;
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i)..shuffle();
    if (_currentIndex >= 0 && _shuffleOrder.isNotEmpty) {
      _shuffleOrder.remove(_currentIndex);
      _shuffleOrder.insert(0, _currentIndex);
    }
  }
}

/// Lightweight song reference for the audio queue (avoids drift dependency).
class SongRef {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int durationMs;
  final String filePath;
  final String? coverArtPath;

  const SongRef({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.durationMs,
    required this.filePath,
    this.coverArtPath,
  });
}

/// Data class bundling the state needed by the mini-player bar.
class PlayerBarState {
  final SongRef? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffled;
  final RepeatMode repeatMode;

  const PlayerBarState({
    this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.isShuffled,
    required this.repeatMode,
  });
}

// Riverpod provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

enum RepeatMode { off, all, one }
