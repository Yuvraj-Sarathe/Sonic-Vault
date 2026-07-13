import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/core/utils/file_utils.dart';

void main() {
  group('FileUtils.formatFileSize', () {
    test('returns "0 B" for zero bytes', () {
      expect(FileUtils.formatFileSize(0), '0 B');
    });

    test('returns bytes for values under 1 KB', () {
      expect(FileUtils.formatFileSize(512), '512 B');
    });

    test('returns KB for values between 1 KB and 1 MB', () {
      expect(FileUtils.formatFileSize(1024), '1.0 KB');
      expect(FileUtils.formatFileSize(1536), '1.5 KB');
    });

    test('returns MB for values between 1 MB and 1 GB', () {
      expect(FileUtils.formatFileSize(1048576), '1.0 MB');
      expect(FileUtils.formatFileSize(1572864), '1.5 MB');
    });

    test('returns GB for values >= 1 GB', () {
      expect(FileUtils.formatFileSize(1073741824), '1.0 GB');
    });
  });

  group('FileUtils.formatDuration', () {
    test('formats seconds-only duration', () {
      expect(FileUtils.formatDuration(const Duration(seconds: 45)), '0:45');
    });

    test('formats minutes duration with padding', () {
      expect(
        FileUtils.formatDuration(const Duration(seconds: 125)),
        '2:05',
      );
    });

    test('formats hours duration', () {
      expect(
        FileUtils.formatDuration(const Duration(seconds: 3661)),
        '1:01:01',
      );
    });

    test('handles zero duration', () {
      expect(FileUtils.formatDuration(Duration.zero), '0:00');
    });
  });

  group('FileUtils.formatDate', () {
    test('formats date in MMM d, yyyy', () {
      final date = DateTime(2026, 7, 9);
      expect(FileUtils.formatDate(date), 'Jul 9, 2026');
    });
  });

  group('FileUtils.generateFileId', () {
    test('generates consistent 16-char hash', () {
      final id1 = FileUtils.generateFileId('/path/to/file.mp3');
      expect(id1, hasLength(16));
      expect(id1, isA<String>());
    });

    test('generates same id for same path', () {
      final id1 = FileUtils.generateFileId('/path/to/file.mp3');
      final id2 = FileUtils.generateFileId('/path/to/file.mp3');
      expect(id1, id2);
    });

    test('generates different ids for different paths', () {
      final id1 = FileUtils.generateFileId('/path/a.mp3');
      final id2 = FileUtils.generateFileId('/path/b.mp3');
      expect(id1, isNot(id2));
    });
  });

  group('FileUtils.getFileExtension', () {
    test('returns extension with dot', () {
      expect(FileUtils.getFileExtension('song.mp3'), '.mp3');
    });

    test('returns lowercase extension', () {
      expect(FileUtils.getFileExtension('song.FLAC'), '.flac');
    });

    test('returns extension for path with directories', () {
      expect(
        FileUtils.getFileExtension('/Music/Album/song.ogg'),
        '.ogg',
      );
    });

    test('returns empty string for path without extension', () {
      expect(FileUtils.getFileExtension('Makefile'), '');
    });

    test('returns empty string for path ending with dot', () {
      expect(FileUtils.getFileExtension('file.'), '');
    });

    test('returns extension for path with multiple dots', () {
      expect(FileUtils.getFileExtension('song.final.mp3'), '.mp3');
    });
  });

  group('FileUtils.getFileName / getFileNameWithoutExtension', () {
    test('gets file name from full path', () {
      expect(
        FileUtils.getFileName('/Music/Album/song.mp3'),
        'song.mp3',
      );
    });

    test('gets file name without extension', () {
      expect(
        FileUtils.getFileNameWithoutExtension('/Music/Album/song.mp3'),
        'song',
      );
    });

    test('handles Windows paths', () {
      expect(
        FileUtils.getFileName(r'C:\Music\song.mp3'),
        'song.mp3',
      );
    });

    test('handles files without extension', () {
      expect(
        FileUtils.getFileNameWithoutExtension('/Music/Album/song'),
        'song',
      );
    });
  });

  group('FileUtils.isAudioFile / isImageFile / isLyricFile', () {
    test('identifies audio extensions', () {
      expect(FileUtils.isAudioFile('song.mp3'), isTrue);
      expect(FileUtils.isAudioFile('song.flac'), isTrue);
      expect(FileUtils.isAudioFile('song.wav'), isTrue);
      expect(FileUtils.isAudioFile('song.ogg'), isTrue);
    });

    test('rejects non-audio extensions', () {
      expect(FileUtils.isAudioFile('song.txt'), isFalse);
      expect(FileUtils.isAudioFile('song.jpg'), isFalse);
    });

    test('identifies image extensions', () {
      expect(FileUtils.isImageFile('cover.jpg'), isTrue);
      expect(FileUtils.isImageFile('cover.png'), isTrue);
      expect(FileUtils.isImageFile('cover.webp'), isTrue);
    });

    test('identifies lyric extensions', () {
      expect(FileUtils.isLyricFile('lyrics.lrc'), isTrue);
      expect(FileUtils.isLyricFile('lyrics.LRC'), isTrue);
    });
  });

  group('FileUtils.scanDirectory', () {
    test('returns empty list for non-existent directory', () async {
      final result = await FileUtils.scanDirectory('/nonexistent/path');
      expect(result, isEmpty);
    });

    test('finds audio files in temp directory', () async {
      final dir = Directory.systemTemp.createTempSync('sonicvault_test_');
      try {
        File('${dir.path}/song1.mp3').createSync();
        File('${dir.path}/song2.flac').createSync();
        File('${dir.path}/readme.txt').createSync();
        File('${dir.path}/sub/other.ogg')
          ..createSync(recursive: true)
          ..writeAsStringSync('test');

        final result = await FileUtils.scanDirectory(dir.path);
        expect(result, hasLength(3));
        expect(
          result.map((f) => f.path.split(RegExp(r'[/\\]')).last).toSet(),
          containsAll(['song1.mp3', 'song2.flac', 'other.ogg']),
        );
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });

  group('FileUtils.sanitizeFileName', () {
    test('removes invalid filename characters', () {
      expect(FileUtils.sanitizeFileName('Rock/Metal: Best!'), 'Rock_Metal_ Best!');
    });

    test('preserves valid names', () {
      expect(FileUtils.sanitizeFileName('HelloWorld'), 'HelloWorld');
    });
  });
}
