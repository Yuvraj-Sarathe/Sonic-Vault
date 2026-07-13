import 'dart:io';

/// A single line in an LRC subtitle/lyrics file.
class LrcLine {
  final Duration timestamp;
  final String text;

  const LrcLine({required this.timestamp, required this.text});
}

/// Parses LRC (LyRiCs) subtitle files used for synced karaoke/lyrics.
///
/// Standard LRC format:
///   [mm:ss.xx]Lyrics text
///   [mm:ss.xx][mm:ss.yy]Lyrics with multiple timestamps
///
/// Extended LRC also supports:
///   [mm:ss.xxx] with millisecond precision
///   [ti:Title]
///   [ar:Artist]
///   [al:Album]
///   [by:Creator]
///   [offset:+/-ms]
class LrcParser {
  /// Parse an LRC file at [filePath] and return the list of timed lines.
  /// Returns null if the file doesn't exist or cannot be parsed.
  static Future<List<LrcLine>?> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      return parseContent(content);
    } catch (_) {
      return null;
    }
  }

  /// Parse LRC content from a string.
  static List<LrcLine> parseContent(String content) {
    final lines = <LrcLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})[.:](\d{2,3})\](.*)');
    Duration? offset;

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check for metadata tags
      if (trimmed.startsWith('[offset:')) {
        final match = RegExp(r'-?\d+').firstMatch(trimmed);
        if (match != null) {
          offset = Duration(milliseconds: int.parse(match.group(0)!));
        }
        continue;
      }
      if (trimmed.startsWith('[') && !trimmed.contains(']')) continue;

      // Parse timestamp lines
      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!;
        final millis = millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr);
        final text = match.group(4)?.trim() ?? '';

        if (text.isEmpty) continue;

        var ts = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );
        if (offset != null) ts += offset;

        lines.add(LrcLine(timestamp: ts, text: text));
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Find an LRC file adjacent to an audio file.
  /// Checks for: audio_name.lrc, audio_name.txt alongside the audio file.
  static String? findLrcFile(String audioFilePath) {
    final dir = audioFilePath.substring(
      0,
      audioFilePath.lastIndexOf(RegExp(r'[/\\]')),
    );
    final baseName = audioFilePath.split(RegExp(r'[/\\]')).last;
    final dotIndex = baseName.lastIndexOf('.');
    final nameNoExt = dotIndex > 0 ? baseName.substring(0, dotIndex) : baseName;

    // Check common lyric file name patterns
    final candidates = [
      '$nameNoExt.lrc',
      '$nameNoExt.txt',
      '$nameNoExt.LRC',
    ];

    for (final candidate in candidates) {
      final path = '$dir\\$candidate';
      if (File(path).existsSync()) return path;
    }

    return null;
  }

  /// Get the active line index at [position] into the lyrics.
  /// Returns -1 if no lyrics are loaded or position is before the first line.
  static int getActiveLineIndex(Duration position, List<LrcLine> lyrics) {
    if (lyrics.isEmpty) return -1;

    int activeIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (position >= lyrics[i].timestamp) {
        activeIndex = i;
      } else {
        break;
      }
    }
    return activeIndex;
  }
}
