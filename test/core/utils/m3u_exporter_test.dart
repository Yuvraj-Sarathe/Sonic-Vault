import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/core/utils/m3u_exporter.dart';

void main() {
  group('M3UExporter', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('m3u_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates M3U file with correct format', () async {
      final filePath = await M3UExporter.exportPlaylist(
        filePaths: [
          'C:\\Music\\song1.mp3',
          'C:\\Music\\song2.flac',
        ],
        titles: ['Song One', 'Song Two'],
        durationsSec: [180, 240],
        playlistName: 'Test Playlist',
        directory: tempDir.path,
      );

      expect(File(filePath).existsSync(), isTrue);

      final content = await File(filePath).readAsString();
      final lines = content.split('\n');

      expect(lines[0], '#EXTM3U');
      expect(lines[1], '#EXTINF:180,Song One');
      expect(lines[2], 'C:\\Music\\song1.mp3');
      expect(lines[3], '#EXTINF:240,Song Two');
      expect(lines[4], 'C:\\Music\\song2.flac');
    });

    test('sanitizes playlist name in filename', () async {
      final filePath = await M3UExporter.exportPlaylist(
        filePaths: ['song.mp3'],
        titles: ['Song'],
        durationsSec: [120],
        playlistName: 'Rock/Metal: Favorites',
        directory: tempDir.path,
      );

      expect(filePath, contains('Rock_Metal_ Favorites.m3u'));
    });

    test('falls back to file path when title list is shorter', () async {
      final filePath = await M3UExporter.exportPlaylist(
        filePaths: ['song1.mp3', 'song2.mp3'],
        titles: ['Song One'],
        durationsSec: [120],
        playlistName: 'Partial',
        directory: tempDir.path,
      );

      final content = await File(filePath).readAsString();
      final lines = content.split('\n');

      expect(lines[1], '#EXTINF:120,Song One');
      expect(lines[3], startsWith('#EXTINF:-1,song2.mp3'));
    });

    test('handles empty track list', () async {
      final filePath = await M3UExporter.exportPlaylist(
        filePaths: [],
        titles: [],
        durationsSec: [],
        playlistName: 'Empty',
        directory: tempDir.path,
      );

      final content = await File(filePath).readAsString();
      expect(content, '#EXTM3U');
    });
  });
}
