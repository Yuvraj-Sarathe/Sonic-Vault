import 'dart:io';

class M3UExporter {
  static Future<String> exportPlaylist({
    required List<String> filePaths,
    required List<String> titles,
    required List<int> durationsSec,
    required String playlistName,
    required String directory,
  }) async {
    final lines = <String>['#EXTM3U'];

    for (var i = 0; i < filePaths.length; i++) {
      final duration = i < durationsSec.length ? durationsSec[i] : -1;
      final title = i < titles.length ? titles[i] : filePaths[i];
      lines.add('#EXTINF:$duration,$title');
      lines.add(filePaths[i]);
    }

    final filePath = '$directory/${_sanitize(playlistName)}.m3u';
    final file = File(filePath);
    await file.writeAsString(lines.join('\n'));
    return filePath;
  }

  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
