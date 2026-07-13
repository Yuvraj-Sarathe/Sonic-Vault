import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sonicvault/core/audio/audio_service.dart';

void main() {
  group('queue management', () {
    test('initial state is empty', () {
      final service = AudioService.testing();
      expect(service.queue, isEmpty);
      expect(service.currentIndex, -1);
      expect(service.currentSong, isNull);
    });

    test('setQueue populates the queue', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', artist: 'X', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', artist: 'Y', durationMs: 200, filePath: '/b.mp3'),
      ]);
      expect(service.queue, hasLength(2));
      expect(service.currentIndex, 0);
      expect(service.currentSong!.title, 'A');
    });

    test('setQueue replaces existing queue', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
      ]);
      await service.setQueue([
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ]);
      expect(service.queue, hasLength(1));
      expect(service.currentSong!.id, '3');
    });

    test('setQueue with startIndex selects correct song', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ], startIndex: 2);
      expect(service.currentIndex, 2);
      expect(service.currentSong!.id, '3');
    });

    test('playSong by id', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
      ]);
      await service.playSong(const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'));
      expect(service.currentIndex, 1);
    });

    test('playSong unknown id does nothing', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
      ]);
      await service.playSong(const SongRef(id: '99', title: '?', durationMs: 0, filePath: '/x.mp3'));
      expect(service.currentIndex, 0);
    });

    test('playFromIndex', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
      ]);
      await service.playFromIndex(1);
      expect(service.currentIndex, 1);
    });

    test('playFromIndex out of range does nothing', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
      ]);
      await service.playFromIndex(99);
      expect(service.currentIndex, 0);
    });

    test('stop clears queue', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
      ]);
      await service.stop();
      expect(service.queue, isEmpty);
      expect(service.currentIndex, -1);
    });
  });

  group('navigation', () {
    test('next advances through queue', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ]);
      expect(service.currentSong!.id, '1');
      await service.next();
      expect(service.currentSong!.id, '2');
      await service.next();
      expect(service.currentSong!.id, '3');
    });

    test('next stops at end with repeat off', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
      ]);
      await service.playFromIndex(1);
      await service.next();
      expect(service.currentSong!.id, '2');
    });

    test('next wraps to start with repeat all', () async {
      final service = AudioService.testing();
      service.setRepeatMode(RepeatMode.all);
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
      ]);
      await service.playFromIndex(1);
      await service.next();
      expect(service.currentSong!.id, '1');
    });

    test('previous goes back', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ]);
      await service.playFromIndex(1);
      await service.previous();
      expect(service.currentSong!.id, '1');
    });

    test('previous wraps to end with repeat all', () async {
      final service = AudioService.testing();
      service.setRepeatMode(RepeatMode.all);
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ]);
      await service.previous();
      expect(service.currentSong!.id, '3');
    });
  });

  group('shuffle', () {
    test('shuffle defaults to off', () {
      final service = AudioService.testing();
      expect(service.isShuffled, isFalse);
    });

    test('toggleShuffle flips state', () {
      final service = AudioService.testing();
      service.toggleShuffle();
      expect(service.isShuffled, isTrue);
      service.toggleShuffle();
      expect(service.isShuffled, isFalse);
    });

    test('setShuffle works', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ]);
      service.setShuffle(true);
      expect(service.isShuffled, isTrue);
    });

    test('shuffle puts current index first in order', () async {
      final service = AudioService.testing();
      await service.setQueue([
        const SongRef(id: '1', title: 'A', durationMs: 100, filePath: '/a.mp3'),
        const SongRef(id: '2', title: 'B', durationMs: 200, filePath: '/b.mp3'),
        const SongRef(id: '3', title: 'C', durationMs: 150, filePath: '/c.mp3'),
      ], startIndex: 1);
      service.setShuffle(true);
      await service.next();
      expect(service.currentSong!.id, isNot('2'));
    });
  });

  group('repeat mode', () {
    test('default repeat mode is off', () {
      final service = AudioService.testing();
      expect(service.repeatMode, RepeatMode.off);
    });

    test('cycleRepeatMode cycles through modes', () {
      final service = AudioService.testing();
      expect(service.cycleRepeatMode(), RepeatMode.all);
      expect(service.cycleRepeatMode(), RepeatMode.one);
      expect(service.cycleRepeatMode(), RepeatMode.off);
    });

    test('setRepeatMode stores value', () {
      final service = AudioService.testing();
      service.setRepeatMode(RepeatMode.one);
      expect(service.repeatMode, RepeatMode.one);
    });
  });

  group('playback control (no-op in testing mode)', () {
    test('seek does not throw', () async {
      final service = AudioService.testing();
      await service.seek(const Duration(seconds: 30));
    });

    test('setVolume clamps and does not throw', () async {
      final service = AudioService.testing();
      await service.setVolume(0.5);
      await service.setVolume(-1.0);
      await service.setVolume(2.0);
    });

    test('setSpeed clamps and does not throw', () async {
      final service = AudioService.testing();
      await service.setSpeed(1.0);
      await service.setSpeed(0.1);
      await service.setSpeed(3.0);
    });

    test('togglePlayPause does not throw', () async {
      final service = AudioService.testing();
      await service.togglePlayPause();
    });

    test('stop does not throw', () async {
      final service = AudioService.testing();
      await service.stop();
    });
  });

  group('stream accessors', () {
    test('exposes empty streams in testing mode', () {
      final service = AudioService.testing();
      expect(service.positionStream, isA<Stream<Duration>>());
      expect(service.playerStateStream, isA<Stream<PlayerState>>());
      expect(service.volumeStream, isA<Stream<double>>());
      expect(service.speedStream, isA<Stream<double>>());
    });
  });

  group('dispose', () {
    test('dispose does not throw', () async {
      final service = AudioService.testing();
      await service.dispose();
    });
  });
}
